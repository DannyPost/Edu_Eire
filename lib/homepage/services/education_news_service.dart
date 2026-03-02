import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/news_article.dart';

class EducationNewsService {
  EducationNewsService._();
  static final EducationNewsService instance = EducationNewsService._();

  String get _newsDataKey => dotenv.env['NEWSDATA_API_KEY'] ?? '';
  String get _openAiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  Future<List<NewsArticle>> fetchSummarised({int maxItems = 20}) async {
  final articles = await _fetchNewsData();
  final deduped = _dedupeByUrl(articles).toList();

  // 🔑 If OpenAI is not configured, return raw articles
  if (_openAiKey.isEmpty) {
    print('[NewsService] OpenAI key missing — returning raw articles');
    return deduped.take(maxItems).toList();
  }

  const batchSize = 3;
  final summarised = <NewsArticle>[];

  for (var i = 0; i < deduped.length; i += batchSize) {
    final batch = deduped.skip(i).take(batchSize);
    final results = await Future.wait(batch.map(_summariseWithOpenAI));
    summarised.addAll(results.whereType<NewsArticle>());
    await Future.delayed(const Duration(milliseconds: 1200));
  }

  // 🛟 Fallback if everything was filtered out
  if (summarised.isEmpty) {
    print('[NewsService] All articles filtered — showing raw feed');
    return deduped.take(maxItems).toList();
  }

  return summarised.take(maxItems).toList();
}


  /// ✅ newsdata.io fetch
  Future<List<NewsArticle>> _fetchNewsData() async {
    if (_newsDataKey.isEmpty) return [];

    final uri = Uri.https(
      'newsdata.io',
      '/api/1/latest',
      {
        'apikey': _newsDataKey,
        'country': 'ie',
        'language': 'en',
        'category': 'education',
      },
    );

    print('[NewsService] Fetching Irish education news: $uri');

    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return [];

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final results = json['results'] as List<dynamic>? ?? [];

    return results
        .map((e) => NewsArticle.fromNewsData(e as Map<String, dynamic>))
        .where((a) => a.title.isNotEmpty && a.url.isNotEmpty)
        .toList();
  }

  Iterable<NewsArticle> _dedupeByUrl(List<NewsArticle> items) {
    final seen = <String, NewsArticle>{};
    for (final a in items) {
      if (!seen.containsKey(a.url)) {
        seen[a.url] = a;
      }
    }
    return seen.values.sortedByCompare(
      (a) => a.publishedAt,
      (a, b) => b.compareTo(a),
    );
  }

  /// ✅ unchanged OpenAI summarisation
  Future<NewsArticle?> _summariseWithOpenAI(NewsArticle article) async {
    if (_openAiKey.isEmpty || article.snippet.isEmpty) return null;

    final prompt = '''
Please carefully read the following Irish education news article.

Determine if it is specifically relevant to:
✅ Irish secondary schools
✅ Irish third-level education

If it is NOT relevant, reply only with:
NOT RELEVANT

If it IS relevant, write a clear ~150-word summary in student-friendly language.

TITLE: ${article.title}
SNIPPET: ${article.snippet}
''';

    final body = {
      'model': 'gpt-4o-mini',
      'messages': [
        {
          'role': 'system',
          'content': 'You are an Irish education news analyst.',
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
      final content =
          data['choices'][0]['message']['content'] as String? ?? '';

      if (content.contains('NOT RELEVANT')) return null;

      return article.copyWith(summary: content);
    }
    return null;
  }
}
