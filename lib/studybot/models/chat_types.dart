enum ChatTask { advice, exemplar, paper, grade, prediction, fallback }

ChatTask taskFromString(String? s) {
  switch (s) {
    case 'advice':
      return ChatTask.advice;
    case 'exemplar':
      return ChatTask.exemplar;
    case 'paper':
      return ChatTask.paper;
    case 'grade':
      return ChatTask.grade;
    case 'prediction':
      return ChatTask.prediction;
    default:
      return ChatTask.fallback;
  }
}

class AdviceResponse {
  final String text;
  AdviceResponse({required this.text});
}

class ExemplarResponse {
  final String text;
  final String? model;
  final int? tokens;
  ExemplarResponse({required this.text, this.model, this.tokens});
}

class PaperResponse {
  final String text;
  PaperResponse({required this.text});
}

class GradeResponse {
  final int score;
  final String? rubricId;
  final List<String> bullets;
  final String? comment;

  GradeResponse({
    required this.score,
    this.rubricId,
    this.bullets = const [],
    this.comment,
  });
}