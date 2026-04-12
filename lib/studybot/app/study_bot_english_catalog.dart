import '../config/constants.dart';

/// Leaving Certificate English — paper and section options for Study Bot `meta`.
class StudyBotEnglishSection {
  final String id;
  final String label;
  /// Value for `meta.section` (must match API / S3 routing).
  final String apiSection;

  const StudyBotEnglishSection({
    required this.id,
    required this.label,
    required this.apiSection,
  });
}

class StudyBotEnglishPaper {
  final String key;
  final String label;
  /// Value for `meta.paper`
  final String apiPaper;
  final List<StudyBotEnglishSection> sections;

  const StudyBotEnglishPaper({
    required this.key,
    required this.label,
    required this.apiPaper,
    required this.sections,
  });

  StudyBotEnglishSection? sectionById(String id) {
    for (final s in sections) {
      if (s.id == id) return s;
    }
    return sections.isEmpty ? null : sections.first;
  }
}

/// LC English catalog: Paper 1 / Paper 2 and their sections.
abstract final class StudyBotEnglishCatalog {
  static const String subjectIdEnglish = 'english';
  static const String subjectIdOther = 'other';

  static const List<StudyBotEnglishPaper> papers = [
    StudyBotEnglishPaper(
      key: 'paper1',
      label: 'Paper 1 — Language',
      apiPaper: 'Paper 1',
      sections: [
        StudyBotEnglishSection(
          id: 'p1_rc',
          label: 'Reading comprehension',
          apiSection: Constants.metaSectionReadingComprehension,
        ),
        StudyBotEnglishSection(
          id: 'p1_poetry',
          label: 'Unseen poetry',
          apiSection: Constants.metaSectionUnseenPoetry,
        ),
        StudyBotEnglishSection(
          id: 'p1_composition',
          label: 'Composition',
          apiSection: Constants.metaSectionComposition,
        ),
      ],
    ),
    StudyBotEnglishPaper(
      key: 'paper2',
      label: 'Paper 2 — Literature',
      apiPaper: 'Paper 2',
      sections: [
        StudyBotEnglishSection(
          id: 'p2_comparative',
          label: 'Comparative study',
          apiSection: Constants.metaSectionComparativeStudy,
        ),
        StudyBotEnglishSection(
          id: 'p2_studied_poetry',
          label: 'Studied poetry',
          apiSection: Constants.metaSectionStudiedPoetry,
        ),
        StudyBotEnglishSection(
          id: 'p2_single_text',
          label: 'Single text',
          apiSection: Constants.metaSectionSingleText,
        ),
      ],
    ),
  ];

  static StudyBotEnglishPaper? paperByKey(String key) {
    for (final p in papers) {
      if (p.key == key) return p;
    }
    return papers.isEmpty ? null : papers.first;
  }

  static String defaultPaperKey() => papers.first.key;

  static String defaultSectionIdForPaper(String paperKey) {
    final p = paperByKey(paperKey);
    return p?.sections.first.id ?? 'p1_rc';
  }
}
