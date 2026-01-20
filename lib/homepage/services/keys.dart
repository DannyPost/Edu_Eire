import 'package:flutter/services.dart';

class AppKeys {
  static String openAiKey = '';
  static String newsApiKey = '';
  static bool _loaded = false;

  static Future<void> init() async {
    if (_loaded) return;

    // These files must be listed under flutter/assets in pubspec.yaml
    openAiKey = (await rootBundle.loadString('chatbot_api.env')).trim();
    newsApiKey = (await rootBundle.loadString('news_api.env')).trim();

    _loaded = true;
  }

  static void ensureLoaded() {
    if (!_loaded || openAiKey.isEmpty || newsApiKey.isEmpty) {
      throw StateError(
        'API keys not loaded. Call await AppKeys.init() before using services.',
      );
    }
  }
}