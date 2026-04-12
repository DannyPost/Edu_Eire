import '../entities/grade_result.dart';
import '../repositories/grade_repository.dart';

/// Use case: grade a student's answer.
class GradeAnswer {
  final GradeRepository _repo;

  const GradeAnswer(this._repo);

  Future<GradeResult> call({
    required String answer,
    required Map<String, dynamic> meta,
    String? stimulus,
    String? taskPrompt,
  }) {
    return _repo.gradeAnswer(
      answer: answer,
      meta: meta,
      stimulus: stimulus,
      taskPrompt: taskPrompt,
    );
  }
}
