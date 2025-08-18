class PaperQuestion {
  final String text;
  final int marks;

  const PaperQuestion({required this.text, required this.marks});

  factory PaperQuestion.fromJson(Map<String, dynamic> json) => PaperQuestion(
        text: json['text'] as String,
        marks: json['marks'] as int,
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        'marks': marks,
      };
}

class PaperSection {
  final String title;
  final List<PaperQuestion> questions;

  const PaperSection({required this.title, required this.questions});

  factory PaperSection.fromJson(Map<String, dynamic> json) => PaperSection(
        title: json['title'] as String,
        questions: (json['questions'] as List)
            .map((e) =>
                PaperQuestion.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'questions': questions.map((q) => q.toJson()).toList(),
      };
}

class MarkschemeItem {
  final int questionIndex;
  final List<String> criteria;

  const MarkschemeItem({required this.questionIndex, required this.criteria});

  factory MarkschemeItem.fromJson(Map<String, dynamic> json) => MarkschemeItem(
        questionIndex: json['questionIndex'] as int,
        criteria: (json['criteria'] as List).map((e) => e.toString()).toList(),
      );

  Map<String, dynamic> toJson() => {
        'questionIndex': questionIndex,
        'criteria': criteria,
      };
}

class PaperResponse {
  final List<PaperSection> sections;
  final List<MarkschemeItem> markscheme;
  final String? downloadUrl;

  const PaperResponse({
    required this.sections,
    required this.markscheme,
    this.downloadUrl,
  });

  factory PaperResponse.fromJson(Map<String, dynamic> json) => PaperResponse(
        sections: (json['sections'] as List)
            .map((e) =>
                PaperSection.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        markscheme: (json['markscheme'] as List)
            .map((e) =>
                MarkschemeItem.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        downloadUrl:
            json['downloadUrl'] == null ? null : json['downloadUrl'] as String,
      );
}
