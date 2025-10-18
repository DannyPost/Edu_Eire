import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/news_article.dart';

class EducationNewsService {
  EducationNewsService._();
  static final EducationNewsService instance = EducationNewsService._();

  String get _newsApiKey => dotenv.env['NEWSAPI_API_KEY'] ?? '';
  String get _openAiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  Future<List<NewsArticle>> fetchSummarised({int maxItems = 20}) async {
    print('[NewsService] Keys => NewsAPI:${_newsApiKey.isNotEmpty ? _newsApiKey.substring(0, 4) : "null"} OpenAI:${_openAiKey.isNotEmpty ? "loaded" : "null"}');

    try {
      final articles = await _fetchNewsAPI();
      final deduped = _dedupeByUrl(articles).toList();

      const batchSize = 3;
      final summarised = <NewsArticle>[];
      for (var i = 0; i < deduped.length; i += batchSize) {
        final batch = deduped.skip(i).take(batchSize);
        final batchResults = await Future.wait(batch.map(_summariseWithOpenAI));
        summarised.addAll(batchResults.whereType<NewsArticle>());
        await Future.delayed(const Duration(milliseconds: 1200));
      }

      return summarised.take(maxItems).toList();
    } catch (e, st) {
      print('[NewsService] ERROR => $e');
      print(st);
      rethrow;
    }
  }

  Future<List<NewsArticle>> _fetchNewsAPI() async {
    if (_newsApiKey.isEmpty) return [];

    final uri = Uri.https('newsapi.org', '/v2/everything', {
      'q': 'education',
      'language': 'en',
      'apiKey': _newsApiKey,
      'pageSize': '50',
      'domains': 'irishtimes.com,rte.ie,independent.ie,irishexaminer.com,thejournal.ie',
    });

    print('[NewsService] Fetching Irish education news: $uri');

    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return [];

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return (json['articles'] as List<dynamic>).map((e) {
      final m = e as Map<String, dynamic>;
      return NewsArticle(
        title: m['title'] ?? '',
        url: m['url'] ?? '',
        source: m['source']?['name'] ?? 'NewsAPI',
        imageUrl: m['urlToImage'] ?? '',
        publishedAt: DateTime.tryParse(m['publishedAt'] ?? '') ?? DateTime.now(),
        snippet: m['description'] ?? '',
      );
    }).toList();
  }

  Iterable<NewsArticle> _dedupeByUrl(List<NewsArticle> items) {
    final seen = <String, NewsArticle>{};
    for (final a in items) {
      if (!seen.containsKey(a.url)) seen[a.url] = a;
    }
    return seen.values
        .sortedByCompare((a) => a.publishedAt, (a, b) => b.compareTo(a));
  }

  Future<NewsArticle?> _summariseWithOpenAI(NewsArticle article) async {
    if (_openAiKey.isEmpty || article.snippet.isEmpty) return null;

    final prompt = '''
Please carefully read the following Irish education news article.

Determine if it is specifically relevant to:
✅ Irish secondary schools (e.g., curriculum, exams, student life, buildings, funding, policies)
✅ Irish third-level (university/college) education (e.g., courses, student grants, admissions, fees, policies)

If it is **NOT** relevant to Irish secondary or third-level education, reply only with:
NOT RELEVANT

If it **is** relevant, write a detailed, clear summary in around 150 words. The summary should include:
✅ The main points of the article
✅ Any background or context that helps understand it
✅ Why this news matters to Irish secondary or third-level students
✅ Write in **short, clear sentences** to make it easy to read and understand

Use plain, student-friendly language. Do not shorten or skip details.

TITLE: ${article.title}
SNIPPET: ${article.snippet}
''';

    final body = {
      'model': 'gpt-4o-mini',
      'messages': [
        {
          'role': 'system',
          'content': 'You are an Irish education news analyst. Provide concise and polite answers for students.',
        },
        {
          'role': 'user',
          'content': prompt,
        }
      ],
      'temperature': 0.4,
    };

    final res = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_openAiKey',
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 20));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final content = ((data['choices'] as List<dynamic>).first)['message']['content'] ?? '';
      if (content.contains('NOT RELEVANT')) {
        return null;
      }
      return article.copyWith(summary: content, whyMatters: null);
    }
    return null;
  }
}
