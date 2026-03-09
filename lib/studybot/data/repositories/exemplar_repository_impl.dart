// lib/studybot/data/repositories/exemplar_repository_impl.dart
import '../../backend/common/api_paths.dart';
import '../../backend/exemplar/exemplar_models.dart';
import '../../services/api_client.dart';

class ExemplarRepository {
  ExemplarRepository(this._client);
  final ApiClient _client;

  Future<ExemplarResponse> getExemplar({required String question, Map<String, dynamic>? meta}) async {
    final req = ExemplarRequest(question: question, meta: meta);
    final json = await _client.postJson(ApiPaths.exemplar, body: req.toJson());
    return ExemplarResponse.fromJson(json);
  }
}
