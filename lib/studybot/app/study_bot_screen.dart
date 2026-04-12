// lib/studybot/app/study_bot_screen.dart
// Study Bot — LC-style Subject / Paper / Section + exemplar/grade wiring
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../config/constants.dart';
import '../config/env.dart';
import 'study_bot_english_catalog.dart';

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

class _TypingDotsState extends State<TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

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
            style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.primary),
          );
        },
      );
}

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
  String _displayed = '';
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
  Widget build(BuildContext context) => Text(_displayed, style: widget.style);
}

class StudyBotScreen extends StatefulWidget {
  final Map<String, dynamic>? apiHealth;
  final bool apiHealthChecked;
  final Future<void> Function()? onRefreshApiHealth;

  const StudyBotScreen({
    super.key,
    this.apiHealth,
    this.apiHealthChecked = false,
    this.onRefreshApiHealth,
  });

  @override
  State<StudyBotScreen> createState() => _StudyBotScreenState();
}

class _StudyBotScreenState extends State<StudyBotScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _stimulusController = TextEditingController();
  final TextEditingController _taskPromptController = TextEditingController();

  String _subjectId = StudyBotEnglishCatalog.subjectIdEnglish;
  String _paperKey = StudyBotEnglishCatalog.defaultPaperKey();
  late String _sectionId = StudyBotEnglishCatalog.defaultSectionIdForPaper(_paperKey);
  String _level = 'HL';
  var _healthRefreshing = false;

  Map<String, dynamic> _studyMeta() {
    if (_subjectId == StudyBotEnglishCatalog.subjectIdOther) {
      return {
        'subject': 'Other',
        'year': 2024,
        'section': Constants.metaSectionGeneralEnglish,
        'paper': 'General',
        'level': _level,
      };
    }
    final paper = StudyBotEnglishCatalog.paperByKey(_paperKey)!;
    final section = paper.sectionById(_sectionId) ?? paper.sections.first;
    return {
      'subject': 'English',
      'year': 2024,
      'paper': paper.apiPaper,
      'section': section.apiSection,
      'level': _level,
    };
  }

  String? _trimOrNull(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  void _onPaperChanged(String? key) {
    if (key == null) return;
    setState(() {
      _paperKey = key;
      _sectionId = StudyBotEnglishCatalog.defaultSectionIdForPaper(key);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _stimulusController.dispose();
    _taskPromptController.dispose();
    super.dispose();
  }

  Future<void> _printFirebaseIdToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _snack('No user signed in.');
        return;
      }
      String? token = await user.getIdToken(true);
      if (token == null || token.isEmpty) {
        _snack('Could not fetch ID token.');
        return;
      }
      token = token.replaceAll('\r', '').replaceAll('\n', '');
      // ignore: avoid_print
      print('FIREBASE_ID_TOKEN:$token');
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
      meta: _studyMeta(),
      stimulus: _trimOrNull(_stimulusController.text),
      taskPrompt: _trimOrNull(_taskPromptController.text),
    );
    if (!mounted) return;
    final state = grade.state;
    if (state.status == Status.error) {
      _snack('Grade error: ${state.errorMessage ?? 'Unknown error'}');
    } else if (state.status == Status.success) {
      _snack('Graded! Score: ${state.result?.score ?? '-'}');
    }
  }

  Future<void> _sendRouted(BuildContext context) async {
    final message = _controller.text.trim();
    if (message.isEmpty) {
      _snack('Type a message first.');
      return;
    }

    final chat = context.read<ChatNotifier>();
    final exemplar = context.read<ExemplarNotifier>();
    final grade = context.read<GradeNotifier>();

    await chat.routeMessage(
      message: message,
      meta: _studyMeta(),
      history: const [],
    );

    if (!mounted) return;

    final route = chat.state.route;
    if (route == null) {
      final err = chat.state.errorMessage ?? 'Routing failed.';
      _snack('Router error: $err');
      return;
    }

    switch (route.type) {
      case 'exemplar':
        await exemplar.generate(
          question: message,
          meta: {..._studyMeta(), 'marks': 30},
          stimulus: _trimOrNull(_stimulusController.text),
          taskPrompt: _trimOrNull(_taskPromptController.text),
        );
        if (!mounted) return;
        if (exemplar.state.status == Status.error) {
          _snack(exemplar.state.errorMessage ?? 'Exemplar error');
        }
        break;
      case 'grade':
        await grade.submit(
          answer: message,
          meta: _studyMeta(),
          stimulus: _trimOrNull(_stimulusController.text),
          taskPrompt: _trimOrNull(_taskPromptController.text),
        );
        if (!mounted) return;
        if (grade.state.status == Status.error) {
          _snack(grade.state.errorMessage ?? 'Grade error');
        }
        break;
      default:
        _snack('Coming soon: ${route.type}. Showing grade for now.');
        await grade.submit(
          answer: message,
          meta: _studyMeta(),
          stimulus: _trimOrNull(_stimulusController.text),
          taskPrompt: _trimOrNull(_taskPromptController.text),
        );
    }
  }

  Future<void> _retryHealth() async {
    if (widget.onRefreshApiHealth == null) return;
    setState(() => _healthRefreshing = true);
    try {
      await widget.onRefreshApiHealth!();
    } finally {
      if (mounted) setState(() => _healthRefreshing = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget? _buildHealthBanner(BuildContext context) {
    if (!widget.apiHealthChecked) return null;

    final h = widget.apiHealth;
    final scheme = Theme.of(context).colorScheme;

    final explicitFailure = h != null && h['ok'] == false;
    if (explicitFailure) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, color: scheme.onErrorContainer, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Studybot API reported unhealthy. Check your deployment and API_BASE_URL.\n'
                    'Current: ${Env.apiBaseUrl}',
                    style: TextStyle(color: scheme.onErrorContainer, fontSize: 13),
                  ),
                ),
                if (widget.onRefreshApiHealth != null)
                  TextButton(
                    onPressed: _healthRefreshing ? null : _retryHealth,
                    child: Text(_healthRefreshing ? '…' : 'Retry'),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    if (h == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.cloud_off_outlined, color: scheme.onSurfaceVariant, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Could not verify the API (network, or browser CORS on web). '
                    'You can still try sending. URL: ${Env.apiBaseUrl}',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                  ),
                ),
                if (widget.onRefreshApiHealth != null)
                  TextButton(
                    onPressed: _healthRefreshing ? null : _retryHealth,
                    child: Text(_healthRefreshing ? '…' : 'Retry'),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    if (h['ok'] == true) return null;

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final GradeState gradeState = context.watch<GradeNotifier>().state;
    final ChatState chatState = context.watch<ChatNotifier>().state;
    final ExemplarState exemplarState = context.watch<ExemplarNotifier>().state;

    final loading = chatState.status == Status.loading ||
        gradeState.status == Status.loading ||
        exemplarState.status == Status.loading;

    final paper = StudyBotEnglishCatalog.paperByKey(_paperKey);
    final sections = paper?.sections ?? const <StudyBotEnglishSection>[];
    final healthBanner = _buildHealthBanner(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Bot'),
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
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
                if (healthBanner != null) healthBanner,
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Subject',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                value: _subjectId,
                                items: const [
                                  DropdownMenuItem(
                                    value: StudyBotEnglishCatalog.subjectIdEnglish,
                                    child: Text('English (LC)'),
                                  ),
                                  DropdownMenuItem(
                                    value: StudyBotEnglishCatalog.subjectIdOther,
                                    child: Text('Other (general)'),
                                  ),
                                ],
                                onChanged: (v) => setState(() {
                                  _subjectId = v ?? StudyBotEnglishCatalog.subjectIdEnglish;
                                  if (_subjectId == StudyBotEnglishCatalog.subjectIdEnglish) {
                                    _paperKey = StudyBotEnglishCatalog.defaultPaperKey();
                                    _sectionId =
                                        StudyBotEnglishCatalog.defaultSectionIdForPaper(_paperKey);
                                  }
                                }),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 88,
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Level',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                value: _level,
                                items: const [
                                  DropdownMenuItem(value: 'HL', child: Text('HL')),
                                  DropdownMenuItem(value: 'OL', child: Text('OL')),
                                ],
                                onChanged: (v) => setState(() => _level = v ?? 'HL'),
                              ),
                            ),
                          ],
                        ),
                        if (_subjectId == StudyBotEnglishCatalog.subjectIdEnglish) ...[
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Paper',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            isExpanded: true,
                            value: _paperKey,
                            items: [
                              for (final p in StudyBotEnglishCatalog.papers)
                                DropdownMenuItem(value: p.key, child: Text(p.label)),
                            ],
                            onChanged: _onPaperChanged,
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Section / topic',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            isExpanded: true,
                            value: sections.any((s) => s.id == _sectionId)
                                ? _sectionId
                                : (sections.isEmpty ? null : sections.first.id),
                            items: [
                              for (final s in sections)
                                DropdownMenuItem(value: s.id, child: Text(s.label)),
                            ],
                            onChanged: (v) => setState(() => _sectionId = v ?? sections.first.id),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'We use your choices as context; your message can still narrow or correct the task.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(Icons.smart_toy, color: scheme.onPrimaryContainer),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
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
                if (chatState.route != null) _RouterBanner(),
                if (loading) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: scheme.primaryContainer,
                        child: Icon(Icons.smart_toy, color: scheme.onPrimaryContainer, size: 20),
                      ),
                      const SizedBox(width: 8),
                      const TypingDots(),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                if (exemplarState.text?.isNotEmpty == true)
                  _ExemplarResultSection(state: exemplarState),
                _GradeResultSection(state: gradeState),
              ],
            ),
          ),
          const Divider(height: 1),
          Material(
            color: scheme.surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ExpansionTile(
                    title: const Text('Passage and exam questions (optional)'),
                    subtitle: const Text('Stimulus, Text A/B, or question parts'),
                    initiallyExpanded: false,
                    children: [
                      TextField(
                        controller: _stimulusController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Passage / poem / stimulus',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _taskPromptController,
                        minLines: 1,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Exam questions (i, ii, …)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            hintText: 'Your question or answer (router → exemplar / grade)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Send',
                        onPressed: () => _sendRouted(context),
                        icon: const Icon(Icons.send),
                      ),
                    ],
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

class _RouterBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final route = context.watch<ChatNotifier>().state.route!;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.tertiaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Chip(
              label: Text('Routed: ${route.type}'),
              backgroundColor: scheme.tertiaryContainer.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 12),
            if (route.confidence != null)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: route.confidence!.clamp(0, 1),
                    minHeight: 8,
                  ),
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
    final scheme = Theme.of(context).colorScheme;
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
          style: TextStyle(color: scheme.error),
        ),
      );
    }
    if ((state.text ?? '').isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      color: scheme.primaryContainer.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: TypewriterText(text: state.text!, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

class _GradeResultSection extends StatelessWidget {
  final GradeState state;
  const _GradeResultSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
          style: TextStyle(color: scheme.error),
        ),
      );
    }
    if (state.result == null) return const SizedBox.shrink();

    final res = state.result!;
    return Card(
      elevation: 0,
      color: scheme.secondaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score: ${res.score}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Feedback:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ...res.bullets.map(
              (b) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(b)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
