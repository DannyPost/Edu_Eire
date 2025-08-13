import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InterestsSurveyPage extends StatefulWidget {
  const InterestsSurveyPage({Key? key}) : super(key: key);

  @override
  State<InterestsSurveyPage> createState() => _InterestsSurveyPageState();
}

class _InterestsSurveyPageState extends State<InterestsSurveyPage> {
  final List<String> _allInterests = [
    'Engineering',
    'Science',
    'Arts',
    'Business',
    'Health',
    'Computing',
    'Law',
    'Education'
  ];
  final List<String> _selected = [];
  bool _loading = false;

  Future<void> _submit() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one interest')),
      );
      return;
    }

    setState(() => _loading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('students').doc(uid).set({
      'interestsCompleted': true,
      'interests': _selected,
    }, SetOptions(merge: true));

    setState(() => _loading = false);

    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tell us your interests')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: _allInterests.map((interest) {
                final selected = _selected.contains(interest);
                return CheckboxListTile(
                  title: Text(interest),
                  value: selected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selected.add(interest);
                      } else {
                        _selected.remove(interest);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          _loading
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Continue'),
                  ),
                ),
        ],
      ),
    );
  }
}
