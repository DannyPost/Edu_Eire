class NewsArticle {
  final String title;
  final String url;
  final String source;
  final String imageUrl; // ADD THIS
  final DateTime publishedAt;
  final String snippet;

  final String? summary;      // Optional: for summarised content
  final String? whyMatters;   // Optional: why it matters

  NewsArticle({
    required this.title,
    required this.url,
    required this.source,
    required this.imageUrl, // ADD THIS
    required this.publishedAt,
    required this.snippet,
    this.summary,
    this.whyMatters,
  });

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
      imageUrl: imageUrl, // ADD THIS
      publishedAt: publishedAt,
      snippet: snippet,
      summary: summary ?? this.summary,
      whyMatters: whyMatters ?? this.whyMatters,
    );
  }
}
