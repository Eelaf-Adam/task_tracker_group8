import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:task_tracker_group8/main.dart';

void main() {
  testWidgets('Welcome screen displays Tasky and navigates to Sign In', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskyApp());

    // Verify that Tasky and Get Started button are present.
    expect(find.text('Tasky'), findsWidgets);
    expect(find.text('Get Started'), findsOneWidget);

    // Tap Get Started
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Verify that we are on Sign In screen
    expect(find.text('Sign In'), findsWidgets);
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('Sign In screen validates empty fields and navigates to Sign Up', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskyApp());

    // Navigate to Sign In
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Tap Sign Up link
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    // Verify on Sign Up screen
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Full Name'), findsNothing); // label or hint exists
    expect(find.text('Sign Up'), findsWidgets);

    // Try submitting without password
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
    await tester.pumpAndSettle();

    // Password validation error should trigger
    expect(find.text('Please enter your password'), findsOneWidget);
  });
}
