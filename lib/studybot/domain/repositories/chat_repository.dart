// lib/studybot/domain/repositories/chat_repository.dart

/// Abstraction for routing/chat-related operations.
/// The data layer will implement this and call the /chat endpoint.
abstract class ChatRepository {
  /// Route a user message to a task type and payload.
  /// Returns a ChatRoute describing which specialised chain to call.
  Future<ChatRoute> routeMessage({
    required String message,
    Map<String, dynamic>? meta,          // unified name
    List<dynamic> history = const [],    // optional conversation turns
  });
}

/// Lightweight domain object describing a router decision.
class ChatRoute {
  /// One of: 'grade' | 'exemplar' | 'advice' | 'prediction' | 'paper' | 'fallback'
  final String type;

  /// Opaque payload the next chain needs (kept as a map at domain level).
  final Map<String, dynamic> payload;

  /// Optional confidence score from the router.
  final double? confidence;

  const ChatRoute({
    required this.type,
    required this.payload,
    this.confidence,
  });

  @override
  String toString() =>
      'ChatRoute(type: $type, payloadKeys: ${payload.keys.toList()}, confidence: $confidence)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatRoute &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          _mapEq(payload, other.payload) &&
          confidence == other.confidence;

  @override
  int get hashCode =>
      type.hashCode ^ payload.hashCode ^ (confidence?.hashCode ?? 0);
}

bool _mapEq(Map a, Map b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final k in a.keys) {
    if (!b.containsKey(k) || a[k] != b[k]) return false;
  }
  return true;
}
