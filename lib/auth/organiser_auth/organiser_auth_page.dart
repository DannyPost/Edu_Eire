import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../business_auth_page.dart'; // if you need it nearby; safe to remove if unused
import '../google_signin_helper.dart'; // <-- uses your existing helper
import '../../organizer/organizer_dashboard.dart'; 
// ^ if you don't have this, you can navigate back and let AuthGate route,
//   or replace with your desired destination. If using AuthGate, remove this import.
import 'organiser_signup_page.dart';


class OrganiserAuthPage extends StatefulWidget {
  const OrganiserAuthPage({super.key});

  @override
  State<OrganiserAuthPage> createState() => _OrganiserAuthPageState();
}

class _OrganiserAuthPageState extends State<OrganiserAuthPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String _err = '';

  Future<bool> _isOrganizerUid(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('organizers')
        .doc(uid)
        .get();
    return doc.exists;
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _busy = true; _err = ''; });
    try {
      final user = await signInWithGoogle(); // from your helper
      if (user == null) throw Exception('Google sign-in cancelled.');
      final ok = await _isOrganizerUid(user.uid);
      if (!ok) {
        await FirebaseAuth.instance.signOut();
        throw Exception('This Google account is not approved as an organizer.');
      }

      // If your app uses AuthGate, you can just pop to root and let it route.
     if (!mounted) return;
    Navigator.pop(context); // returns to AuthGate; it will route to OrganizerDashboard
      // Or navigate directly to a page if you prefer:
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OrganizerDashboard()));
    } on FirebaseAuthException catch (e) {
      setState(() => _err = e.message ?? 'Google sign-in failed.');
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithEmail() async {
    setState(() { _busy = true; _err = ''; });
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      final ok = await _isOrganizerUid(cred.user!.uid);
      if (!ok) {
        await FirebaseAuth.instance.signOut();
        throw Exception('This account is not approved as an organizer.');
      }

      if (!mounted) return;
      Navigator.pop(context); // back to AuthGate to route
      // Or pushReplacement to your dashboard page directly
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'user-not-found' => 'No user with that email.',
        'wrong-password' => 'Incorrect password.',
        'invalid-email'  => 'Invalid email address.',
        _ => 'Sign-in failed: ${e.code}',
      };
      setState(() => _err = msg);
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('Organizer Login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: _email,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined, color: brand),
                filled: true, fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline, color: brand),
                filled: true, fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy ? null : _signInWithEmail,
              child: _busy
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Sign in as Organizer'),
            ),
            const SizedBox(height: 16),
            const Center(child: Text('OR', style: TextStyle(fontWeight: FontWeight.w600))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _busy ? null : _signInWithGoogle,
              icon: Image.asset('assets/g-logo.png', height: 22, width: 22),
              label: const Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                side: const BorderSide(color: Colors.black12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            if (_err.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _err,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
              const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const OrganiserSignupPage()),
                          ),
                  child: const Text('Create organizer account'),
                ),

          ],
        ),
      ),
    );
  }
}
