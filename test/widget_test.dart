import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pemrograman_mobile/main.dart';

void main() {
  testWidgets('App starts with Login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app starts with Login screen
    expect(find.text('Login'), findsOneWidget); // AppBar title
    expect(find.text('Username'), findsOneWidget); // Username field
    expect(find.text('Password'), findsOneWidget); // Password field
    expect(find.text('LOGIN'), findsOneWidget); // Login button
  });

  testWidgets('Register navigation works', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Tap the Register text button
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    // Verify that we navigated to Register screen
    expect(find.text('Register'), findsOneWidget); // AppBar title
    expect(find.text('Full Name'), findsOneWidget); // Full Name field
  });
}