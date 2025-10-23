import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pemrograman_mobile/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app with isLoggedIn = false
    await tester.pumpWidget(const MyApp(isLoggedIn: false));

    // Verify that login screen is shown
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('Register button navigates to register screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isLoggedIn: false));

    // Tap the Register button
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    // Verify that register screen is shown
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });
}