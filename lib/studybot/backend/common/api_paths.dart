/// Centralised API route strings used by the app.
/// Keeping paths in one place avoids string drift across the codebase.
class ApiPaths {
  // Router
  static const String chat = '/chat';

  // Chains
  static const String grade = '/grade';
  static const String exemplar = '/exemplar';
  static const String advice = '/advice';
  static const String prediction = '/prediction';
  static const String paper = '/paper';

  // Files
  static const String filePresign = '/files/presign';
  static const String fileCommit = '/files/commit';

  // Health (optional)
  static const String health = '/health';
}
