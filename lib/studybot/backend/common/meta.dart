import 'types.dart';

/// Shared metadata that many requests can reuse instead of raw maps.
/// Example usage in a request:
///   final meta = StudyMeta(subject: 'English', year: 2024, level: Level.HL);
///   body: { 'answer': answer, 'meta': meta.toJson() }
class StudyMeta {
  /// e.g., "English", "Maths"
  final String subject;

  /// e.g., 2024
  final int? year;

  /// e.g., Level.HL or Level.OL (optional)
  final Level? level;

  /// e.g., "Paper 1", "Paper 2" (free text to keep it flexible)
  final String? paper;

  /// e.g., "Poetry", "Prose" (section within the paper)
  final String? section;

  /// e.g., "poetry_q1" (specific question reference)
  final String? questionId;

  /// Any extra metadata you want to carry along without changing the model.
  final Json? extra;

  const StudyMeta({
    required this.subject,
    this.year,
    this.level,
    this.paper,
    this.section,
    this.questionId,
    this.extra,
  });

  StudyMeta copyWith({
    String? subject,
    int? year,
    Level? level,
    String? paper,
    String? section,
    String? questionId,
    Json? extra,
  }) {
    return StudyMeta(
      subject: subject ?? this.subject,
      year: year ?? this.year,
      level: level ?? this.level,
      paper: paper ?? this.paper,
      section: section ?? this.section,
      questionId: questionId ?? this.questionId,
      extra: extra ?? this.extra,
    );
  }

  Json toJson() => {
        'subject': subject,
        if (year != null) 'year': year,
        if (level != null) 'level': level!.value,
        if (paper != null) 'paper': paper,
        if (section != null) 'section': section,
        if (questionId != null) 'questionId': questionId,
        if (extra != null) 'extra': extra,
      };

  factory StudyMeta.fromJson(Json json) => StudyMeta(
        subject: json['subject'] as String,
        year: json['year'] is int ? json['year'] as int : (json['year'] == null ? null : int.tryParse(json['year'].toString())),
        level: json['level'] == null ? null : LevelString.from(json['level'].toString()),
        paper: json['paper'] as String?,
        section: json['section'] as String?,
        questionId: json['questionId'] as String?,
        extra: (json['extra'] as Map?)?.cast<String, dynamic>(),
      );
}
