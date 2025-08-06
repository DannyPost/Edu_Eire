<<<<<<< HEAD
import 'package:flutter_test/flutter_test.dart';
import 'package:academic_support_app/main.dart'; // ✅ Corrected import path
import 'package:academic_support_app/academic_support/academic_support_screen.dart';


void main() {
  testWidgets('Academic Support screen renders', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());

  // Verify that AcademicSupportScreen is part of the widget tree
  expect(find.byType(AcademicSupportScreen), findsOneWidget);
});
=======
// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edueire2/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
>>>>>>> e0b4353cf7ba5b3fecaec3524f9d21f0f5e54769
}
