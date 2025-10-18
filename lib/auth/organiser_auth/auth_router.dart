import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<void> routeAfterLogin(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  await user.getIdToken(true);
  final claims = (await user.getIdTokenResult()).claims ?? {};
  if (claims['role'] == 'organizer') {
    Navigator.pushReplacementNamed(context, '/organizerDashboard');
  } else {
    Navigator.pushReplacementNamed(context, '/home'); // student feed
  }
}
