class NewsArticle {
  final String title;
  final String url;
  final String source;
  final String imageUrl;
  final DateTime publishedAt;
  final String snippet;

  final String? summary;
  final String? whyMatters;

  NewsArticle({
    required this.title,
    required this.url,
    required this.source,
    required this.imageUrl,
    required this.publishedAt,
    required this.snippet,
    this.summary,
    this.whyMatters,
  });

  /// ✅ NEW: factory for newsdata.io JSON
  factory NewsArticle.fromNewsData(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? '',
      url: json['link'] ?? '',
      source: json['source_name'] ?? 'NewsData',
      imageUrl: json['image_url'] ?? '',
      publishedAt: DateTime.tryParse(json['pubDate'] ?? '') ?? DateTime.now(),
      snippet: json['description'] ?? '',
    );
  }

  String get formattedDate =>
      '${publishedAt.day}/${publishedAt.month}/${publishedAt.year}';

  NewsArticle copyWith({
    String? summary,
    String? whyMatters,
  }) {
    return NewsArticle(
      title: title,
      url: url,
      source: source,
      imageUrl: imageUrl,
      publishedAt: publishedAt,
      snippet: snippet,
      summary: summary ?? this.summary,
      whyMatters: whyMatters ?? this.whyMatters,
    );
  }
}
