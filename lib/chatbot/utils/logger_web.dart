// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ChatLogger {
  static const String _webLogKey = 'edu_chat_log';
  static const int _maxLines = 3100;
  static const int _pruneLines = 100;

  static Future<void> logMessage(String role, String message) async {
    final timestamp = DateTime.now().toIso8601String();
    final newEntry = '[$timestamp] $role: $message';

    final existing = html.window.localStorage[_webLogKey] ?? '';
    final updated = _pruneIfNeeded('$existing\n$newEntry');
    html.window.localStorage[_webLogKey] = updated;
  }

  static Future<String> getLog() async {
    return html.window.localStorage[_webLogKey] ?? 'No log found.';
  }

  static Future<void> clearLog() async {
    html.window.localStorage.remove(_webLogKey);
  }

  static String _pruneIfNeeded(String content) {
    final lines = content.trim().split('\n');
    if (lines.length > _maxLines) {
      final pruned = lines.sublist(_pruneLines);
      return pruned.join('\n');
    }
    return content;
  }
}
