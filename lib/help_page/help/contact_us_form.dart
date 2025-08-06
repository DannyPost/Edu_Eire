import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactUsForm extends StatefulWidget {
  const ContactUsForm({super.key});

  @override
  State<ContactUsForm> createState() => _ContactUsFormState();
}

class _ContactUsFormState extends State<ContactUsForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController    = TextEditingController();
  final _emailController   = TextEditingController();
  final _messageController = TextEditingController();
  bool _loading = false;

  // -------------------------------------------------------------
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    await FirebaseFirestore.instance.collection('contact_submissions').add({
      'name'     : _nameController.text,
      'email'    : _emailController.text,
      'message'  : _messageController.text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() => _loading = false);

    final snackBar = SnackBar(
      content: const Text('Thank you! Your message has been sent.'),
      backgroundColor: Theme.of(context).colorScheme.primary,
    );
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(snackBar);

    _nameController.clear();
    _emailController.clear();
    _messageController.clear();
  }

  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final brand   = theme.primaryColor;
    final bgField = theme.brightness == Brightness.light
        ? Colors.grey[50]
        : Colors.grey[800];

    return Card(
      color: theme.cardColor,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Send us a message',
                style: TextStyle(
                  color: brand,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _inputField('Name', _nameController, bgField, false, (v) =>
                  v == null || v.isEmpty ? 'Enter your name' : null),
              const SizedBox(height: 14),
              _inputField('Email', _emailController, bgField, false, (v) =>
                  v != null && EmailValidator.validate(v) ? null : 'Enter a valid email'),
              const SizedBox(height: 14),
              _inputField('Message', _messageController, bgField, true, (v) =>
                  v == null || v.isEmpty ? 'Enter your message' : null,
                maxLines: 4,
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brand,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _loading ? null : _submitForm,
                  child: _loading
                      ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))
                      : const Text('Send Message', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller, Color? fill, bool multiline, String? Function(String?) validator, {int maxLines = 1}) {
    return TextFormField(
      controller : controller,
      validator  : validator,
      maxLines   : multiline ? maxLines : 1,
      decoration : InputDecoration(
        labelText: label,
        filled   : true,
        fillColor: fill,
        border   : OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
