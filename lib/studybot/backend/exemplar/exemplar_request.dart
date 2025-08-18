class ExemplarRequest {
  final String question;
  final Map<String, dynamic>? meta;

  const ExemplarRequest({required this.question, this.meta});

  Map<String, dynamic> toJson() => {
        'question': question,
        if (meta != null) 'meta': meta,
      };
}
