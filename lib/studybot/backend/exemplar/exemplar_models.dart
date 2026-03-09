// lib/studybot/backend/exemplar/exemplar_models.dart
class ExemplarRequest {
  final String question;
  final Map<String, dynamic>? meta;
  ExemplarRequest({required this.question, this.meta});

  Map<String, dynamic> toJson() => {
        "question": question,
        if (meta != null) "meta": meta,
      };
}

class ExemplarResponse {
  final String text;
  final String? model;
  final int? tokens;

  ExemplarResponse({required this.text, this.model, this.tokens});

  factory ExemplarResponse.fromJson(Map<String, dynamic> json) {
    final body = json['data'] is Map ? (json['data'] as Map) : json;
    return ExemplarResponse(
      text: (body['text'] ?? "").toString(),
      model: body['model']?.toString(),
      tokens: body['tokens'] is int ? body['tokens'] as int : null,
    );
  }
}
