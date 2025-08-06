import 'package:flutter/material.dart';
import '../services/openai_service.dart';
import '../models/message_model.dart';
import '../utils/logger.dart';
import 'dart:async';

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration speed;
  const TypewriterText({required this.text, required this.style, this.speed = const Duration(milliseconds: 20), Key? key}) : super(key: key);

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String displayed = "";
  int i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.speed, (timer) {
      if (i < widget.text.length) {
        setState(() => displayed += widget.text[i++]);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(displayed, style: widget.style);
  }
}

class TypingDots extends StatefulWidget {
  const TypingDots({Key? key}) : super(key: key);
  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _animation = Tween<double>(begin: 0, end: 3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) {
        int dots = (_animation.value % 3).floor() + 1;
        return Text(
          '.' * dots,
          style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.primary),
        );
      },
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = [];
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  List<String> _suggestions = [];
  bool _hasTyped = false;

  final List<String> _allSuggestions = [
    'How do I apply to college in Ireland?',
    'What is the SUSI grant?',
    'How many points do I need for medicine?',
    'What are HEAR and DARE schemes?',
    'What is a PLC course?',
    'Can I apply to UK universities through CAO?',
    'Do I need Irish for university?',
    'When is the SUSI deadline?',
    'What is the CAO Change of Mind?',
    'How do grants work for part-time students?',
    'What are level 6, 7, 8 courses?',
    'Tips for writing a personal statement'
  ];

  final List<String> _defaultPrompts = [
    'How do I apply to college in Ireland?',
    'What is the SUSI grant?',
    'How many points for medicine?',
    'What are HEAR and DARE?',
    'Do I need Irish for university?'
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _loadPreviousLog();
  }

  Future<void> _loadPreviousLog() async {
    final log = await ChatLogger.getLog();
    if (log.isNotEmpty) {
      final lines = log.split('\n');
      setState(() {
        _messages.clear();
        for (var line in lines) {
          if (line.contains('User:')) {
            final text = line.substring(line.indexOf('User:') + 5).trim();
            _messages.add(Message(role: 'user', text: text));
          } else if (line.contains('Bot:')) {
            final text = line.substring(line.indexOf('Bot:') + 4).trim();
            _messages.add(Message(role: 'bot', text: text));
          }
        }
      });
    }
  }

  void _onTextChanged() {
    final input = _controller.text.toLowerCase();
    if (input.isEmpty) {
      setState(() {
        _suggestions = [];
        _hasTyped = false;
      });
    } else {
      setState(() {
        _hasTyped = true;
        _suggestions = _allSuggestions.where((s) => s.toLowerCase().contains(input)).take(5).toList();
      });
    }
  }

  Future<void> _sendMessage() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;
    final userMessage = Message(role: 'user', text: input);
    setState(() {
      _messages.add(userMessage);
      _controller.clear();
      _suggestions = [];
      _hasTyped = false;
      _isLoading = true;
    });
    await ChatLogger.logMessage('User', input).catchError((e) => debugPrint('$e'));
    try {
      final reply = await fetchChatGPTResponse(input);
      final botMessage = Message(role: 'bot', text: reply);
      setState(() {
        _messages.add(botMessage);
        _isLoading = false;
      });
      await ChatLogger.logMessage('Bot', reply).catchError((e) => debugPrint('$e'));
    } catch (e) {
      final errorMsg = 'Error: $e';
      setState(() {
        _messages.add(Message(role: 'bot', text: errorMsg));
        _isLoading = false;
      });
      await ChatLogger.logMessage('Bot', errorMsg).catchError((e) => debugPrint('$e'));
    }
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: Theme.of(context).colorScheme.primary),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Eoin is typing', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            const SizedBox(width: 6),
            const TypingDots()
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(Message message) {
    final isUser = message.role == 'user';
    final bgColor = isUser ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor;
    final textColor = isUser ? Colors.white : Theme.of(context).textTheme.bodyLarge!.color;
    final border = isUser ? null : Border.all(color: Theme.of(context).colorScheme.primary);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          border: border,
          borderRadius: BorderRadius.circular(12),
        ),
        child: isUser
            ? Text(message.text, style: TextStyle(color: textColor, fontSize: 16))
            : TypewriterText(text: message.text, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color, fontSize: 16)),
      ),
    );
  }

  Widget _buildSuggestions() {
    final suggestionsToShow = _hasTyped ? _suggestions : _defaultPrompts;
    if (suggestionsToShow.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        children: suggestionsToShow.map((s) {
          return GestureDetector(
            onTap: () {
              _controller.text = s;
              _controller.selection = TextSelection.fromPosition(TextPosition(offset: s.length));
              _focusNode.requestFocus();
            },
            child: Chip(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
              ),
              label: Text(
                s,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              backgroundColor: Theme.of(context).cardColor,
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/chatbot/edu_eire_logo.png', height: 36),
            const SizedBox(width: 10),
            const Text('Edu Bot', style: TextStyle(color: Colors.white))
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (_, index) {
                if (_isLoading && index == _messages.length) {
                  return _buildTypingBubble();
                }
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          _buildSuggestions(),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    cursorColor: Theme.of(context).colorScheme.primary,
                    decoration: InputDecoration(
                      hintText: 'Ask a question...',
                      focusedBorder: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: const OutlineInputBorder(
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
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
