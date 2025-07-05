import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../homepage.dart';
import 'choose_signup_type_page.dart';

// Define a consistent color scheme
const Color primaryColor = Color.fromARGB(255, 0, 24, 238); // Deep blue
const Color accentColor = Color(0xFF03DAC6); // Teal
const Color textColor = Color(0xFF424242); // Dark grey for text
const Color errorColor = Colors.redAccent;
const Color googleButtonColor = Color(0xFF4285F4); // Google blue

// Make this instance public so it can be accessed from other files (e.g., HomePage for signOut)
final GoogleSignIn googleSignIn = GoogleSignIn( // Renamed from _googleSignIn
  clientId: kIsWeb
      ? '21657212241-s031j74rca545f8mv94cn99rcv5da4st.apps.googleusercontent.com'
      : null,
  scopes: ['email', 'profile', 'openid'],
);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String error = '';
  bool _isLoading = false; // To manage loading state

  Future<void> _checkAndNavigateUser(User? user) async {
    if (user == null || !mounted) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data();
        final bool profileCompleted = data?['profileCompleted'] ?? false;
        // final String? role = data?['role']; // Role can be null initially for Google users

        if (profileCompleted) {
          // If profile is complete, navigate to HomePage
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          }
        } else {
          // Profile is NOT complete. They need to choose a role and complete the profile.
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ChooseSignupTypePage()),
            );
          }
        }
      } else {
        // User document doesn't exist (e.g., brand new Google user).
        // They need to choose their role and complete signup.
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ChooseSignupTypePage()),
          );
        }
      }
    } catch (e) {
      print("Error checking user data for navigation: $e");
      // Fallback: If there's an error fetching user data, navigate to ChooseSignupTypePage
      // as it's safer than HomePage if profile state is unknown.
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ChooseSignupTypePage()),
        );
      }
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      error = ''; // Clear previous errors
    });
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (userCredential.user == null) {
        setState(() {
          error = 'Login failed: User information not available.';
          _isLoading = false;
        });
        return; // Stop execution if user is null
      }
      if (mounted) {
        await _checkAndNavigateUser(userCredential.user);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message ?? 'An unknown error occurred.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async { // Renamed from signInWithGoogle to _signInWithGoogle to match class convention
    setState(() {
      _isLoading = true;
      error = ''; // Clear previous errors
    });
    try {
      GoogleSignInAccount? user;

      // The kIsWeb condition here is redundant as signIn() is compatible across platforms
      user = await googleSignIn.signIn(); // Use the global googleSignIn instance

      if (user == null) {
        setState(() => error = 'Google sign-in aborted by user.');
        return;
      }

      final googleAuth = await user.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user == null) {
        setState(() {
          error = 'Google sign-in failed: User information not available.';
          _isLoading = false;
        });
        return; // Stop execution if user is null
      }

      // Check if this is a brand new Google user
      // If the user document doesn't exist, create it and mark profile incomplete
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'role': null, // Role is initially null for new Google users
          'profileCompleted': false, // Profile is initially false
          'createdAt': FieldValue.serverTimestamp(),
          'displayName': userCredential.user!.displayName,
          'photoURL': userCredential.user!.photoURL,
        });
      }

      if (mounted) {
        await _checkAndNavigateUser(userCredential.user);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => error = 'Google sign-in failed: ${e.message}');
    } catch (e) {
      // Catch Firestore permission errors or other general errors here
      print("Google Sign-In General Error: $e");
      setState(() => error = 'Google sign-in failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Edu Eire",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF0F4F8)],
            ),
          ),
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset(
                  'lib/assets/g-logo.png', // Replace with your app logo path
                  height: 120,
                  width: 120,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                "Login to your account",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  prefixIcon: const Icon(Icons.email_outlined, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                ),
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outline, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                ),
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Login",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 16),
              // Google Sign-In Button
              ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white, // Or a contrasting color
                          strokeWidth: 2,
                        ),
                      )
                    : Image.asset(
                        'lib/assets/g-logo.png',
                        height: 24,
                        width: 24,
                      ),
                label: _isLoading
                    ? const Text(
                        "Loading...", // Or an empty string if you prefer
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      )
                    : const Text(
                        "Continue with Google",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: textColor,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.grey, width: 0.5),
                  ),
                  elevation: 2,
                ),
                onPressed: _isLoading ? null : _signInWithGoogle, // Call the new _signInWithGoogle
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => _isLoading
                    ? null
                    : Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChooseSignupTypePage()),
                      ),
                child: Text(
                  "Don't have an account? Sign up",
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    error,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: errorColor, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}