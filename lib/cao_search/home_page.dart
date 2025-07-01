import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Main Home Page')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Go to CAO Search'),
          onPressed: () {
            Navigator.pushNamed(context, '/cao-search');
          },
        ),
      ),
    );
  }
}
