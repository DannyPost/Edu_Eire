// lib/studybot/data/repositories/paper_repository_impl.dart
import '../../backend/common/api_paths.dart';
import '../../backend/paper/paper_models.dart';
import '../../services/api_client.dart';

class PaperRepository {
  PaperRepository(this._client);
  final ApiClient _client;

  /// Example meta: {"subject":"English","section":["A","B"],"level":"HL"}
  Future<PaperResponse> generatePaper({required Map<String, dynamic> meta}) async {
    final req = PaperRequest(meta: meta);
    final json = await _client.postJson(ApiPaths.paper, body: req.toJson());
    return PaperResponse.fromJson(json);
  }
}
