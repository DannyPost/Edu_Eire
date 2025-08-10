/// Build-time environment values (non-secret).
/// Set via --dart-define when you build or run:
/// flutter run --dart-define=API_BASE_URL=https://abc.execute-api.eu-west-1.amazonaws.com/dev
///             --dart-define=ENVIRONMENT=dev
class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://57u97hpdwi.execute-api.eu-west-1.amazonaws.com/dev', // change to your dev gateway when ready
  );

  /// dev | stage | prod
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'dev',
  );
}
