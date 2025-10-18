import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../homepage.dart';
import 'business_pending_page.dart';
import 'google_signin_helper.dart';
import 'business_details_form_page.dart';

// ---- Constants --------------------------------------------------
const _errRed = Colors.redAccent;
const _role   = 'business';

class BusinessAuthPage extends StatefulWidget {
  const BusinessAuthPage({super.key});

  @override
  State<BusinessAuthPage> createState() => _BusinessAuthPageState();
}

class _BusinessAuthPageState extends State<BusinessAuthPage> {
  bool  _login = true;
  bool  _busy  = false;
  String _err  = '';

  final _name  = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _pass  = TextEditingController();

  Color get _brand => Theme.of(context).primaryColor;  // <-- global brand colour

  /* ───────────────────────── Helpers ───────────────────────── */
  void _setErr(Object? e) => setState(() => _err = (e is FirebaseException)
      ? (e.message ?? e.toString())
      : e.toString());

  /* ───────────────────────── Google sign‑in ───────────────────────── */
  Future<void> _googleSignIn() async {
    setState(() { _busy = true; _err = ''; });
    try {
      final user = await signInWithGoogle();
      if (!mounted) return;
      if (user == null) throw Exception('Google sign‑in cancelled');
      await _afterLogin(user, fromGoogle: true);
    } catch (e) {
      if (!mounted) return;
      _setErr('Google sign‑in failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /* ───────────────────────── Email / PW flow ───────────────────────── */
  Future<void> _submit() async {
    setState(() { _busy = true; _err = ''; });
    try {
      UserCredential cred;
      if (_login) {
        cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(), password: _pass.text.trim(),
        );
      } else {
        if (await _alreadyRegistered(_email.text.trim())) {
          _setErr('Registration already submitted – wait for approval.');
          return;
        }
        cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email.text.trim(), password: _pass.text.trim(),
        );
      }
      await _afterLogin(cred.user, fromGoogle: false);
    } on FirebaseAuthException catch (e) {
      _setErr(e);
    } catch (e) {
      _setErr(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /* ─────────────── After login / Firestore doc setup ─────────────── */
  Future<void> _afterLogin(User? u, {required bool fromGoogle}) async {
    if (u == null || !mounted) return;
    final ref = FirebaseFirestore.instance.collection('businesses').doc(u.uid);

    try {
      var snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          'displayName' : fromGoogle ? (u.displayName ?? '') : _name.text.trim(),
          'businessName': fromGoogle ? '' : _name.text.trim(),
          'phone'       : fromGoogle ? '' : _phone.text.trim(),
          'email'       : u.email?.toLowerCase(),
          'role'        : _role,
          'approved'    : false,
        });
        snap = await ref.get();
      }

      final data = snap.data() ?? {};
      final needsExtra = (data['businessName'] as String?).isNullOrEmpty ||
                         (data['phone']       as String?).isNullOrEmpty;

      if (needsExtra) {
        final filled = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BusinessDetailsFormPage(user: u)),
        );
        if (filled != true) return;
      }

      final updated  = (await ref.get()).data()!;
      final approved = updated['approved'] == true;
      final stripeId = updated['stripeAccountId'] as String?;

      if (!approved) {
        if (stripeId == null && !_login) {
          await _beginStripe(u, ref);
        }
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const BusinessPendingPage()),
        );
        return;
      }

      // --- Approved business: go to HomePage ---
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage(
          isDarkMode     : prefs.getBool('isDarkMode') ?? false,
          isDyslexicFont : prefs.getBool('isDyslexicFont') ?? false,
          role           : _role,
          setDarkMode    : (_) {},
          setDyslexicFont: (_) {},
        )),
      );
    } catch (e) {
      _setErr('Firestore error: $e');
    }
  }

  /* ─────────────── Stripe onboarding helper ─────────────── */
  Future<void> _beginStripe(User u, DocumentReference ref) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('createStripeConnectAccount');
      final res = await callable.call({
        'email'       : u.email,
        'businessName': _name.text.trim().isNotEmpty ? _name.text.trim() : (u.displayName ?? 'Business user'),
      });
      await ref.update({'stripeAccountId': res.data['stripeAccountId']});
      final url = res.data['onboardingUrl'] as String;
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _setErr('Stripe error: $e');
    }
  }

  Future<bool> _alreadyRegistered(String email) async =>
      (await FirebaseFirestore.instance
              .collection('businesses')
              .where('email', isEqualTo: email.toLowerCase())
              .limit(1)
              .get())
          .docs
          .isNotEmpty;

  /* ───────────────────────── UI ───────────────────────── */
  @override
  Widget build(BuildContext ctx) => Scaffold(
        appBar: AppBar(
          title: const Text('Business Auth'),
          backgroundColor: _brand,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Icon(Icons.business, size: 90, color: _brand),
            const SizedBox(height: 24),
            if (!_login) ...[
              _field('Business name', Icons.business, _name), const SizedBox(height: 16),
              _field('Phone', Icons.phone, _phone),           const SizedBox(height: 16),
            ],
            _field('E‑mail', Icons.email, _email),            const SizedBox(height: 16),
            _field('Password', Icons.lock, _pass, obs:true), const SizedBox(height: 24),
            _btn(_login ? 'Login' : 'Create account', _submit),
            const SizedBox(height: 16),
            const Center(child: Text('OR', style: TextStyle(fontWeight: FontWeight.w600))),
            const SizedBox(height: 16),
            _googleButton(),
            TextButton(
              onPressed: _busy ? null : () => setState(() => _login = !_login),
              child: Text(
                _login ? 'New business?  Register' : 'Have an account?  Login',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (_err.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_err, textAlign: TextAlign.center,
                    style: const TextStyle(color: _errRed)),
              ),
          ]),
        ),
      );

  /* ---------------- Widgets helpers ---------------- */
  Widget _googleButton() => ElevatedButton.icon(
    onPressed: _busy ? null : _googleSignIn,
    icon: Image.asset('assets/g-logo.png', height: 22, width: 22),
    label: const Text('Sign in with Google', style: TextStyle(fontWeight: FontWeight.w600)),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      side: const BorderSide(color: Colors.black12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      minimumSize: const Size(double.infinity, 48),
    ),
  );

  Widget _field(String lbl, IconData ico, TextEditingController c, {bool obs=false}) =>
      TextField(
        controller: c,
        obscureText: obs,
        decoration: InputDecoration(
          labelText: lbl,
          prefixIcon: Icon(ico, color: _brand),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      );

  Widget _btn(String title, VoidCallback fn) => ElevatedButton(
        onPressed: _busy ? null : fn,
        style: ElevatedButton.styleFrom(
          backgroundColor: _brand,
          minimumSize: const Size(double.infinity, 50),
        ),
        child: _busy
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(title, style: const TextStyle(fontSize: 18)),
      );
}

extension _StrNullEmpty on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
}
