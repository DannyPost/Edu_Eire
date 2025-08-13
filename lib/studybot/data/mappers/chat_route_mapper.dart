import '../../domain/repositories/chat_repository.dart';
import '../models/chat_route_model.dart';

class ChatRouteMapper {
  static ChatRoute toEntity(ChatRouteModel model) =>
      ChatRoute(type: model.type, payload: model.payload, confidence: model.confidence);
}
