import '../common/status.dart';

class ExemplarState {
  final Status status;
  final String? text;         // full exemplar text (streamed/aggregated in data layer)
  final String? errorMessage;

  const ExemplarState({
    this.status = Status.idle,
    this.text,
    this.errorMessage,
  });

  ExemplarState copyWith({
    Status? status,
    String? text,
    String? errorMessage,
  }) {
    return ExemplarState(
      status: status ?? this.status,
      text: text ?? this.text,
      errorMessage: errorMessage,
    );
  }
}
