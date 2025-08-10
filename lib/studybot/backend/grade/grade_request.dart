class GradeRequest {
  final String answer;
  final Map<String, dynamic> meta;

  const GradeRequest({required this.answer, required this.meta});

  Map<String, dynamic> toJson() => {
        'answer': answer,
        'meta': meta,
      };
}
