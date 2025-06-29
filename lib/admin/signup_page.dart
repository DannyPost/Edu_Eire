import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

class SignupPage extends StatefulWidget {
  final String? email;
  const SignupPage({Key? key, this.email}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  final _passwordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _sectorController = TextEditingController();
  final _sizeController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email ?? '');
  }

  Future<void> _signupAndStripeOnboarding() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      // 1. Create Firebase user
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Call Cloud Function to create Stripe account & onboarding link
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('createStripeConnectAccount');
      final stripeRes = await callable.call(<String, dynamic>{
        'email': _emailController.text.trim(),
        'businessName': _businessNameController.text.trim(),
      });

      final stripeAccountId = stripeRes.data['stripeAccountId'];
      final onboardingUrl = stripeRes.data['onboardingUrl'];

      // 3. Store business data in Firestore
      await FirebaseFirestore.instance.collection('admins').doc(cred.user!.uid).set({
        'email': _emailController.text.trim(),
        'businessName': _businessNameController.text.trim(),
        'sector': _sectorController.text.trim(),
        'size': _sizeController.text.trim(),
        'stripeAccountId': stripeAccountId,
        'approved': false,
        'created': DateTime.now().toIso8601String(),
      });

      setState(() {
        _isLoading = false;
        _error = null;
      });

      // 4. Launch Stripe onboarding link
      if (await canLaunch(onboardingUrl)) {
        await launch(onboardingUrl);
      } else {
        throw 'Could not launch onboarding link';
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Signup Complete"),
          content: const Text("Finish your Stripe onboarding. You will receive an email when approved."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _businessNameController.dispose();
    _sectorController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Signup')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text("Sign up as a business", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => v == null || !v.contains('@') ? "Enter valid email" : null,
                  ),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (v) => v == null || v.length < 6 ? "Password too short" : null,
                  ),
                  const Divider(height: 32),
                  TextFormField(
                    controller: _businessNameController,
                    decoration: const InputDecoration(labelText: 'Business Name'),
                    validator: (v) => v == null || v.isEmpty ? "Required" : null,
                  ),
                  TextFormField(
                    controller: _sectorController,
                    decoration: const InputDecoration(labelText: 'Sector'),
                    validator: (v) => v == null || v.isEmpty ? "Required" : null,
                  ),
                  TextFormField(
                    controller: _sizeController,
                    decoration: const InputDecoration(labelText: 'Business Size'),
                    validator: (v) => v == null || v.isEmpty ? "Required" : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 18),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _signupAndStripeOnboarding,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            minimumSize: const Size(double.infinity, 44),
                          ),
                          child: const Text('Submit & Start Stripe Onboarding'),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
