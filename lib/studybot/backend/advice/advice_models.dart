// lib/studybot/backend/advice/advice_models.dart
class AdviceRequest {
  final String prompt;
  final Map<String, dynamic>? meta;

  AdviceRequest({required this.prompt, this.meta});

  Map<String, dynamic> toJson() => {
        "prompt": prompt,
        if (meta != null) "meta": meta,
      };
}

class AdviceResponse {
  final String text;
  final String? model;
  final int? tokens;

  AdviceResponse({required this.text, this.model, this.tokens});

  factory AdviceResponse.fromJson(Map<String, dynamic> json) {
    // Accept either {text:"..."} or {message:"..."} or nested {data:{text}}
    final body = json['data'] is Map ? (json['data'] as Map) : json;
    final txt = (body['text'] ?? body['message'] ?? "").toString();
    return AdviceResponse(
      text: txt,
      model: body['model']?.toString(),
      tokens: body['tokens'] is int ? body['tokens'] as int : null,
    );
  }
}
