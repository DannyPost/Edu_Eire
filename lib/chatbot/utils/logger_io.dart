import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';

class ChatLogger {
  static const int _maxLines = 3100;
  static const int _pruneLines = 100;

  static Future<void> logMessage(String role, String message) async {
    final timestamp = DateTime.now().toIso8601String();
    final newEntry = '[$timestamp] $role: $message';

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

  static Future<String> getLog() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = io.File('${dir.path}/chat_log.txt');
      return await file.readAsString();
    } catch (e) {
      return 'Failed to read log: $e';
    }
  }

  static Future<void> clearLog() async {
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

  static String _pruneIfNeeded(String content) {
    final lines = content.trim().split('\n');
    if (lines.length > _maxLines) {
      final pruned = lines.sublist(_pruneLines);
      return pruned.join('\n');
    }
    return content;
  }
}
