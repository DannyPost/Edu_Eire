/// Domain entity representing a chat message in the Study Bot.
/// Pure data: no JSON or UI concerns here.
enum ChatSender { user, bot }

class ChatMessage {
  final String id;            // e.g., a uuid or timestamp string
  final String text;
  final ChatSender sender;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    ChatSender? sender,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() =>
      'ChatMessage(id: $id, sender: $sender, text: "$text", ts: $timestamp)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          text == other.text &&
          sender == other.sender &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      id.hashCode ^ text.hashCode ^ sender.hashCode ^ timestamp.hashCode;
}
