import 'package:flutter/material.dart';
import 'student_deals_page.dart';
import '../admin/admin_dashboard.dart';

class StudentDealsApp extends StatelessWidget {
  const StudentDealsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Deals',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const StudentDealsPage(),
        '/admin': (context) => const AdminDashboard(),
      },
    );
  }
}
