import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Adjust paths as necessary based on your project structure:
import 'package:edu_eire_app/auth/choose_signup_type_page.dart';
import 'package:edu_eire_app/auth/login_page.dart'; // Import LoginPage to access googleSignIn
// Make sure this is imported

// Define a consistent color scheme (or import from common constants)
const Color primaryColor = Color.fromARGB(255, 0, 24, 238);
const Color textColor = Color(0xFF424242);
const Color accentColor = Color(0xFF03DAC6);


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _userRole;
  bool _profileComplete = false;
  bool _isLoadingUserData = true; // State for loading user profile data

  @override
  void initState() {
    super.initState();
    _checkUserProfile();
  }

  Future<void> _checkUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      }
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          _profileComplete = data?['profileCompleted'] ?? false;
          _userRole = data?['role'];
        });

        if (!_profileComplete) {
          // If profile is NOT complete, redirect to choose signup type
          // This ensures they complete their profile even if they close the app prematurely
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ChooseSignupTypePage()),
            );
          }
        }
        // If profileComplete is true, it implicitly stays on HomePage.
      } else {
        // User document not found for a logged-in user (edge case, but handle it)
        // This implies they authenticated but never created their user doc or it was deleted.
        // Send them to choose signup type to rectify.
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ChooseSignupTypePage()),
          );
        }
      }
    } catch (e) {
      print("Error checking user profile from HomePage: $e");
      // As a fallback, if there's an error fetching user data, still try to go to ChooseSignupTypePage
      // or show an error, to prevent the user from being stuck or seeing an incomplete state.
       if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ChooseSignupTypePage()),
        );
      }
    } finally {
      setState(() {
        _isLoadingUserData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUserData) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edu Eire Home"),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              await googleSignIn.signOut(); // Use the imported global instance
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Welcome, ${user?.email ?? 'User'}!'),
            if (_userRole != null) Text('Your Role: ${_userRole!.toUpperCase()}'),
            if (_userRole == 'student')
              const Text('This is the student dashboard content.'),
            if (_userRole == 'business')
              const Text('This is the business dashboard content.'),
            if (!_profileComplete)
              const Text(
                'Your profile is incomplete. Please finish your signup.',
                style: TextStyle(color: Colors.red),
              ),
            // You can add more widgets here based on roles or profile completion status
          ],
        ),
      ),
    );
  }
}