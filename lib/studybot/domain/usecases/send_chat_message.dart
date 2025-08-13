import '../repositories/chat_repository.dart';

/// Use case: route a user's free text to the correct chain.
/// Thin wrapper so state layer can depend on a stable API.
class SendChatMessage {
  final ChatRepository _repo;

  const SendChatMessage(this._repo);

  /// Returns a ChatRoute describing which endpoint to call next.
  Future<ChatRoute> call({
    required String message,
    Map<String, dynamic>? context,
  }) {
    return _repo.routeMessage(message: message, context: context);
  }
}
