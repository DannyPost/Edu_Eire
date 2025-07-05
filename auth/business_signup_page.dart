// lib/pages/auth/business_signup_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';

import '../../homepage.dart'; // Assuming this exists

// Define common colors or import from a constants file
const Color primaryColor = Color.fromARGB(255, 0, 24, 238);
const Color textColor = Color(0xFF424242);
const Color errorColor = Colors.redAccent;

class BusinessSignupPage extends StatefulWidget {
  final User? user; // Accept the user object
  const BusinessSignupPage({super.key, this.user});

  @override
  State<BusinessSignupPage> createState() => _BusinessSignupPageState();
}

class _BusinessSignupPageState extends State<BusinessSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

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
      _contactPersonController.text = widget.user!.displayName ?? ''; // Pre-fill display name
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
          'role': 'business',
          'profileCompleted': true, // Mark as complete after this form
          'createdAt': FieldValue.serverTimestamp(),
          'displayName': _contactPersonController.text.trim(), // Use entered name or pre-filled Google name
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

        // --- Debugging Prints for 'businesses' collection ---
        print('Attempting to write to businesses/${currentUser.uid}');
        final businessDataToWrite = {
          'businessName': _businessNameController.text.trim(),
          'contactPerson': _contactPersonController.text.trim(),
          'phoneNumber': _phoneNumberController.text.trim(),
          'registrationDate': FieldValue.serverTimestamp(),
          // Add any other business-specific fields here
        };
        print('Business Data to Write: $businessDataToWrite');
        // --- End Debugging Prints ---

        // 2. Save business-specific details in 'businesses' collection
        await FirebaseFirestore.instance.collection('businesses').doc(currentUser.uid).set(
          businessDataToWrite,
        );
        print('Successfully wrote to businesses collection.'); // Debug print

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
    _businessNameController.dispose();
    _contactPersonController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Business Signup"),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(labelText: 'Business Name'),
                validator: (value) => value!.isEmpty ? 'Please enter your business name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactPersonController,
                decoration: const InputDecoration(labelText: 'Contact Person'),
                validator: (value) => value!.isEmpty ? 'Please enter a contact person' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Please enter your phone number' : null,
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