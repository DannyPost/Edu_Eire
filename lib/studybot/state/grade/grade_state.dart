import '../../domain/entities/grade_result.dart';
import '../common/status.dart';

class GradeState {
  final Status status;
  final GradeResult? result;
  final String? errorMessage;

  const GradeState({
    this.status = Status.idle,
    this.result,
    this.errorMessage,
  });

  GradeState copyWith({
    Status? status,
    GradeResult? result,
    String? errorMessage,
  }) {
    return GradeState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage,
    );
  }
}
