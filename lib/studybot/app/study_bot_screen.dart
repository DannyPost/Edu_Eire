// lib/studybot/app/study_bot_screen.dart
// Minimal Study-Bot chat UI + router → exemplar/grade wiring
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

// State
import '../state/common/status.dart';
import '../state/grade/grade_notifier.dart';
import '../state/grade/grade_state.dart';
import '../state/chat/chat_notifier.dart';
import '../state/chat/chat_state.dart';
import '../state/exemplar/exemplar_notifier.dart';
import '../state/exemplar/exemplar_state.dart';

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
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final dots = (_c.value * 3).floor() % 3 + 1;
          return Text('.' * dots, style: TextStyle(fontSize: 20, color: Theme.of(context).primaryColor));
        },
      );
}

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;
  const TypewriterText({super.key, required this.text, required this.style, this.duration = const Duration(milliseconds: 30)});
  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}
class _TypewriterTextState extends State<TypewriterText> {
  String _displayed = ""; late int _currentIndex; late final List<String> _characters; late final Duration _duration;
  @override
  void initState() { super.initState(); _characters = widget.text.split(''); _currentIndex = 0; _duration = widget.duration; _tick(); }
  void _tick() async {
    while (_currentIndex < _characters.length) {
      await Future.delayed(_duration);
      if (!mounted) return;
      setState(() { _displayed += _characters[_currentIndex]; _currentIndex++; });
    }
  }
  @override
  Widget build(BuildContext context) => Text(_displayed, style: widget.style);
}

class StudyBotScreen extends StatefulWidget { const StudyBotScreen({super.key}); @override State<StudyBotScreen> createState() => _StudyBotScreenState(); }
class _StudyBotScreenState extends State<StudyBotScreen> {
  final TextEditingController _controller = TextEditingController();
  @override void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _printFirebaseIdToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) { _snack('No user signed in.'); return; }
      String? token = await user.getIdToken(true);
      if (token == null || token.isEmpty) { _snack('Could not fetch ID token.'); return; }
      token = token.replaceAll('\r', '').replaceAll('\n', '');
      // ignore: avoid_print
      print('FIREBASE_ID_TOKEN:$token');
      await Clipboard.setData(ClipboardData(text: token));
      final preview = token.length > 24 ? '${token.substring(0, 24)}…' : token;
      _snack('ID token copied: $preview');
    } catch (e) { _snack('Failed to get ID token: $e'); }
  }

  Future<void> _testGrade(BuildContext context) async {
    final text = _controller.text.trim().isEmpty ? 'This is my test answer for the StudyBot grading flow.' : _controller.text.trim();
    final grade = context.read<GradeNotifier>();
    await grade.submit(answer: text, meta: {'subject': 'English','year': 2024,'section': 'Poetry','questionId': 'poetry_q1'});
    final state = grade.state;
    if (state.status == Status.error) _snack('Grade error: ${state.errorMessage ?? 'Unknown error'}');
    else if (state.status == Status.success) _snack('Graded! Score: ${state.result?.score ?? '-'}');
  }

  Future<void> _sendRouted(BuildContext context) async {
    final message = _controller.text.trim();
    if (message.isEmpty) { _snack('Type a message first.'); return; }

    final chat = context.read<ChatNotifier>();
    final exemplar = context.read<ExemplarNotifier>();
    final grade = context.read<GradeNotifier>();

    await chat.routeMessage(
      message: message,
      meta: {'subject': 'English', 'year': 2024, 'section': 'Poetry'},
      history: const [],
    );

    final route = chat.state.route;
    if (route == null) {
      final err = context.read<ChatNotifier>().state.errorMessage ?? 'Routing failed.';
      _snack('Router error: $err');
      return;
    }

    switch (route.type) {
      case 'exemplar':
        await exemplar.generate(
          question: message,
          meta: {'subject': 'English', 'level': 'HL', 'marks': 30},
        );
        if (exemplar.state.status == Status.error) {
          _snack(exemplar.state.errorMessage ?? 'Exemplar error');
        }
        break;
      case 'grade':
        await grade.submit(answer: message, meta: {'subject': 'English'});
        if (grade.state.status == Status.error) {
          _snack(grade.state.errorMessage ?? 'Grade error');
        }
        break;
      default:
        _snack('Coming soon: ${route.type}. Showing grade for now.');
        await grade.submit(answer: message, meta: {'subject': 'English'});
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final GradeState gradeState = context.watch<GradeNotifier>().state;
    final ChatState chatState = context.watch<ChatNotifier>().state;
    final ExemplarState exemplarState = context.watch<ExemplarNotifier>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Bot'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(tooltip: 'Print ID Token', icon: const Icon(Icons.vpn_key), onPressed: _printFirebaseIdToken),
          IconButton(tooltip: 'Test Grade (calls /grade)', icon: const Icon(Icons.play_arrow), onPressed: () => _testGrade(context)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(child: Icon(Icons.smart_toy)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                        child: const TypewriterText(text: "Hello! I'm your Study Bot. How can I help?", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (chatState.route != null) _RouterBanner(),
                const SizedBox(height: 12),
                Row(children: const [CircleAvatar(child: Icon(Icons.smart_toy)), SizedBox(width: 8), TypingDots()]),
                const SizedBox(height: 24),
                if (exemplarState.text?.isNotEmpty == true) _ExemplarResultSection(state: exemplarState),
                _GradeResultSection(state: gradeState),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller, minLines: 1, maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: "Ask StudyBot… (router will decide exemplar/grade)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(tooltip: 'Send (routes → exemplar/grade)', icon: const Icon(Icons.send, color: Colors.blueAccent), onPressed: () => _sendRouted(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouterBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final route = context.watch<ChatNotifier>().state.route!;
    return Card(
      elevation: 0, color: Colors.amber.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Chip(label: Text('Routed: ${route.type}'), backgroundColor: Colors.amber.withOpacity(0.3)),
            const SizedBox(width: 12),
            if (route.confidence != null)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: route.confidence!.clamp(0, 1), minHeight: 8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExemplarResultSection extends StatelessWidget {
  final ExemplarState state;
  const _ExemplarResultSection({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.status == Status.loading) {
      return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 16), child: CircularProgressIndicator()));
    }
    if (state.status == Status.error) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(state.errorMessage ?? 'Error', style: const TextStyle(color: Colors.red)));
    }
    if ((state.text ?? '').isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0, color: Colors.green.withOpacity(0.06),
      child: Padding(padding: const EdgeInsets.all(12), child: TypewriterText(text: state.text!, style: const TextStyle(fontSize: 16))),
    );
  }
}

class _GradeResultSection extends StatelessWidget {
  final GradeState state;
  const _GradeResultSection({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.status == Status.loading) {
      return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 16), child: CircularProgressIndicator()));
    }
    if (state.status == Status.error) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(state.errorMessage ?? 'Error', style: const TextStyle(color: Colors.red)));
    }
    if (state.result == null) return const SizedBox.shrink();

    final res = state.result!;
    return Card(
      elevation: 0, color: Colors.blueGrey.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Score: ${res.score}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Feedback:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          ...res.bullets.map((b) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('• '), Expanded(child: Text(b))])),
        ]),
      ),
    );
  }
}
