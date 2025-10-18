import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Universal Google sign‑in helper.
///
/// * **Web** → uses Firebase’s `signInWithPopup` convenience.
/// * **Mobile / Desktop** → uses the `google_sign_in` package to obtain a
///   Google ID‑token + access‑token, then exchanges them for a Firebase
///   credential.
///
/// Returns the **Firebase [User]** on success, or `null` if the user canceled
/// the sign‑in flow.
Future<User?> signInWithGoogle() async {
  if (kIsWeb) {
    // ── Web: open Google auth popup ────────────────────────────────
    final provider = GoogleAuthProvider();
    // You can add extra scopes if you need YouTube / Contacts APIs, e.g.:
    // provider.addScope('https://www.googleapis.com/auth/youtube.readonly');
    final userCred = await FirebaseAuth.instance.signInWithPopup(provider);
    return userCred.user;
  } else {
    // ── Mobile / Desktop: use google_sign_in package ───────────────
    final googleSignIn = GoogleSignIn(scopes: const ['email']);
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null; // user dismissed the dialog

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
