import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth

import 'package:edu_eire_app/auth/student_signup_page.dart';
import 'package:edu_eire_app/auth/business_signup_page.dart'; // Assuming this exists

// You might need to import the colors from login_page.dart or define a common constants file
const Color primaryColor = Color.fromARGB(255, 0, 24, 238);

class ChooseSignupTypePage extends StatelessWidget {
  const ChooseSignupTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current authenticated user here.
    // This will be non-null if they just logged in via Google.
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Choose Account Type"),
        backgroundColor: primaryColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentSignupPage(user: user), // Pass the user here
                  ),
                );
              },
              child: const Text("I am a Student"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BusinessSignupPage(user: user), // Pass the user here
                  ),
                );
              },
              child: const Text("I am a Business"),
            ),
          ],
        ),
      ),
    );
  }
}