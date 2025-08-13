class PredictionRequest {
  final String subject;
  final String paper; // e.g., "Paper 1", "HL"
  final int year;

  const PredictionRequest({
    required this.subject,
    required this.paper,
    required this.year,
  });

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'paper': paper,
        'year': year,
      };
}
