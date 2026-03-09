// lib/studybot/services/studybot_service.dart
import 'api_client.dart';
import '../models/chat_types.dart';

class StudyBotService {
  final ApiClient _client;
  StudyBotService(this._client);

  /// Routes via /chat then calls the mapped worker Lambda.
  /// Returns a discriminated union: (task, payload)
  Future<({ChatTask task, dynamic payload})> routeAndExecute({
    required String message,
    String? question,                    // ⬅ optional explicit question field from UI
    Map<String, dynamic>? meta,
    List<dynamic> history = const [],
  }) async {
    // 1) Ask router to classify + invoke worker (router calls the worker for us)
    final routerResp = await _client.post('/chat', {
      'message': message,
      if (question != null && question.trim().isNotEmpty) 'question': question,
      if (meta != null) 'meta': meta,
      if (history.isNotEmpty) 'history': history,
    });

    // Router returns: { type: 'exemplar'|'grade'|'paper'|'advice'|..., decision:{...}, ...workerPayload }
    final routeStr = (routerResp['type'] ?? routerResp['route'] ?? 'advice').toString();
    final task = taskFromString(routeStr);

    switch (task) {
      case ChatTask.exemplar:
        // Expected keys: text, model?, tokens?
        return (
          task: task,
          payload: ExemplarResponse(
            text: (routerResp['text'] ?? '').toString(),
            model: routerResp['model']?.toString(),
            tokens: (routerResp['tokens'] is num) ? (routerResp['tokens'] as num).toInt() : null,
          ),
        );

      case ChatTask.paper:
        // Expected key: text
        return (
          task: task,
          payload: PaperResponse(
            text: (routerResp['text'] ?? '').toString(),
          ),
        );

      case ChatTask.grade:
        // Expected keys: score, bullets[], comment?, rubricId?
        return (
          task: task,
          payload: GradeResponse(
            score: (routerResp['score'] is num) ? (routerResp['score'] as num).toInt() : 0,
            rubricId: routerResp['rubricId']?.toString(),
            bullets: (routerResp['bullets'] is List)
                ? (routerResp['bullets'] as List).map((e) => e.toString()).toList()
                : const [],
            comment: (routerResp['comment'] ?? routerResp['feedback'])?.toString(),
          ),
        );

      case ChatTask.advice:
      case ChatTask.prediction:
      case ChatTask.fallback:
      default:
        // Advice-shaped fallback: text
        return (
          task: ChatTask.advice,
          payload: AdviceResponse(
            text: (routerResp['text'] ??
                    'I hit an error routing that. Try rephrasing your request.')
                .toString(),
          ),
        );
    }
  }
}