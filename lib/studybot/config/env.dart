// lib/studybot/config/env.dart
class Env {
  Env._();

  /// Base URL of your API Gateway stage (no trailing slash).
  static String baseUrl = '';

  /// Optional logical -> path map (e.g., { 'chat': '/chat' }).
  static Map<String, String> routes = {};

  /// Optional cached Firebase ID token.
  static String? firebaseIdToken;

  /// Async provider for a fresh auth token (e.g., Firebase getIdToken()).
  static Future<String> Function()? _tokenProvider;

  /// New initializer (preferred).
  static void init({
    required String baseUrl,
    Map<String, String>? routes,
    Future<String> Function()? tokenProvider,
  }) {
    Env.baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');
    if (routes != null) Env.routes = routes;
    _tokenProvider = tokenProvider;
  }

  /// ---- Back-compat shims ----

  /// Legacy initializer used by older code.
  /// Equivalent to `init(baseUrl: ..., tokenProvider: authTokenGetter, routes: ...)`.
  static void configure({
    required String baseUrl,
    Future<String> Function()? authTokenGetter,
    Map<String, String>? routes,
  }) {
    init(
      baseUrl: baseUrl,
      routes: routes,
      tokenProvider: authTokenGetter,
    );
  }

  /// Legacy setter used to cache a token after login.
  static void setFirebaseIdToken(String? token) {
    firebaseIdToken = (token ?? '').isEmpty ? null : token;
  }

  /// ---- Runtime helpers ----

  /// Resolve a logical key (e.g., 'chat') to '/chat', or pass through '/path'.
  static String resolvePath(String keyOrPath) {
    if (keyOrPath.startsWith('/')) return keyOrPath;
    final mapped = routes[keyOrPath];
    if (mapped != null) return mapped.startsWith('/') ? mapped : '/$mapped';
    return '/$keyOrPath';
  }

  /// Get an auth token. Uses cache -> provider -> empty string.
  static Future<String> token() async {
    if (firebaseIdToken != null && firebaseIdToken!.isNotEmpty) {
      return firebaseIdToken!;
    }
    if (_tokenProvider != null) {
      final t = await _tokenProvider!();
      return t;
    }
    return '';
  }
}