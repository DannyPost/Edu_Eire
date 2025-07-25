import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../homepage.dart';
import 'business_auth_page.dart';
import 'google_signin_helper.dart';

const primaryColor = Color(0xFF0018EE);
const errorColor   = Colors.redAccent;
const _role        = 'student';

class StudentAuthPage extends StatefulWidget {
  const StudentAuthPage({super.key});
  @override State<StudentAuthPage> createState() => _StudentAuthPageState();
}

class _StudentAuthPageState extends State<StudentAuthPage> {
  bool _login = true;
  bool _busy = false;
  String _err = '';
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  Future<void> _googleSignIn() async {
    setState(() { _busy = true; _err = ''; });
    try {
      final user = await signInWithGoogle();
      if (!mounted) return;
      if (user == null) throw Exception('Google sign-in cancelled');
      await _finishAuth(user, fromGoogle: true);
      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      setState(() => _err = e is FirebaseException
        ? (e.message ?? e.toString())
        : e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  Future<void> _submitEmailPw() async {
    setState(() { _busy = true; _err = ''; });
    try {
      UserCredential cred;
      if (_login) {
        cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(), password: _pass.text.trim());
      } else {
        cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email.text.trim(), password: _pass.text.trim());
      }
      await _finishAuth(cred.user, fromGoogle: false);
    } on FirebaseAuthException catch (e) {
      setState(() => _err = e.message ?? 'Auth failed');
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _finishAuth(User? user, {required bool fromGoogle}) async {
    if (user == null || !mounted) return;
    try {
      await FirebaseFirestore.instance.collection('students').doc(user.uid).set({
        'displayName': fromGoogle ? user.displayName : _name.text.trim(),
        'role'       : _role,
        'email'      : user.email?.toLowerCase(),
      }, SetOptions(merge: true));
      final prefs = await SharedPreferences.getInstance();
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => HomePage(
          isDarkMode     : prefs.getBool('isDarkMode') ?? false,
          isDyslexicFont : prefs.getBool('isDyslexicFont') ?? false,
          role           : _role,
          setDarkMode: (_) {},           
          setDyslexicFont: (_) {},
        )));
    } catch (e) {
      setState(() => _err = e is FirebaseException
        ? (e.message ?? e.toString())
        : e.toString());
    }
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(title: const Text('Student'),
        backgroundColor: primaryColor, centerTitle: true),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Image.asset('assets/g-logo.png',
                  height: 120, width: 120)),
          const SizedBox(height: 30),
          if (!_login) ...[
            _field('Name', Icons.person_outline, _name, false),
            const SizedBox(height: 16),
          ],
          _field('E-mail', Icons.email_outlined, _email, false),
          const SizedBox(height: 16),
          _field('Password', Icons.lock_outline, _pass, true),
          const SizedBox(height: 24),
          _button(_login ? 'Login' : 'Create account', _submitEmailPw),
          const SizedBox(height: 16),
          const Center(child: Text('OR', style: TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(height: 16),
          _googleButton(),
          TextButton(
            onPressed: _busy ? null : () => setState(() => _login = !_login),
            child: Text(_login
                ? 'New user?  Sign up'
                : 'Have an account?  Login',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: _busy ? null : () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const BusinessAuthPage())),
            child: const Text('Business login / register',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          if (_err.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_err, textAlign: TextAlign.center,
                  style: const TextStyle(color: errorColor))),
        ],
      ),
    ),
  );

  Widget _googleButton() => ElevatedButton.icon(
    onPressed: _busy ? null : _googleSignIn,
    icon: Image.asset('assets/g-logo.png', height: 22, width: 22),
    label: const Text('Sign in with Google', style: TextStyle(fontWeight: FontWeight.w600)),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white, foregroundColor: Colors.black87,
      side: const BorderSide(color: Colors.black12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      minimumSize: const Size(double.infinity, 48),
    ),
  );

  Widget _field(String lbl, IconData ico, TextEditingController c, bool obs) =>
      TextField(
        controller: c, obscureText: obs,
        decoration: InputDecoration(
          labelText: lbl,
          prefixIcon: Icon(ico, color: primaryColor),
          filled: true, fillColor: Colors.grey[100],
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      );

  Widget _button(String txt, VoidCallback fn) => ElevatedButton(
    onPressed: _busy ? null : fn,
    style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        minimumSize: const Size(double.infinity, 50)),
    child: _busy
        ? const CircularProgressIndicator(color: Colors.white)
        : Text(txt, style: const TextStyle(fontSize: 18)),
  );
}
