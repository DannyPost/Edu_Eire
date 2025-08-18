// ───────────────────────────────────────────────────────────
// lib/studybot/study_bot_screen.dart
// Minimal Study-Bot chat UI + debug actions (ID token + test grade)
// ───────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

// State
import '../state/grade/grade_notifier.dart';
import '../state/grade/grade_state.dart';
import '../state/common/status.dart';
import 'package:flutter/services.dart'; 
/*───────────────────────────────────────────────────────────
 ⏳  Typing-dots “...”
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

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final dots = (_c.value * 3).floor() % 3 + 1;
          return Text(
            '.' * dots,
            style: TextStyle(fontSize: 20, color: Theme.of(context).primaryColor),
          );
        },
      );
}

/*───────────────────────────────────────────────────────────
 ⌨️  Typewriter reveal for bot replies
───────────────────────────────────────────────────────────*/
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;

  const TypewriterText({
    super.key,
    required this.text,
    required this.style,
    this.duration = const Duration(milliseconds: 30),
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayed = "";
  late int _currentIndex;
  late final List<String> _characters;
  late final Duration _duration;

  @override
  void initState() {
    super.initState();
    _characters = widget.text.split('');
    _currentIndex = 0;
    _duration = widget.duration;
    _tick();
  }

  void _tick() async {
    while (_currentIndex < _characters.length) {
      await Future.delayed(_duration);
      if (!mounted) return;
      setState(() {
        _displayed += _characters[_currentIndex];
        _currentIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayed, style: widget.style);
  }
}

/*───────────────────────────────────────────────────────────
 📄  StudyBot Screen Layout + Debug buttons
───────────────────────────────────────────────────────────*/
class StudyBotScreen extends StatefulWidget {
  const StudyBotScreen({super.key});

  @override
  State<StudyBotScreen> createState() => _StudyBotScreenState();
}

class _StudyBotScreenState extends State<StudyBotScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Clipboard

Future<void> _printFirebaseIdToken() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('No user signed in.');
      return;
    }

    String? token = await user.getIdToken(true); // refresh
    if (token == null || token.isEmpty) {
      _snack('Could not fetch ID token.');
      return;
    }

    // Ensure single-line (defensive; tokens normally have no newlines)
    token = token.replaceAll('\r', '').replaceAll('\n', '');

    // Log full token for debugging
    // ignore: avoid_print
    print('FIREBASE_ID_TOKEN:$token');

    // Copy to clipboard for cURL/Postman
    await Clipboard.setData(ClipboardData(text: token));

    final preview = token.length > 24 ? '${token.substring(0, 24)}…' : token;
    _snack('ID token copied: $preview');
  } catch (e) {
    _snack('Failed to get ID token: $e');
  }
}


  Future<void> _testGrade(BuildContext context) async {
    final text = _controller.text.trim().isEmpty
        ? 'This is my test answer for the StudyBot grading flow.'
        : _controller.text.trim();

    final grade = context.read<GradeNotifier>();
    await grade.submit(
      answer: text,
      meta: {
        'subject': 'English',
        'year': 2024,
        'section': 'Poetry',
        'questionId': 'poetry_q1',
      },
    );
    final state = grade.state;
    if (state.status == Status.error) {
      _snack('Grade error: ${state.errorMessage ?? 'Unknown error'}');
    } else if (state.status == Status.success) {
      _snack('Graded! Score: ${state.result?.score ?? '-'}');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final GradeState gradeState = context.watch<GradeNotifier>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Bot'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            tooltip: 'Print ID Token',
            icon: const Icon(Icons.vpn_key),
            onPressed: _printFirebaseIdToken,
          ),
          IconButton(
            tooltip: 'Test Grade (calls /grade)',
            icon: const Icon(Icons.play_arrow),
            onPressed: () => _testGrade(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Example bot message
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(child: Icon(Icons.smart_toy)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const TypewriterText(
                          text: "Hello! I'm your Study Bot. How can I help?",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Typing animation example
                Row(
                  children: const [
                    CircleAvatar(child: Icon(Icons.smart_toy)),
                    SizedBox(width: 8),
                    TypingDots(),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Debug output area for grading ─────────────────────────
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
                    controller: _controller,
                    minLines: 1,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: "Type your answer here… (debug: used for Test Grade)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Send (placeholder)',
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: () {
                    // Placeholder for future chat/router logic
                    _snack('Send tapped (not wired yet)');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/*───────────────────────────────────────────────────────────
 🎯  Small widget to display Grade state nicely
───────────────────────────────────────────────────────────*/
class _GradeResultSection extends StatelessWidget {
  final GradeState state;
  const _GradeResultSection({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.status == Status.loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (state.status == Status.error) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          state.errorMessage ?? 'Error',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    if (state.result == null) {
      return const SizedBox.shrink();
    }

    final res = state.result!;
    return Card(
      elevation: 0,
      color: Colors.blueGrey.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score: ${res.score}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Feedback:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ...res.bullets.map((b) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(b)),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}
