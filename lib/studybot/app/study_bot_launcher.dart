import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../di.dart';
import '../state/chat/chat_notifier.dart';
import '../state/grade/grade_notifier.dart';
import '../state/exemplar/exemplar_notifier.dart';
import 'study_bot_screen.dart';

/// Hosts [StudyBotDI] and providers; opens [StudyBotScreen]. Dispose closes the HTTP client.
class StudyBotLauncher extends StatefulWidget {
  const StudyBotLauncher({super.key});

  @override
  State<StudyBotLauncher> createState() => _StudyBotLauncherState();
}

class _StudyBotLauncherState extends State<StudyBotLauncher> {
  late final StudyBotDI _di = StudyBotDI.dev();
  Map<String, dynamic>? _health;
  var _healthChecked = false;

  @override
  void initState() {
    super.initState();
    _runHealthCheck();
  }

  Future<void> _runHealthCheck() async {
    final h = await _di.getApiHealth();
    if (!mounted) return;
    setState(() {
      _health = h;
      _healthChecked = true;
    });
  }

  @override
  void dispose() {
    _di.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ChatNotifier>.value(value: _di.chatNotifier),
        ChangeNotifierProvider<GradeNotifier>.value(value: _di.gradeNotifier),
        ChangeNotifierProvider<ExemplarNotifier>.value(value: _di.exemplarNotifier),
      ],
      child: StudyBotScreen(
        apiHealth: _health,
        apiHealthChecked: _healthChecked,
        onRefreshApiHealth: _runHealthCheck,
      ),
    );
  }
}
