import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/news_article.dart';

class EducationNewsService {
  EducationNewsService._();
  static final EducationNewsService instance = EducationNewsService._();

  // Example: https://vh39fj1fv4.execute-api.eu-west-1.amazonaws.com/prod/homepage
  String get _homepageCacheUrl => dotenv.env['HOMEPAGE_CACHE_URL'] ?? '';

  // never show anything older than 60 days
  static const int _maxAgeDays = 60;

  Future<List<NewsArticle>> fetchSummarised({int maxItems = 20}) async {
    if (_homepageCacheUrl.isEmpty) {
      throw Exception('Missing HOMEPAGE_CACHE_URL in homepage.env');
    }

    final uri = Uri.parse(_homepageCacheUrl);
    final res = await http.get(uri, headers: {'Accept': 'application/json'});

    if (res.statusCode != 200) {
      throw Exception(
        'Homepage cache request failed: ${res.statusCode} ${res.body}',
      );
    }

    dynamic decoded = jsonDecode(res.body);

    // If API Gateway wrapper ever appears:
    // { statusCode, headers, body: "{...}" }
    if (decoded is Map<String, dynamic> && decoded.containsKey('body')) {
      final body = decoded['body'];
      decoded = (body is String) ? jsonDecode(body) : body;
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected homepage cache format');
    }

    final rawArticles = decoded['articles'];
    if (rawArticles is! List) return [];

    final cutoff = DateTime.now().toUtc().subtract(const Duration(days: _maxAgeDays));
    final seenUrls = <String>{};

    final articles = <NewsArticle>[];

    for (final item in rawArticles) {
      if (item is! Map) continue;
      final map = item.cast<String, dynamic>();

      final url = (map['url'] ?? '').toString().trim();
      if (url.isEmpty) continue;
      if (seenUrls.contains(url)) continue;

      final publishedAtStr = (map['publishedAt'] ?? '').toString().trim();
      final parsed = DateTime.tryParse(publishedAtStr);

      // ✅ publishedAt is required (non-nullable) in your model
      // Fallback to epoch if missing/bad
      final publishedAt = (parsed ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)).toUtc();

      // Keep the 60-day rule in the client too
      if (publishedAt.isBefore(cutoff)) continue;

      final summaryStr = (map['summary'] ?? '').toString().trim();
      final snippetStr = (map['snippet'] ?? '').toString().trim();

      final article = NewsArticle(
        title: (map['title'] ?? '').toString(),
        source: (map['source'] ?? '').toString(),
        url: url,
        imageUrl: (map['imageUrl'] ?? '').toString(),
        publishedAt: publishedAt,
        // Your Stage-3 output often has no snippet, so fallback to summary
        snippet: snippetStr.isNotEmpty ? snippetStr : summaryStr,
        summary: summaryStr.isNotEmpty ? summaryStr : null,
      );

      articles.add(article);
      seenUrls.add(url);

      if (articles.length >= maxItems) break;
    }

    // Sort newest first
    articles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return articles;
  }
}