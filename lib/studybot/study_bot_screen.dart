// ───────────────────────────────────────────────────────────
// lib/studybot/study_bot_screen.dart
// Minimal Study-Bot chat UI – wired to LangChain backend
// ───────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert' show jsonEncode, utf8;           // ✅ for jsonEncode / utf8
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';     // ✅ FirebaseAuth
import 'package:http/http.dart' as http;               // ✅ http.Request

/*───────────────────────────────────────────────────────────
  ⏳  Typing-dots “…”
───────────────────────────────────────────────────────────*/
class TypingDots extends StatefulWidget {
  const TypingDots({super.key});
  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
        ..repeat();
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final dots = (_c.value * 3).floor() % 3 + 1;
          return Text('.' * dots,
              style: TextStyle(fontSize: 20, color: Theme.of(context).primaryColor));
        },
      );
}

/*───────────────────────────────────────────────────────────
  ⌨️  Typewriter reveal for bot replies
───────────────────────────────────────────────────────────*/
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const TypewriterText({super.key, required this.text, required this.style});
  @override State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _shown = '';
  late final Timer _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 20), (t) {
      if (_shown.length < widget.text.length) {
        setState(() => _shown = widget.text.substring(0, _shown.length + 1));
      } else {
        _timer.cancel();
      }
    });
  }
  @override void dispose() { _timer.cancel(); super.dispose(); }
  @override Widget build(BuildContext ctx) => Text(_shown, style: widget.style);
}

/*───────────────────────────────────────────────────────────
  📱  Study-Bot screen
───────────────────────────────────────────────────────────*/
class StudyBotScreen extends StatefulWidget {
  const StudyBotScreen({super.key});
  @override
  State<StudyBotScreen> createState() => _StudyBotScreenState();
}

class _StudyBotScreenState extends State<StudyBotScreen> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  final _focus  = FocusNode();

  final _messages = <_Msg>[
    _Msg.bot('Hi there! I’m your Study-Bot. How can I help? 🤓'),
  ];

  bool _loading = false;
  bool _typed   = false;
  List<String> _suggestions = [];

  final _allSuggestions = [
    'How do I improve in English poetry?',
    'Predict topics for Paper 1',
    'Give me a mock LC exam',
    'What are my weak areas?',
    'Show an exemplar essay'
  ];
  final _defaultPrompts = [
    'Grade my answer',
    'Likely Paper 2 topics?',
    'Generate a mock paper'
  ];

  /* —— Backend stub: replace with real HTTPS call later —— */
Future<String> _sendToBackend(String prompt) async {
  final idToken = await FirebaseAuth.instance.currentUser!.getIdToken();
  final uri = Uri.parse('https://europe-west1-<GCP_PROJECT>.cloudfunctions.net/studybot/studybot');

  final req = http.Request('POST', uri)
    ..headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    })
    ..body = jsonEncode({'prompt': prompt});

  final res = await req.send();

  // Stream chunks as they arrive
  final buffer = StringBuffer();
  await res.stream.transform(utf8.decoder).forEach(buffer.write);
  if (res.statusCode != 200) throw buffer.toString();
  return buffer.toString().trim();
}


  /*──────────────── listeners ─────────────────────────────*/
  void _onTextChanged() {
    final input = _ctrl.text.toLowerCase();
    setState(() {
      _typed = input.isNotEmpty;
      _suggestions = _allSuggestions
          .where((s) => s.toLowerCase().contains(input))
          .take(5)
          .toList();
    });
  }

  Future<void> _handleSend() async {
    final txt = _ctrl.text.trim();
    if (txt.isEmpty) return;
    setState(() {
      _messages.add(_Msg.user(txt));
      _ctrl.clear();
      _typed = false;
      _suggestions = [];
      _loading = true;
    });
    await _scrollToBottom();

    final reply = await _sendToBackend(txt);
    setState(() {
      _messages.add(_Msg.bot(reply));
      _loading = false;
    });
    await _scrollToBottom();
  }

  Future<void> _scrollToBottom() async {
    await Future.delayed(const Duration(milliseconds: 60));
    _scroll.animateTo(
      _scroll.position.maxScrollExtent + 80,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  /*──────────────── UI ───────────────────────────────────*/
  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).primaryColor;
    final card  = Theme.of(context).cardColor;
    final txt   = Theme.of(context).textTheme.bodyLarge!.color;

    /// one message bubble
    Widget bubble(_Msg m) {
      final isMe  = m.role == _Role.user;
      final bg    = isMe ? brand : card;
      final color = isMe ? Colors.white : txt;
      final border = isMe ? null : Border.all(color: brand);

      final inner = isMe
          ? Text(m.text, style: TextStyle(color: color, fontSize: 16))
          : TypewriterText(text: m.text, style: TextStyle(color: color, fontSize: 16));

      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(maxWidth: 280),
          decoration: BoxDecoration(
            color: bg,
            border: border,
            borderRadius: BorderRadius.circular(12),
          ),
          child: inner,
        ),
      );
    }

    /// bot typing indicator
    Widget typing() => Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: card,
          border: Border.all(color: brand),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('Bot is typing', style: TextStyle(color: brand)),
          const SizedBox(width: 6),
          const TypingDots(),
        ]),
      ),
    );

    /// suggestion chips
    Widget chips() {
      final list = _typed ? _suggestions : _defaultPrompts;
      if (list.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Wrap(
          spacing: 8,
          children: list.map((s) => GestureDetector(
            onTap: () {
              _ctrl.text = s;
              _ctrl.selection = TextSelection.fromPosition(TextPosition(offset: s.length));
              _focus.requestFocus();
            },
            child: Chip(
              label: Text(s, style: TextStyle(color: brand)),
              backgroundColor: card,
              shape: StadiumBorder(side: BorderSide(color: brand.withOpacity(.3))),
            ),
          )).toList(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study-Bot'),
        backgroundColor: brand,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (_, i) {
                if (_loading && i == _messages.length) return typing();
                return bubble(_messages[i]);
              },
            ),
          ),
          chips(),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      minLines: 1,
                      maxLines: 3,
                      cursorColor: brand,
                      decoration: InputDecoration(
                        hintText: 'Ask a question…',
                        filled: true,
                        fillColor: card,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: brand, width: 2),
                        ),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: brand,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _handleSend,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/*──────────────── model ───────────────────────────────────*/
enum _Role { user, bot }
class _Msg {
  final _Role role;
  final String text;
  _Msg._(this.role, this.text);
  factory _Msg.user(String t) => _Msg._(_Role.user, t);
  factory _Msg.bot (String t) => _Msg._(_Role.bot , t);
}
