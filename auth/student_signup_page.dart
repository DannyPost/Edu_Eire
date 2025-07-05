import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart'; // Make sure you have this package: add email_validator: ^2.1.17 to pubspec.yaml and run flutter pub get

import '../../homepage.dart'; // Assuming this exists

// Define common colors or import from a constants file
const Color primaryColor = Color.fromARGB(255, 0, 24, 238);
const Color textColor = Color(0xFF424242);
const Color errorColor = Colors.redAccent;

class StudentSignupPage extends StatefulWidget {
  final User? user; // Accept the user object
  const StudentSignupPage({super.key, this.user});

  @override
  State<StudentSignupPage> createState() => _StudentSignupPageState();
}

class _StudentSignupPageState extends State<StudentSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _institutionController = TextEditingController();

  String _error = '';
  bool _isLoading = false;
  bool _isGoogleUser = false; // Flag to check if user came via Google

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      // If a user object was passed, it means they are already authenticated (e.g., via Google)
      _isGoogleUser = true;
      _emailController.text = widget.user!.email ?? ''; // Pre-fill email
      _fullNameController.text = widget.user!.displayName ?? ''; // Pre-fill display name
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      User? currentUser = widget.user; // Start with the passed user

      if (!_isGoogleUser) {
        // Only create a new Firebase Auth user if they are NOT a Google user
        // i.e., they are signing up with email/password
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        currentUser = userCredential.user;
      }

      if (currentUser != null) {
        // --- Debugging Prints for 'users' collection ---
        print('Attempting to write to users/${currentUser.uid}');
        final userDataToWrite = {
          'email': currentUser.email,
          'role': 'student',
          'profileCompleted': true, // Mark as complete after this form
          'createdAt': FieldValue.serverTimestamp(),
          'displayName': _fullNameController.text.trim(), // Use entered name or pre-filled Google name
          'photoURL': currentUser.photoURL, // Keep photoURL from Google if available
          'lastLogin': FieldValue.serverTimestamp(), // Optional: Update last login time
        };
        print('User Data to Write: $userDataToWrite');
        // --- End Debugging Prints ---

        // 1. Update/Create 'users' collection document for the current user
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set(
          userDataToWrite,
          SetOptions(merge: true),
        );
        print('Successfully wrote to users collection.'); // Debug print

        // --- Debugging Prints for 'students' collection ---
        print('Attempting to write to students/${currentUser.uid}');
        final studentDataToWrite = {
          'fullName': _fullNameController.text.trim(),
          'institution': _institutionController.text.trim(),
          'registrationDate': FieldValue.serverTimestamp(),
          // Add any other student-specific fields here
        };
        print('Student Data to Write: $studentDataToWrite');
        // --- End Debugging Prints ---

        // 2. Save student-specific details in 'students' collection
        await FirebaseFirestore.instance.collection('students').doc(currentUser.uid).set(
          studentDataToWrite,
        );
        print('Successfully wrote to students collection.'); // Debug print

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        setState(() {
          _error = 'User not authenticated after signup.';
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'An authentication error occurred.');
      print('FirebaseAuthException: ${e.message}'); // Debug print
    } on FirebaseException catch (e) {
      setState(() => _error = 'Firestore error: ${e.message}');
      print('FirebaseException (Firestore): ${e.message}'); // Debug print
    } catch (e) {
      setState(() => _error = 'An unexpected error occurred: ${e.toString()}');
      print('General Error: ${e.toString()}'); // Debug print
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _institutionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Signup"),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) => value!.isEmpty ? 'Please enter your full name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                readOnly: _isGoogleUser, // Make email read-only for Google users
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!EmailValidator.validate(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Only show password fields if not a Google user
              if (!_isGoogleUser) ...[
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _institutionController,
                decoration: const InputDecoration(labelText: 'Institution'),
                validator: (value) => value!.isEmpty ? 'Please enter your institution' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Sign Up',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _error,
                    style: TextStyle(color: errorColor),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}