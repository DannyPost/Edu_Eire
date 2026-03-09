// lib/studybot/backend/chat/chat_response.dart
import 'chat_models.dart';

class ChatResponse {
  final ChatRoute route;
  final String? text; // some router variants include a text
  ChatResponse({required this.route, this.text});

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      route: ChatRoute.fromJson(json),
      text: json['text'] as String?,
    );
  }
}
