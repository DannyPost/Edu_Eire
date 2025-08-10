class ChatRequest {
  final String message;
  final Map<String, dynamic>? context;

  const ChatRequest({required this.message, this.context});

  Map<String, dynamic> toJson() => {
        'message': message,
        if (context != null) 'context': context,
      };
}
