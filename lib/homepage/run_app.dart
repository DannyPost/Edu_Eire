import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'widgets/education_news_feed.dart';

Future<void> runEducationApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(const EducationNewsFeed());
}
