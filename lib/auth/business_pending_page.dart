import 'package:flutter/material.dart';
const _blue = Color(0xFF0018EE);

class BusinessPendingPage extends StatelessWidget {
  const BusinessPendingPage({super.key});
  @override
  Widget build(BuildContext ctx) => Scaffold(
        appBar: AppBar(title: const Text('Business sign-up'), backgroundColor: _blue),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.search, size: 96, color: _blue.withOpacity(.8)),
              const SizedBox(height: 24),
              const Text(
                'We’re verifying your business.\n'
                'You’ll get an e-mail when approved.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Back to login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue, minimumSize: const Size(220, 48)),
                onPressed: () => Navigator.popUntil(ctx, (r) => r.isFirst),
              )
            ]),
          ),
        ));
}
