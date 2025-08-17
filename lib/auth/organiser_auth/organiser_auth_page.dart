import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'organiser_dashboard_page.dart';

class OrganiserAuthPage extends StatefulWidget {
  const OrganiserAuthPage({super.key});
  @override
  State<OrganiserAuthPage> createState() => _OrganiserAuthPageState();
}

class _OrganiserAuthPageState extends State<OrganiserAuthPage> {
  bool _login = true, _busy = false;
  String _err = '';
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass  = TextEditingController();

  void _setErr(Object e) => setState(() => _err = e.toString());

  Future<void> _ensureUserDoc(User u, {String? name}) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(u.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'name': name ?? u.displayName ?? '',
        'email': u.email,
        'role': 'organiser',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      // make sure role is set (idempotent)
      await ref.update({'role': 'organiser'});
    }
  }

  Future<void> _submit() async {
    setState(() { _busy = true; _err = ''; });
    try {
      UserCredential cred;
      if (_login) {
        cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(), password: _pass.text.trim(),
        );
      } else {
        cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email.text.trim(), password: _pass.text.trim(),
        );
        await _ensureUserDoc(cred.user!, name: _name.text.trim());
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OrganiserDashboardPage(user: cred.user!)),
      );
    } on FirebaseAuthException catch (e) {
      _setErr(e.message ?? e.code);
    } catch (e) {
      _setErr(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: AppBar(title: const Text('Organiser Sign In')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_login)
                  TextField(controller: _name, decoration: const InputDecoration(labelText: 'Organisation Name')),
                TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 8),
                TextField(controller: _pass, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
                const SizedBox(height: 12),
                if (_err.isNotEmpty) Text(_err, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: brand),
                  child: Text(_login ? 'Sign In' : 'Create Organiser Account'),
                ),
                TextButton(
                  onPressed: _busy ? null : () => setState(() => _login = !_login),
                  child: Text(_login ? 'Create organiser account' : 'I already have an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
