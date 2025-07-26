import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Settings page – allows users to tweak preferences, **log out** and **delete the account**.
/// The theme / font switches are wired up by the parent via the callbacks.
class SettingsPage extends StatefulWidget {
  final void Function(bool) toggleTheme;
  final bool isDarkMode;
  final void Function(bool) toggleDyslexicFont;
  final bool isDyslexicFont;

  const SettingsPage({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
    required this.toggleDyslexicFont,
    required this.isDyslexicFont,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _dark;
  late bool _dys;

  @override
  void initState() {
    super.initState();
    _dark = widget.isDarkMode;
    _dys  = widget.isDyslexicFont;
  }

  /* ──────────────────────────────────────────────────────────
     Auth helpers
     ────────────────────────────────────────────────────────── */
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    // Pop back to the root – AuthGate will take over and show login.
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    try {
      // 1️⃣  Remove Firestore docs (student *or* business – whichever exists)
      final fs = FirebaseFirestore.instance;
      await fs.collection('students').doc(uid).delete().catchError((_) {});
      await fs.collection('businesses').doc(uid).delete().catchError((_) {});

      // 2️⃣  Delete the FirebaseAuth user (may require recent login)
      await user.delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted successfully.')),
      );

      // 3️⃣  Navigate to login (AuthGate will show the auth flow)
      Navigator.popUntil(context, (route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      // Most common: requires-recent-login – let them know.
      _showError('Delete failed: ${e.message ?? e.code}.\nPlease log out & log back in, then try again.');
    } catch (e) {
      _showError('Delete failed: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  /* ──────────────────────────────────────────────────────────
     Confirm dialogs
     ────────────────────────────────────────────────────────── */
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: Navigator.of(context).pop, child: const Text('Cancel')),
          TextButton(onPressed: () { Navigator.of(context).pop(); _logout(); }, child: const Text('Logout')),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text('This will permanently remove your account and all data. This cannot be undone.'),
        actions: [
          TextButton(onPressed: Navigator.of(context).pop, child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAccount();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /* ──────────────────────────────────────────────────────────
     UI
     ────────────────────────────────────────────────────────── */
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(
          children: [
            _accountSection(),
            _notificationsSection(),
            _privacySection(),
            _accessibilitySection(),
            _supportSection(),
          ],
        ),
      );

  ExpansionTile _accountSection() => ExpansionTile(
        title: const Text('Account Management'),
        children: [
          ListTile(title: const Text('Edit Profile'), onTap: () {}),
          ListTile(title: const Text('Change Password'), onTap: () {}),
          ListTile(title: const Text('Logout'), onTap: _confirmLogout),
          ListTile(
            title: const Text('Delete Account'),
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: _confirmDelete,
          ),
        ],
      );

  ExpansionTile _notificationsSection() => ExpansionTile(
        title: const Text('Notifications'),
        children: [
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: true, // TODO make dynamic
            onChanged: (_) {},
          ),
          ListTile(title: const Text('Notification Types'), onTap: () {}),
        ],
      );

  ExpansionTile _privacySection() => ExpansionTile(
        title: const Text('Privacy & Security'),
        children: [
          ListTile(title: const Text('App Version'), subtitle: const Text('1.0.0')),
          ListTile(title: const Text('Terms of Service'), onTap: () {}),
          ListTile(title: const Text('Privacy Policy'), onTap: () {}),
          ListTile(title: const Text('Data Sharing Preferences'), onTap: () {}),
        ],
      );

  ExpansionTile _accessibilitySection() => ExpansionTile(
        title: const Text('Accessibility'),
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: _dark,
            onChanged: (v) { setState(() => _dark = v); widget.toggleTheme(v); },
          ),
          SwitchListTile(
            title: const Text('Dyslexic Font'),
            value: _dys,
            onChanged: (v) { setState(() => _dys = v); widget.toggleDyslexicFont(v); },
          ),
          ListTile(title: const Text('Text Size'), onTap: () {}),
        ],
      );

  ExpansionTile _supportSection() => ExpansionTile(
        title: const Text('Feedback / Support'),
        children: [
          ListTile(title: const Text('Send Feedback'), onTap: () {}),
          ListTile(title: const Text('Contact Support'), onTap: () {}),
        ],
      );
}
