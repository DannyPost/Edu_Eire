import 'package:flutter/material.dart';

/// Shown while the business account is awaiting admin approval.
class BusinessPendingPage extends StatelessWidget {
  const BusinessPendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business sign‑up'),
        backgroundColor: cs.primary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 96, color: cs.primary.withOpacity(.8)),
              const SizedBox(height: 24),
              const Text(
                'We’re verifying your business.\nYou’ll get an e‑mail when approved.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                icon: const Icon(Icons.login),
                label: const Text('Back to login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  minimumSize: const Size(220, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
