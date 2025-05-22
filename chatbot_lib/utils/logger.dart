import 'package:flutter/foundation.dart' show kIsWeb;

// Web support
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

// Mobile/Desktop
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';

class ChatLogger {
  static const String _webLogKey = 'edu_chat_log';
  static const int _maxLines = 3100;
  static const int _pruneLines = 100;

  static Future<void> logMessage(String role, String message) async {
    final timestamp = DateTime.now().toIso8601String();
    final newEntry = '[$timestamp] $role: $message';

    if (kIsWeb) {
      final existing = html.window.localStorage[_webLogKey] ?? '';
      final updated = _pruneIfNeeded(existing + '\n' + newEntry);
      html.window.localStorage[_webLogKey] = updated;
    } else {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = io.File('${dir.path}/chat_log.txt');

        if (!await file.exists()) {
          await file.create(recursive: true);
        }

        String current = await file.readAsString();
        final updated = _pruneIfNeeded(current + '\n' + newEntry);
        await file.writeAsString(updated);
      } catch (e) {
        print('Log error: $e');
      }
    }
  }

  static Future<String> getLog() async {
    if (kIsWeb) {
      return html.window.localStorage[_webLogKey] ?? 'No log found.';
    } else {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = io.File('${dir.path}/chat_log.txt');
        return await file.readAsString();
      } catch (e) {
        return 'Failed to read log: $e';
      }
    }
  }

  static Future<void> clearLog() async {
    if (kIsWeb) {
      html.window.localStorage.remove(_webLogKey);
    } else {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = io.File('${dir.path}/chat_log.txt');
        if (await file.exists()) {
          await file.writeAsString('');
        }
      } catch (e) {
        print('Failed to clear log: $e');
      }
    }
  }

  /// Keep only the last (_maxLines - _pruneLines) lines when over threshold
  static String _pruneIfNeeded(String content) {
    final lines = content.trim().split('\n');
    if (lines.length > _maxLines) {
      final pruned = lines.sublist(_pruneLines); // Drop oldest 100
      return pruned.join('\n');
    }
    return content;
  }
}
