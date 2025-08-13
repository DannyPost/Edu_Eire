/// Domain entity for the result of grading an answer.
class GradeResult {
  /// 0..100
  final int score;

  /// Short, actionable feedback bullets.
  final List<String> bullets;

  /// Optional metadata (e.g., questionId, rubricId).
  final Map<String, dynamic> meta;

  const GradeResult({
    required this.score,
    required this.bullets,
    this.meta = const {},
  });

  GradeResult copyWith({
    int? score,
    List<String>? bullets,
    Map<String, dynamic>? meta,
  }) {
    return GradeResult(
      score: score ?? this.score,
      bullets: bullets ?? this.bullets,
      meta: meta ?? this.meta,
    );
  }

  @override
  String toString() =>
      'GradeResult(score: $score, bullets: ${bullets.length}, meta: $meta)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradeResult &&
          runtimeType == other.runtimeType &&
          score == other.score &&
          _listEq(bullets, other.bullets) &&
          _mapEq(meta, other.meta);

  @override
  int get hashCode =>
      score.hashCode ^ bullets.fold(0, (p, e) => p ^ e.hashCode) ^ meta.hashCode;
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEq(Map a, Map b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final k in a.keys) {
    if (!b.containsKey(k) || a[k] != b[k]) return false;
  }
  return true;
}
