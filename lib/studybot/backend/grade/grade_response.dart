class GradeResponse {
  final int score; // 0..100
  final List<String> bullets;
  final Map<String, dynamic> meta;

  const GradeResponse({
    required this.score,
    required this.bullets,
    required this.meta,
  });

  factory GradeResponse.fromJson(Map<String, dynamic> json) => GradeResponse(
        score: json['score'] as int,
        bullets: (json['bullets'] as List).map((e) => e.toString()).toList(),
        meta: (json['meta'] as Map).cast<String, dynamic>(),
      );
}
