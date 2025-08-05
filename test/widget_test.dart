import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:academic_support_app/main.dart'; // ✅ Corrected import path
import 'package:academic_support_app/academic_support/academic_support_screen.dart';


void main() {
  testWidgets('Academic Support screen renders', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());

  // Verify that AcademicSupportScreen is part of the widget tree
  expect(find.byType(AcademicSupportScreen), findsOneWidget);
});
}
