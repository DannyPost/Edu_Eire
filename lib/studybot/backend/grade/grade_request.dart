class GradeRequest {
  final String answer;
  final Map<String, dynamic> meta;

  /// Same as exemplar `stimulus` — passage the student answered against.
  final String? stimulus;

  /// Exam question wording / parts (i, ii, iii).
  final String? taskPrompt;

  const GradeRequest({
    required this.answer,
    required this.meta,
    this.stimulus,
    this.taskPrompt,
  });

  Map<String, dynamic> toJson() => {
        'answer': answer,
        'meta': meta,
        if (stimulus != null && stimulus!.trim().isNotEmpty) 'stimulus': stimulus,
        if (taskPrompt != null && taskPrompt!.trim().isNotEmpty) 'taskPrompt': taskPrompt,
      };
}
