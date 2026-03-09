// lib/studybot/backend/chat/chat_request.dart
class ChatRequest {
  final String message;
  final Map<String, dynamic>? meta;
  final List<dynamic> history;

  ChatRequest({
    required this.message,
    this.meta,
    this.history = const [],
  });

  Map<String, dynamic> toJson() => {
        "message": message,
        if (meta != null) "meta": meta,
        if (history.isNotEmpty) "history": history,
      };
}
