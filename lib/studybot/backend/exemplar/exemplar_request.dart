import '../../config/constants.dart';

class ExemplarRequest {
  final String question;
  final Map<String, dynamic>? meta;

  /// Unseen passage(s) (Text A / B). When [meta.section] is
  /// [Constants.metaSectionReadingComprehension], the API should fetch S3 guides and
  /// combine stimulus + [taskPrompt] + [question] for the model.
  final String? stimulus;

  /// Exam instructions / sub-questions (verbatim from the paper).
  final String? taskPrompt;

  const ExemplarRequest({
    required this.question,
    this.meta,
    this.stimulus,
    this.taskPrompt,
  });

  Map<String, dynamic> toJson() => {
        'question': question,
        if (meta != null) 'meta': meta,
        if (stimulus != null && stimulus!.trim().isNotEmpty) 'stimulus': stimulus,
        if (taskPrompt != null && taskPrompt!.trim().isNotEmpty) 'taskPrompt': taskPrompt,
      };
}
