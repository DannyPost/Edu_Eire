import '../../backend/backend.dart';
import '../../services/api_client.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_route_model.dart';
import '../mappers/chat_route_mapper.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ApiClient _api;

  ChatRepositoryImpl(this._api);

  @override
  Future<ChatRoute> routeMessage({
    required String message,
    Map<String, dynamic>? context,
  }) async {
    final req = ChatRequest(message: message, context: context);
    final json = await _api.postJson(ApiPaths.chat, req.toJson());
    final model = ChatRouteModel.fromJson(json);
    return ChatRouteMapper.toEntity(model);
  }
}
