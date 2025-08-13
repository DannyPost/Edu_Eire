import '../entities/grade_result.dart';

/// Abstraction for grading and exemplar operations.
/// The data layer will implement this using /grade and /exemplar endpoints.
abstract class GradeRepository {
  /// Grade a student's answer against a rubric.
  Future<GradeResult> gradeAnswer({
    required String answer,
    required Map<String, dynamic> meta,
  });

  /// Generate a high-quality exemplar/model answer for a question.
  /// Returns the exemplar text (streaming is handled in the data/services layer,
  /// but you can also adapt this to return a stream if you prefer).
  Future<String> getExemplar({
    required String question,
    Map<String, dynamic>? meta,
  });
}
