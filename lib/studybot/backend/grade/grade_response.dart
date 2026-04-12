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
        score: _scoreFromJson(json['score']),
        bullets: _bulletsFromJson(json['bullets']),
        meta: (json['meta'] is Map)
            ? (json['meta'] as Map).cast<String, dynamic>()
            : <String, dynamic>{},
      );

  static int _scoreFromJson(dynamic v) {
    if (v is int) return v.clamp(0, 100);
    if (v is double) return v.round().clamp(0, 100);
    if (v is num) return v.round().clamp(0, 100);
    if (v is String) {
      final n = num.tryParse(v);
      if (n != null) return n.round().clamp(0, 100);
    }
    return 0;
  }

  static List<String> _bulletsFromJson(dynamic v) {
    if (v is! List) return const [];
    return v.map((e) => e.toString()).toList();
  }
}
