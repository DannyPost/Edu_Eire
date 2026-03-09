// lib/studybot/backend/grade/grade_models.dart
class GradeRequest {
  final String question;
  final String answer;
  final Map<String, dynamic>? meta;
  GradeRequest({required this.question, required this.answer, this.meta});

  Map<String, dynamic> toJson() => {
        "question": question,
        "answer": answer,
        if (meta != null) "meta": meta,
      };
}

class GradeResponse {
  final num score;          // 0–100
  final String comment;     // feedback
  final String? model;
  final Map<String, dynamic>? rubric;

  GradeResponse({
    required this.score,
    required this.comment,
    this.model,
    this.rubric,
  });

  factory GradeResponse.fromJson(Map<String, dynamic> json) {
    final body = json['data'] is Map ? (json['data'] as Map) : json;
    return GradeResponse(
      score: (body['score'] ?? body['mark'] ?? 0) as num,
      comment: (body['comment'] ?? body['feedback'] ?? "").toString(),
      model: body['model']?.toString(),
      rubric: body['rubric'] is Map<String, dynamic> ? body['rubric'] : null,
    );
  }
}
