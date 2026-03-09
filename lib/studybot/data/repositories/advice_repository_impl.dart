// lib/studybot/data/repositories/advice_repository_impl.dart
import '../../backend/common/api_paths.dart';
import '../../backend/advice/advice_models.dart';
import '../../services/api_client.dart';

class AdviceRepository {
  AdviceRepository(this._client);
  final ApiClient _client;

  Future<AdviceResponse> getAdvice({required String prompt, Map<String, dynamic>? meta}) async {
    final req = AdviceRequest(prompt: prompt, meta: meta);
    final json = await _client.postJson(ApiPaths.advice, body: req.toJson());
    return AdviceResponse.fromJson(json);
  }
}
