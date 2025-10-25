// lib/studybot/data/repositories/chat_repository_impl.dart
import '../../services/api_client.dart';
import '../../backend/common/api_paths.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ApiClient _api;
  ChatRepositoryImpl(this._api);

  @override
  Future<ChatRoute> routeMessage({
    required String message,
    Map<String, dynamic>? meta,
    List<dynamic> history = const [],
  }) async {
    final body = <String, dynamic>{
      'message': message,
      if (history.isNotEmpty) 'history': history,
      if (meta != null) 'meta': meta,
    };

    final json = await _api.postJson(ApiPaths.chat, body);

    // Be tolerant with backend field names
    final type = (json['type'] ?? json['label'] ?? 'fallback').toString();
    final conf = json['confidence'];
    final double? confidence =
        conf is num ? conf.toDouble() : (conf is String ? double.tryParse(conf) : null);

    final Map<String, dynamic> payload = Map<String, dynamic>.from(
      json['routeMeta'] ??
      json['payload'] ??
      json['route_meta'] ??
      const <String, dynamic>{},
    );

    return ChatRoute(
      type: type,
      payload: payload,
      confidence: confidence,
    );
  }
}
