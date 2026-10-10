import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_tracker_group8/main.dart';
import 'package:task_tracker_group8/services/auth_service.dart';
import 'package:task_tracker_group8/utils/validators.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppValidators Tests', () {
    test('Name validator requires capital letter and minimum 2 characters', () {
      expect(AppValidators.validateName(''), 'Please enter your name');
      expect(AppValidators.validateName('a'), 'Name must be at least 2 characters');
      expect(AppValidators.validateName('lee'), 'Name must start with a capital letter');
      expect(AppValidators.validateName('123'), 'Name must start with a capital letter');
      expect(AppValidators.validateName('Lee'), isNull);
      expect(AppValidators.validateName('Sarah Connor'), isNull);
    });

    test('Email validator enforces valid email format', () {
      expect(AppValidators.validateEmail(''), 'Please enter your email');
      expect(AppValidators.validateEmail('invalid'), 'Please enter a valid email address');
      expect(AppValidators.validateEmail('user@'), 'Please enter a valid email address');
      expect(AppValidators.validateEmail('user@domain'), 'Please enter a valid email address');
      expect(AppValidators.validateEmail('lee@example.com'), isNull);
      expect(AppValidators.validateEmail('john.doe@sub.domain.org'), isNull);
    });

    test('Password validator enforces letters, numbers, special char and 8-12 length', () {
      expect(AppValidators.validatePassword(''), 'Please enter your password');
      expect(AppValidators.validatePassword('Short1!'), 'Password must be between 8 and 12 characters');
      expect(AppValidators.validatePassword('WayTooLongPassword123!'), 'Password must be between 8 and 12 characters');
      expect(AppValidators.validatePassword('12345678!'), 'Password must contain letters');
      expect(AppValidators.validatePassword('abcdefgh!'), 'Password must contain at least one number');
      expect(AppValidators.validatePassword('Password12'), 'Password must contain at least one special character');
      expect(AppValidators.validatePassword('Pass123!'), isNull);
      expect(AppValidators.validatePassword('Secret#99'), isNull);
    });
  });

  group('AuthService Tests', () {
    test('Register user, duplicate detection, and login flow', () async {
      final regResult = await AuthService.register(
        name: 'Lee',
        email: 'lee@test.com',
        password: 'Pass123!',
      );
      expect(regResult.success, isTrue);
      expect(regResult.user?.name, 'Lee');

      // Duplicate registration should fail
      final dupResult = await AuthService.register(
        name: 'Lee Duplicate',
        email: 'lee@test.com',
        password: 'Pass123!',
      );
      expect(dupResult.success, isFalse);
      expect(dupResult.message, contains('already exists'));

      // Non-existing user login should fail
      final notFoundResult = await AuthService.signIn(
        email: 'nonexistent@test.com',
        password: 'Pass123!',
      );
      expect(notFoundResult.success, isFalse);
      expect(notFoundResult.message, contains('No account found'));

      // Wrong password should fail
      final wrongPassResult = await AuthService.signIn(
        email: 'lee@test.com',
        password: 'WrongPassword!',
      );
      expect(wrongPassResult.success, isFalse);
      expect(wrongPassResult.message, contains('Incorrect password'));

      // Correct credentials should succeed
      final loginResult = await AuthService.signIn(
        email: 'lee@test.com',
        password: 'Pass123!',
      );
      expect(loginResult.success, isTrue);
      expect(AuthService.currentUser?.name, 'Lee');
    });
  });

  group('Dashboard Flow Tests', () {
    testWidgets('Signing up with Lee navigates to Dashboard and displays greeting with Lee', (WidgetTester tester) async {
      await tester.pumpWidget(const TaskyApp());

      // On Welcome screen -> tap Get Started
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // On Sign In -> tap Sign Up
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Verify empty fields by default (no automatic email/name)
      expect(find.widgetWithText(TextFormField, 'Enter your name'), findsOneWidget);

      // Enter valid credentials
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter your name'), 'Lee');
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter your email'), 'lee.new@test.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter your password'), 'Secret#123');

      // Tap Sign Up button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pumpAndSettle();

      // Verify navigated to Dashboard and shows Lee greeting
      expect(find.textContaining('Lee'), findsWidgets);
      expect(find.textContaining('Let’s make a'), findsOneWidget);

      // Verify bottom navigation icons exist
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);

      // Verify "In Progress" section is kept
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Application Design'), findsOneWidget);

      // Verify "Here is what's happening" and "Task overview" are removed
      expect(find.textContaining("what's happening"), findsNothing);
      expect(find.text('Task Overview'), findsNothing);
    });
  });
}
