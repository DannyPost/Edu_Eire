import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BusinessDetailsFormPage extends StatefulWidget {
  final User user;
  const BusinessDetailsFormPage({required this.user, super.key});
  @override
  State<BusinessDetailsFormPage> createState() => _BusinessDetailsFormPageState();
}

class _BusinessDetailsFormPageState extends State<BusinessDetailsFormPage> {
  final _businessName = TextEditingController();
  final _phone = TextEditingController();
  bool _busy = false, _error = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Business Details')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('Please enter your business details to complete registration.',
            style: TextStyle(fontSize: 16)),
        const SizedBox(height: 24),
        TextField(
          controller: _businessName,
          decoration: const InputDecoration(labelText: 'Business Name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          decoration: const InputDecoration(labelText: 'Phone'),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Submit'),
        ),
        if (_error) const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text('Please fill all fields', style: TextStyle(color: Colors.red)),
        ),
      ]),
    ),
  );

  void _submit() async {
    setState(() { _busy = true; _error = false; });
    if (_businessName.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      setState(() { _error = true; _busy = false; });
      return;
    }
    await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set({
      'businessName': _businessName.text.trim(),
      'phone': _phone.text.trim(),
    }, SetOptions(merge: true));
    Navigator.pop(context, true);
  }
}
