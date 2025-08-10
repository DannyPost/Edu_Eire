// lib/studybot/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthService {
  Future<String?> getIdToken();
}

/// Real auth backed by FirebaseAuth; fetches a fresh ID token per call.
class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth;
  FirebaseAuthService({FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Future<String?> getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken(true); // force refresh to avoid expiry issues
  }
}

/// (Optional) Dev stub for tests without Firebase sign-in.
class DevAuthService implements AuthService {
  String? _token;
  void setDebugToken(String token) => _token = token;
  @override
  Future<String?> getIdToken() async => _token;
}
