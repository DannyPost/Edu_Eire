import 'package:flutter/material.dart';
import 'widgets/education_news_feed.dart';

// ❌ No WidgetsFlutterBinding
// ❌ No AppKeys.init()
// ❌ No runApp()

class EducationNewsPage extends StatelessWidget {
  const EducationNewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const EducationNewsFeed();
  }
}