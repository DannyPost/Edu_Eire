import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Universal Google sign-in (web uses popup, mobile uses native flow)
Future<User?> signInWithGoogle() async {
  if (kIsWeb) {
    // Web: popup sign-in
    final authProvider = GoogleAuthProvider();
    final userCred = await FirebaseAuth.instance.signInWithPopup(authProvider);
    return userCred.user;
  } else {
    // Mobile/desktop: google_sign_in package
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCred =
        await FirebaseAuth.instance.signInWithCredential(credential);
    return userCred.user;
  }
}
