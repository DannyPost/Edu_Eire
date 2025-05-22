import 'package:flutter/material.dart';
import '../services/openai_service.dart';
import '../models/message_model.dart';
import '../utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = [];

  Future<void> _sendMessage() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    final userMessage = Message(role: 'user', text: input);
    setState(() {
      _messages.add(userMessage);
      _controller.clear();
    });

    // Log user message (non-blocking)
    ChatLogger.logMessage('User', input).catchError((e) {
      debugPrint('Failed to log user message: $e');
    });

    try {
      final reply = await fetchChatGPTResponse(input);
      final botMessage = Message(role: 'bot', text: reply);

      setState(() {
        _messages.add(botMessage);
      });

      // Log bot reply (non-blocking)
      ChatLogger.logMessage('Bot', reply).catchError((e) {
        debugPrint('Failed to log bot reply: $e');
      });
    } catch (e) {
      final errorMsg = 'Error: $e';
      final errorMessage = Message(role: 'bot', text: errorMsg);

      setState(() {
        _messages.add(errorMessage);
      });

      // Log error (non-blocking)
      ChatLogger.logMessage('Bot', errorMsg).catchError((e) {
        debugPrint('Failed to log error: $e');
      });
    }
  }

  Widget _buildMessage(Message message) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF3AB6FF) : Colors.white,
          border: isUser ? null : Border.all(color: const Color(0xFF3AB6FF)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SelectableText(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : const Color(0xFF003B66),
            fontSize: 16,
          ),
          contextMenuBuilder: (context, editableTextState) {
            return CupertinoAdaptiveTextSelectionToolbar.buttonItems(
              anchors: editableTextState.contextMenuAnchors,
              buttonItems: [
                ContextMenuButtonItem(
                  label: 'Copy',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: message.text));
                    Navigator.pop(context);
                  },
                ),
                ContextMenuButtonItem(
                  label: 'Search Web',
                  onPressed: () async {
                    final query = Uri.encodeComponent(message.text);
                    final url = Uri.parse('https://www.google.com/search?q=$query');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3AB6FF),
        centerTitle: true,
        leading: IconButton(
          icon: Image.asset('assets/menu.png', height: 24, width: 24),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: Image.asset('assets/back_arrow.png', height: 24, width: 24),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/edu_eire_logo.png', height: 36),
            const SizedBox(width: 10),
            const Text(
              'Edu Bot',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (_, index) => _buildMessage(_messages[index]),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ask a question...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF3AB6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
