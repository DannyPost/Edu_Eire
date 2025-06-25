import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'signup_page.dart';
import '../homepage.dart'; // Assuming this exists

// Define a consistent color scheme for better character
const Color primaryColor = Color.fromARGB(255, 0, 24, 238); // Deep purple
const Color accentColor = Color(0xFF03DAC6); // Teal
const Color textColor = Color(0xFF424242); // Dark grey for text
const Color errorColor = Colors.redAccent;
const Color googleButtonColor = Color(0xFF4285F4); // Google blue

final GoogleSignIn _googleSignIn = GoogleSignIn(
  clientId: kIsWeb
      ? '21657212241-s031j74rca545f8mv94cn99rcv5da4st.apps.googleusercontent.com'
      : null,
  scopes: ['email', 'profile', 'openid'], // Keep original for now, adjust based on People API fix
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

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      error = ''; // Clear previous errors
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) { // Check if widget is still mounted before navigation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message ?? 'An unknown error occurred.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      error = ''; // Clear previous errors
    });
    try {
      GoogleSignInAccount? user;

      if (kIsWeb) {
        user = await _googleSignIn.signIn();
      } else {
        user = await _googleSignIn.signIn();
      }

      if (user == null) {
        setState(() => error = 'Google sign-in aborted by user.');
        return;
      }

      final googleAuth = await user.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      // General catch for other errors, e.g., People API not enabled.
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
      backgroundColor: Colors.white, // A clean background
      appBar: AppBar(
        title: const Text(
          "Edu Eire",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0, // No shadow for a modern look
      ),
      body: SingleChildScrollView( // Prevents overflow on smaller screens
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF0F4F8)], // Subtle gradient
            ),
          ),
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Logo/Illustration
              Center(
                child: Image.asset(
                  'lib/assets/logo.png', // Replace with your app logo path
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

              // Email TextField
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  prefixIcon: const Icon(Icons.email_outlined, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none, // Hide default border
                  ),
                  filled: true,
                  fillColor: Colors.grey[100], // Light grey background
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                ),
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 16),

              // Password TextField
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

              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : _login, // Disable button while loading
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor, // Custom primary color
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55), // Larger button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5, // Add shadow
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
                icon: Image.asset(
                  'lib/assets/g-logo.png', // Make sure this path is correct
                  height: 24,
                  width: 24,
                ),
                label: const Text(
                  "Continue with Google",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // White background
                  foregroundColor: textColor, // Dark text
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.grey, width: 0.5), // Subtle border
                  ),
                  elevation: 2, // Subtle shadow
                ),
                onPressed: _isLoading ? null : _signInWithGoogle, // Disable while loading
              ),
              const SizedBox(height: 24),

              // Sign Up Text Button
              TextButton(
                onPressed: () => _isLoading
                    ? null
                    : Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupPage()),
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