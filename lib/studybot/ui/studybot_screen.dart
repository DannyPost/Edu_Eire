import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/studybot_service.dart';
import '../models/chat_types.dart';

class StudyBotScreen extends StatefulWidget {
  const StudyBotScreen({super.key});

  @override
  State<StudyBotScreen> createState() => _StudyBotScreenState();
}

class _StudyBotScreenState extends State<StudyBotScreen> {
  final _prompt = TextEditingController();
  final _subject = TextEditingController(text: "English");
  final _level = TextEditingController(text: "HL");

  bool _busy = false;
  _Result? _result;

  late final StudyBotService _sb;

  @override
  void initState() {
    super.initState();
    _sb = StudyBotService(ApiClient());
  }

  @override
  void dispose() {
    _prompt.dispose();
    _subject.dispose();
    _level.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _prompt.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _busy = true;
      _result = null;
    });

    try {
      final res = await _sb.routeAndExecute(
        message: text,
        meta: {
          "subject": _subject.text.trim(),
          "level": _level.text.trim(),
        },
      );

      setState(() => _result = _Result.from(res));
    } catch (e) {
      setState(() => _result = _Result.error(e.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("StudyBot")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Subject + Level row ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subject,
                    decoration: const InputDecoration(
                      labelText: "Subject",
                      hintText: "e.g. English",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _level,
                    decoration: const InputDecoration(
                      labelText: "Level",
                      hintText: "HL / OL",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Main prompt ──────────────────────────────────────────────
            Expanded(
              child: TextField(
                controller: _prompt,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText:
                      "Type anything — ask a question, paste your essay for grading, request a practice paper…",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(14),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Send button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _send,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_busy ? "Thinking…" : "Send"),
              ),
            ),

            // ── Result card ──────────────────────────────────────────────
            if (_result != null) ...[
              const SizedBox(height: 16),
              _ResultCard(result: _result!),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Result model ─────────────────────────────────────────────────────────────

class _Result {
  final String label;
  final String body;
  final bool isError;

  const _Result({required this.label, required this.body, this.isError = false});

  factory _Result.from(({ChatTask task, dynamic payload}) res) {
    switch (res.task) {
      case ChatTask.grade:
        final r = res.payload as GradeResponse;
        final buf = StringBuffer("Score: ${r.score}");
        if (r.rubricId != null) buf.write("\nRubric: ${r.rubricId}");
        if (r.comment != null && r.comment!.isNotEmpty) {
          buf.write("\n\n${r.comment}");
        }
        if (r.bullets.isNotEmpty) {
          buf.write("\n\nFeedback:\n");
          buf.write(r.bullets.map((b) => "• $b").join("\n"));
        }
        return _Result(label: "Grade", body: buf.toString());

      case ChatTask.exemplar:
        final r = res.payload as ExemplarResponse;
        return _Result(label: "Model Answer", body: r.text);

      case ChatTask.paper:
        final r = res.payload as PaperResponse;
        return _Result(label: "Practice Paper", body: r.text);

      case ChatTask.prediction:
        final rp = res.payload as AdviceResponse;
        return _Result(label: "Prediction", body: rp.text);

      case ChatTask.advice:
      case ChatTask.fallback:
        final r = res.payload as AdviceResponse;
        return _Result(label: "Study Advice", body: r.text);
    }
  }

  factory _Result.error(String msg) =>
      _Result(label: "Error", body: msg, isError: true);
}

// ── Result card widget ────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final _Result result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labelColor = result.isError ? cs.error : cs.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: result.isError ? cs.errorContainer : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: result.isError ? cs.error : cs.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: labelColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            result.body,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
