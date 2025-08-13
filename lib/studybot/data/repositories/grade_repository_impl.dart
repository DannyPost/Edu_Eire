import '../../backend/backend.dart';
import '../../services/api_client.dart';
import '../../domain/entities/grade_result.dart';
import '../../domain/repositories/grade_repository.dart';

class GradeRepositoryImpl implements GradeRepository {
  final ApiClient _api;

  GradeRepositoryImpl(this._api);

  @override
  Future<GradeResult> gradeAnswer({
    required String answer,
    required Map<String, dynamic> meta,
  }) async {
    final req = GradeRequest(answer: answer, meta: meta);
    final json = await _api.postJson(ApiPaths.grade, req.toJson());
    final resp = GradeResponse.fromJson(json);
    return GradeResult(score: resp.score, bullets: resp.bullets, meta: resp.meta);
  }

  @override
  Future<String> getExemplar({
    required String question,
    Map<String, dynamic>? meta,
  }) async {
    // Collect the streamed exemplar into a single string for the domain.
    final req = ExemplarRequest(question: question, meta: meta);
    final buffer = StringBuffer();
    final stream = _api.postStream(ApiPaths.exemplar, req.toJson());
    await for (final chunk in stream) {
      buffer.write(chunk);
    }
    return buffer.toString();
  }
}
