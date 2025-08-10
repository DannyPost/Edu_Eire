class PredictedTopic {
  final String topic;
  final double confidence; // 0..1
  final String why;

  const PredictedTopic({
    required this.topic,
    required this.confidence,
    required this.why,
  });

  factory PredictedTopic.fromJson(Map<String, dynamic> json) => PredictedTopic(
        topic: json['topic'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        why: json['why'] as String,
      );

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'confidence': confidence,
        'why': why,
      };
}

class PredictionResponse {
  final List<PredictedTopic> topics;

  const PredictionResponse({required this.topics});

  factory PredictionResponse.fromJson(Map<String, dynamic> json) =>
      PredictionResponse(
        topics: (json['topics'] as List)
            .map((e) =>
                PredictedTopic.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}
