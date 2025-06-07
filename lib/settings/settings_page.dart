import 'package:flutter/material.dart';

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
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool isDarkMode;
  late bool isDyslexicFont;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
    isDyslexicFont = widget.isDyslexicFont;
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully! (placeholder)'),
                ),
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ExpansionTile(
            title: const Text('Account Management'),
            children: [
              ListTile(
                title: const Text('Edit Profile'),
                onTap: () {},
              ),
              ListTile(
                title: const Text('Change Password'),
                onTap: () {},
              ),
              ListTile(
                title: const Text('Logout'),
                onTap: _showLogoutDialog,
              ),
              ListTile(
                title: const Text('Delete Account'),
                onTap: () {},
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('Notifications'),
            children: [
              SwitchListTile(
                title: const Text('Enable Notifications'),
                value: true, // TODO: Make dynamic
                onChanged: (value) {},
              ),
              ListTile(
                title: const Text('Notification Types'),
                onTap: () {},
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('Privacy & Security'),
            children: [
              ListTile(
                title: const Text('App Version'),
                subtitle: const Text('1.0.0'),
              ),
              ListTile(
                title: const Text('Terms of Service'),
                onTap: () {},
              ),
              ListTile(
                title: const Text('Privacy Policy'),
                onTap: () {},
              ),
              ListTile(
                title: const Text('Data Sharing Preferences'),
                onTap: () {},
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('Accessibility'),
            children: [
              SwitchListTile(
                title: const Text('Dark Mode'),
                value: isDarkMode,
                onChanged: (value) {
                  setState(() {
                    isDarkMode = value;
                  });
                  widget.toggleTheme(value);
                },
              ),
              SwitchListTile(
                title: const Text('Dyslexic Font'),
                value: isDyslexicFont,
                onChanged: (value) {
                  setState(() {
                    isDyslexicFont = value;
                  });
                  widget.toggleDyslexicFont(value);
                },
              ),
              ListTile(
                title: const Text('Text Size'),
                onTap: () {},
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('Feedback / Support'),
            children: [
              ListTile(
                title: const Text('Send Feedback'),
                onTap: () {},
              ),
              ListTile(
                title: const Text('Contact Support'),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
