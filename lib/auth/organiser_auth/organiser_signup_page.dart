import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrganiserSignupPage extends StatefulWidget {
  const OrganiserSignupPage({super.key});

  @override
  State<OrganiserSignupPage> createState() => _OrganiserSignupPageState();
}

class _OrganiserSignupPageState extends State<OrganiserSignupPage> {
  final _orgName   = TextEditingController();
  final _email     = TextEditingController();
  final _password  = TextEditingController();
  final _password2 = TextEditingController();
  bool _busy = false;
  String _err = '';

Future<void> _submit() async {
  setState(() { _busy = true; _err = ''; });
  try {
    if (_orgName.text.trim().isEmpty) throw Exception('Please enter an organization name.');
    if (_password.text != _password2.text) throw Exception('Passwords do not match.');

    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _email.text.trim(),
      password: _password.text,
    );
    final uid = cred.user!.uid;

    await FirebaseFirestore.instance.collection('organizers').doc(uid).set({
      'orgName'  : _orgName.text.trim(),
      'email'    : _email.text.trim().toLowerCase(),
      'approved' : false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account created. Pending approval.')),
    );
    Navigator.pop(context);
  } on FirebaseException catch (e) {
    // <— This will show Firestore problems like permission-denied
    setState(() => _err = 'Firestore error: ${e.code} — ${e.message}');
  } on FirebaseAuthException catch (e) {
    setState(() => _err = 'Auth error: ${e.code} — ${e.message}');
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
      appBar: AppBar(title: const Text('Create Organizer Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _orgName,
              decoration: InputDecoration(
                labelText: 'Organization Name',
                prefixIcon: Icon(Icons.apartment_outlined, color: brand),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined, color: brand),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline, color: brand),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password2,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline, color: brand),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create organizer account'),
            ),
            if (_err.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_err, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
              ),
          ],
        ),
      ),
    );
  }
}
