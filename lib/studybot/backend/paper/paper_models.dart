// lib/studybot/backend/paper/paper_models.dart
class PaperRequest {
  final Map<String, dynamic> meta;
  PaperRequest({required this.meta});

  Map<String, dynamic> toJson() => {"meta": meta};
}

// We accept either a single 'text' field or a richer shape with sections.
class PaperResponse {
  final String text;
  final String? model;
  final Map<String, dynamic>? metadata;

  PaperResponse({required this.text, this.model, this.metadata});

  factory PaperResponse.fromJson(Map<String, dynamic> json) {
    final body = json['data'] is Map ? (json['data'] as Map) : json;
    final txt = (body['text'] ?? body['paper'] ?? "").toString();
    return PaperResponse(
      text: txt,
      model: body['model']?.toString(),
      metadata: body['metadata'] is Map<String, dynamic> ? body['metadata'] : null,
    );
  }
}
