import '../repositories/grade_repository.dart';

/// Use case: get a model/exemplar answer for a question.
class GetExemplar {
  final GradeRepository _repo;

  const GetExemplar(this._repo);

  Future<String> call({
    required String question,
    Map<String, dynamic>? meta,
  }) {
    return _repo.getExemplar(question: question, meta: meta);
  }
}
