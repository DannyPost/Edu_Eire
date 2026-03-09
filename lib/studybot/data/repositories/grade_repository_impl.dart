// lib/studybot/data/repositories/grade_repository_impl.dart
import '../../backend/common/api_paths.dart';
import '../../backend/grade/grade_models.dart';
import '../../services/api_client.dart';

class GradeRepository {
  GradeRepository(this._client);
  final ApiClient _client;

  Future<GradeResponse> gradeAnswer({
    required String question,
    required String answer,
    Map<String, dynamic>? meta,
  }) async {
    final req = GradeRequest(question: question, answer: answer, meta: meta);
    final json = await _client.postJson(ApiPaths.grade, body: req.toJson());
    return GradeResponse.fromJson(json);
  }
}
