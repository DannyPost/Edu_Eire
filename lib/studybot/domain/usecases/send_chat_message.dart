// lib/studybot/domain/usecases/send_chat_message.dart
import '../repositories/chat_repository.dart';

/// Use-case: send a user message to the router (/chat) and get back a route.
class SendChatMessage {
  final ChatRepository _repo;
  SendChatMessage(this._repo);

  Future<ChatRoute> call({
    required String message,
    Map<String, dynamic>? meta,
    List<dynamic> history = const [],
  }) {
    return _repo.routeMessage(
      message: message,
      meta: meta,
      history: history,
    );
  }
}
