/// App-wide constants (non-secret). Tune as needed.
class Constants {
  // Networking
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(minutes: 2);
  static const Duration streamFirstByteDeadline = Duration(seconds: 8);

  // Input limits (guardrails mirrored on backend)
  static const int maxAnswerCharacters = 5000; // long essays should be uploaded as files
  static const int maxQuestionCharacters = 800;
  static const int maxFilenameLength = 120;

  // Upload limits
  static const int maxUploadBytes = 10 * 1024 * 1024; // 10 MB
  static const List<String> allowedUploadTypes = <String>[
    'application/pdf',
    'text/plain',
  ];

  // UI
  static const int exemplarStreamAbortAfterMs = 120000; // 2 minutes

  /// When [StudyMeta.section] equals this, the API should load reading-comprehension
  /// knowledge from S3 (`s3GuideKey` + `s3BritishEnglishConventionKey` in the manifest)
  /// and prepend it before the task block.
  static const String metaSectionReadingComprehension = 'Reading comprehension';

  /// API loads unseen-poetry guides from S3 when [StudyMeta.section] matches.
  static const String metaSectionUnseenPoetry = 'Unseen poetry';

  /// Generic English flow (no S3 topic guides; shorter generic prompt on API).
  static const String metaSectionGeneralEnglish = 'General English';

  /// Paper 1 Section II style tasks (functional writing / composition).
  static const String metaSectionComposition = 'Composition';

  /// Paper 2 comparative study.
  static const String metaSectionComparativeStudy = 'Comparative study';

  /// Paper 2 prescribed / studied poetry.
  static const String metaSectionStudiedPoetry = 'Studied poetry';

  /// Paper 2 single text (novel, play, etc.).
  static const String metaSectionSingleText = 'Single text';
}
