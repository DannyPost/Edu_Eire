import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'studentdeals/student_deals_page.dart';
import 'admin/login_page.dart';
import 'admin/admin_dashboard.dart';
import 'firebase_options.dart'; // Your generated Firebase config

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const StudentDealsApp());
}

class StudentDealsApp extends StatelessWidget {
  const StudentDealsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Deals',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF4595e6),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Montserrat',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/student-deals': (context) => const StudentDealsPage(),
        '/admin-login': (context) => const LoginPage(),
      },
    );
  }
}

/// AuthGate checks the authentication and Firestore approval state
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final user = authSnap.data;
        if (user == null) {
          // Not logged in - show login or landing page
          return const LoginPage();
        }
        // Check Firestore for admin approval
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('admins')
              .doc(user.email)
              .get(),
          builder: (context, adminSnap) {
            if (adminSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            if (!adminSnap.hasData || !adminSnap.data!.exists) {
              // Not an admin, or not registered yet
              return NotApprovedPage(message: "Your business registration was not found. Please sign up or contact support.");
            }
            final adminData = adminSnap.data!.data() as Map<String, dynamic>;
            if (adminData['approved'] == true) {
              // Approved admin - proceed to dashboard
              return AdminDashboard(adminEmail: user.email!);
            } else {
              // Registered, but not approved
              return NotApprovedPage(message: "Your business registration is pending approval. We'll notify you via email.");
            }
          },
        );
      },
    );
  }
}

/// Simple "Not Approved" or "Pending" page
class NotApprovedPage extends StatelessWidget {
  final String message;
  const NotApprovedPage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFe7f2fb),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4595e6),
        title: const Text("Admin Access"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(36.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_clock, size: 80, color: Colors.blueGrey[400]),
              const SizedBox(height: 24),
              Text(
                message,
                style: TextStyle(fontSize: 20, color: Colors.blueGrey[900], fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blueGrey[900]),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushReplacementNamed('/admin-login');
                },
                child: const Text("Back to Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
