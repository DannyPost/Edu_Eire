// lib/studybot/backend/chat/chat_models.dart

/// Which specialised chain to call.
enum ChatTask { advice, exemplar, paper, grade, prediction, fallback }

ChatTask taskFromString(String v) {
  switch (v) {
    case "advice": return ChatTask.advice;
    case "exemplar": return ChatTask.exemplar;
    case "paper": return ChatTask.paper;
    case "grade": return ChatTask.grade;
    case "prediction": return ChatTask.prediction;
    default: return ChatTask.fallback;
  }
}

class ChatRoute {
  final ChatTask task;
  final double confidence;
  final String? reasons;
  final String? model;

  ChatRoute({
    required this.task,
    required this.confidence,
    this.reasons,
    this.model,
  });

  factory ChatRoute.fromJson(Map<String, dynamic> json) {
    // Accept either decision.route or type
    final decision = json['decision'] as Map<String, dynamic>?;
    final routeStr = (decision?['route'] ?? json['type'] ?? 'fallback').toString();
    return ChatRoute(
      task: taskFromString(routeStr),
      confidence: (decision?['confidence'] ?? json['confidence'] ?? 0.0).toDouble(),
      reasons: decision?['reasons']?.toString(),
      model: decision?['model']?.toString() ?? json['model']?.toString(),
    );
  }
}
