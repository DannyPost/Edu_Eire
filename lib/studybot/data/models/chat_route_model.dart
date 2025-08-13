/// DTO that mirrors /chat response JSON (router).
class ChatRouteModel {
  final String type; // grade | exemplar | advice | prediction | paper | fallback
  final Map<String, dynamic> payload;
  final double? confidence;

  const ChatRouteModel({
    required this.type,
    required this.payload,
    this.confidence,
  });

  factory ChatRouteModel.fromJson(Map<String, dynamic> json) => ChatRouteModel(
        type: json['type'] as String,
        payload: (json['payload'] as Map).cast<String, dynamic>(),
        confidence: json['confidence'] == null
            ? null
            : (json['confidence'] as num).toDouble(),
      );
}
