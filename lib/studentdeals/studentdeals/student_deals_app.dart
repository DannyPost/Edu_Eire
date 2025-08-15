import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'student_deals_page.dart';
import '../admin/admin_dashboard_page.dart';

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

        // Build the page and inject the current user's email
        '/admin': (context) {
          final email = FirebaseAuth.instance.currentUser?.email ?? '';
          return AdminDashboardPage(adminEmail: email);
        },

        // If your code elsewhere does:
        // Navigator.pushNamed(context, '/admin', arguments: 'someone@ex.com');
        // …then replace the '/admin' route above with this:
        //
        // '/admin': (context) {
        //   final email = (ModalRoute.of(context)?.settings.arguments as String?) ?? '';
        //   return AdminDashboardPage(adminEmail: email);
        // },
      },
    );
  }
}
