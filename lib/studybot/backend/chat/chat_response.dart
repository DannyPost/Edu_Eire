class ChatResponse {
  /// grade | exemplar | advice | prediction | paper | fallback
  final String type;
  final Map<String, dynamic> payload;
  final double? confidence;

  const ChatResponse({
    required this.type,
    required this.payload,
    this.confidence,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) => ChatResponse(
        type: json['type'] as String,
        payload: (json['payload'] as Map).cast<String, dynamic>(),
        confidence: (json['confidence'] == null)
            ? null
            : (json['confidence'] as num).toDouble(),
      );
}
