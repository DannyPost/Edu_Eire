import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'widgets/education_news_feed.dart';

Future<void> runEducationApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Try to load the default .env first (conventional). If you keep a
  // differently named file (e.g. _newsDataKey.env), we'll try that as a
  // fallback so your local setup keeps working without renaming files.
  try {
    await dotenv.load(); // loads `.env` by default
  } catch (_) {
    // ignore if default .env not present
  }

  // If the key isn't present in the default file, try the project-specific
  // fallback used in this repo (`_newsDataKey.env`). This keeps compatibility
  // with the attached _newsDataKey.env you shared.
  if ((dotenv.env['NEWSDATA_API_KEY'] ?? '').isEmpty) {
    try {
      await dotenv.load(fileName: '_newsDataKey.env');
    } catch (_) {
      // ignore missing fallback file
    }
  }
  runApp(const EducationNewsFeed());
}
