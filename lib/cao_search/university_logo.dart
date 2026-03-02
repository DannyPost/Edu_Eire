import 'package:flutter/material.dart';

class UniversityLogo extends StatelessWidget {
  final String university;

  const UniversityLogo({super.key, required this.university});

  @override
  Widget build(BuildContext context) {
    const logos = {
      'ATLANTIC TECHNOLOGICAL UNIVERSITY':
          'assets/logos/atlantic_technological_university.png',
      'NATIONAL COLLEGE OF ART AND DESIGN':
          'assets/logos/ncad.png',
    };

    final path = logos[university.toUpperCase()];

    return path == null
        ? const Icon(Icons.school, size: 64)
        : Image.asset(path, height: 64);
  }
}
