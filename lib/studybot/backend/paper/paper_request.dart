class PaperRequest {
  final String subject;
  final String level; // e.g., "HL", "OL"
  final List<String> sections; // e.g., ["Poetry", "Prose"]
  final String difficulty; // e.g., "easy" | "medium" | "hard"

  const PaperRequest({
    required this.subject,
    required this.level,
    required this.sections,
    required this.difficulty,
  });

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'level': level,
        'sections': sections,
        'difficulty': difficulty,
      };
}