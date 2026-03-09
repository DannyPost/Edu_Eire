// lib/studybot/data/repositories/chat_repository_impl.dart
import '../../backend/common/api_paths.dart';
import '../../backend/chat/chat_request.dart';
import '../../backend/chat/chat_response.dart';
import '../../backend/chat/chat_models.dart';
import '../../services/api_client.dart';

class ChatRepository {
  ChatRepository(this._client);
  final ApiClient _client;

  Future<ChatRoute> routeMessage({
    required String message,
    Map<String, dynamic>? meta,
    List<dynamic> history = const [],
  }) async {
    final req = ChatRequest(message: message, meta: meta, history: history);
    final json = await _client.postJson(ApiPaths.chat, body: req.toJson());
    final res = ChatResponse.fromJson(json);
    return res.route;
  }
}
