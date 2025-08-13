import '../../domain/repositories/chat_repository.dart';
import '../common/status.dart';

class ChatState {
  final Status status;
  final ChatRoute? route;       // result from /chat
  final String? errorMessage;   // non-PII error text

  const ChatState({
    this.status = Status.idle,
    this.route,
    this.errorMessage,
  });

  ChatState copyWith({
    Status? status,
    ChatRoute? route,
    String? errorMessage,
  }) {
    return ChatState(
      status: status ?? this.status,
      route: route ?? this.route,
      errorMessage: errorMessage,
    );
  }
}
