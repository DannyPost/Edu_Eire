class NewsArticle {
  final String title;
  final String url;
  final String source;
  final String imageUrl;
  final DateTime publishedAt;
  final String snippet;

  final String? summary; // AI summary (optional)

  const NewsArticle({
    required this.title,
    required this.url,
    required this.source,
    required this.imageUrl,
    required this.publishedAt,
    required this.snippet,
    this.summary,
  });

  NewsArticle copyWith({
    String? title,
    String? url,
    String? source,
    String? imageUrl,
    DateTime? publishedAt,
    String? snippet,
    String? summary,
  }) {
    return NewsArticle(
      title: title ?? this.title,
      url: url ?? this.url,
      source: source ?? this.source,
      imageUrl: imageUrl ?? this.imageUrl,
      publishedAt: publishedAt ?? this.publishedAt,
      snippet: snippet ?? this.snippet,
      summary: summary ?? this.summary,
    );
  }

  static NewsArticle? fromNewsApiJson(Map<String, dynamic> json) {
    final title = (json['title'] ?? '').toString().trim();
    final url = (json['url'] ?? '').toString().trim();
    final source = ((json['source'] ?? {})['name'] ?? '').toString().trim();

    if (title.isEmpty || url.isEmpty) return null;

    final imageUrl = (json['urlToImage'] ?? '').toString().trim();
    final snippet = (json['description'] ?? '').toString().trim();

    DateTime publishedAt;
    final publishedRaw = (json['publishedAt'] ?? '').toString();
    try {
      publishedAt = DateTime.parse(publishedRaw);
    } catch (_) {
      publishedAt = DateTime.now();
    }

    return NewsArticle(
      title: title,
      url: url,
      source: source.isEmpty ? 'Unknown' : source,
      imageUrl: imageUrl,
      publishedAt: publishedAt.toUtc(),
      snippet: snippet,
    );
  }
}