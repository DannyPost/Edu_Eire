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

  // 🔒 HARD RULE: never show anything older than 60 days
  static const int _maxAgeDays = 60;

  Future<List<NewsArticle>> fetchSummarised({int maxItems = 20}) async {
    print(
      '[NewsService] Keys => NewsAPI:${_newsApiKey.isNotEmpty ? _newsApiKey.substring(0, 4) : "null"} OpenAI:${_openAiKey.isNotEmpty ? "loaded" : "null"}',
    );

    try {
      final articles = await _fetchNewsAPI();

      // HARD local cutoff (<= 60 days)
      final recent = _filterLastNDays(articles, _maxAgeDays);

      final deduped = _dedupeByUrl(recent).toList();

      const batchSize = 3;
      final summarised = <NewsArticle>[];

      for (var i = 0; i < deduped.length; i += batchSize) {
        final batch = deduped.skip(i).take(batchSize);
        final batchResults = await Future.wait(batch.map(_summariseWithOpenAI));
        summarised.addAll(batchResults.whereType<NewsArticle>());

        // keep your pacing
        await Future.delayed(const Duration(milliseconds: 1200));
      }

      return summarised.take(maxItems).toList();
    } catch (e, st) {
      print('[NewsService] ERROR => $e');
      print(st);
      rethrow;
    }
  }

  /// ✅ BROADER: fetch Irish news in general (still Irish domains, newest first).
  /// Then we filter strictly using OpenAI prompt.
  Future<List<NewsArticle>> _fetchNewsAPI() async {
    if (_newsApiKey.isEmpty) {
      print('[NewsService] NEWSAPI key is empty');
      return [];
    }

    // ✅ Broad query so we actually get results.
    // Using "Ireland" as a general anchor, but domains are already Irish.
    // This avoids the problem where strict education keywords return 0.
    final query = 'Ireland';

    final uri = Uri.https('newsapi.org', '/v2/everything', {
      'q': query,
      'language': 'en',
      'pageSize': '100',          // more candidates
      'sortBy': 'publishedAt',    // newest first
      'domains': 'irishtimes.com,rte.ie,independent.ie,irishexaminer.com,thejournal.ie',
      'searchIn': 'title,description',
    });

    print('[NewsService] Fetching general Irish news: $uri');

    final res = await http
        .get(
          uri,
          headers: {
            'X-Api-Key': _newsApiKey,
          },
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      print('[NewsService] NewsAPI error ${res.statusCode}: ${res.body}');
      return [];
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (json['articles'] as List<dynamic>? ?? const []);

    return list.map((e) {
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

  List<NewsArticle> _filterLastNDays(List<NewsArticle> items, int days) {
    final cutoff = DateTime.now().toUtc().subtract(Duration(days: days));
    return items.where((a) => a.publishedAt.toUtc().isAfter(cutoff)).toList();
  }

  Iterable<NewsArticle> _dedupeByUrl(List<NewsArticle> items) {
    final seen = <String, NewsArticle>{};
    for (final a in items) {
      final u = a.url.trim();
      if (u.isEmpty) continue;
      if (!seen.containsKey(u)) seen[u] = a;
    }

    return seen.values.sortedByCompare(
      (a) => a.publishedAt,
      (a, b) => b.compareTo(a),
    );
  }

  Future<NewsArticle?> _summariseWithOpenAI(NewsArticle article) async {
    if (_openAiKey.isEmpty || article.snippet.isEmpty) return null;

    // HARD 60-day cutoff again
    final cutoff = DateTime.now().toUtc().subtract(const Duration(days: _maxAgeDays));
    if (!article.publishedAt.toUtc().isAfter(cutoff)) return null;

    final prompt = '''
Please carefully read the following Irish news article.

Determine if it is specifically relevant to:
✅ Irish secondary schools (e.g., curriculum, exams, student life, policies, BT Young Scientist)
✅ Irish third-level (university/college) education (e.g., CAO, SUSI, admissions, fees, grants, apprenticeships)

Be VERY STRICT:
- If it is NOT clearly about Irish secondary or Irish third-level education → reply only: NOT RELEVANT
- If it is politics/crime/sport/celebrity/general news with no clear education impact → NOT RELEVANT
- If it is older than 60 days → NOT RELEVANT

If it IS relevant, write a detailed, clear summary in around 150 words:
- Main points
- Context
- Why it matters to Irish students
- Short, clear sentences
- Student-friendly language

TITLE: ${article.title}
SNIPPET: ${article.snippet}
''';

    final body = {
      'model': 'gpt-4o-mini',
      'messages': [
        {
          'role': 'system',
          'content': 'You are an Irish education news analyst. Provide clear, student-friendly summaries.',
        },
        {
          'role': 'user',
          'content': prompt,
        }
      ],
      'temperature': 0.4,
    };

    final res = await http
        .post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_openAiKey',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final content =
          ((data['choices'] as List<dynamic>).first)['message']['content'] ?? '';

      if (content.toString().contains('NOT RELEVANT')) return null;

      return article.copyWith(summary: content);
    }

    print('[NewsService] OpenAI error ${res.statusCode}: ${res.body}');
    return null;
  }
}