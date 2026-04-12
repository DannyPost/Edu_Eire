// lib/studybot/data/repositories/exemplar_repository_impl.dart
import '../../services/api_client.dart';
import '../../backend/common/api_paths.dart';

class ExemplarRepository {
  final ApiClient _api;
  ExemplarRepository(this._api);

  /// Baseline (non-streaming): backend returns { "text": "...", "tokens"?, "model"? }
  Future<String> generate({
    required String question,
    Map<String, dynamic>? meta,
    String? stimulus,
    String? taskPrompt,
  }) async {
    final body = <String, dynamic>{
      'question': question,
      if (meta != null) 'meta': meta,
      if (stimulus != null && stimulus.trim().isNotEmpty) 'stimulus': stimulus,
      if (taskPrompt != null && taskPrompt.trim().isNotEmpty) 'taskPrompt': taskPrompt,
    };
    final json = await _api.postJson(ApiPaths.exemplar, body);
    return (json['text'] as String?) ?? '';
  }
}
