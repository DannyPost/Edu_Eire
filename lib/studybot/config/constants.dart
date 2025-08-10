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
}
