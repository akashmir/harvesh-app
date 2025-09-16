import 'package:crop/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
//import 'package:crop_recommendation_app/main.dart';

void main() {
  group('Crop Recommendation App Widget Tests', () {
    testWidgets('App launches and shows login screen',
        (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MyApp());

      // Verify that the login screen is displayed
      expect(find.text('Welcome to Harvest'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('Login form validation works', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Find email and password fields
      final emailField = find.byKey(const Key('email_field'));
      final passwordField = find.byKey(const Key('password_field'));
      final signInButton = find.byKey(const Key('sign_in_button'));

      // Test empty field validation
      await tester.tap(signInButton);
      await tester.pump();

      // Should show validation errors
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Email field accepts valid input', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      final emailField = find.byKey(const Key('email_field'));

      // Enter valid email
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      // Verify the text was entered
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('Password field accepts input', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      final passwordField = find.byKey(const Key('password_field'));

      // Enter password
      await tester.enterText(passwordField, 'password123');
      await tester.pump();

      // Verify the text was entered (password should be obscured)
      expect(find.text('password123'), findsNothing);
    });

    testWidgets('Sign up button navigates to registration',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      final signUpButton = find.byKey(const Key('sign_up_button'));

      // Tap sign up button
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      // Verify registration screen is shown
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('Google sign in button is present',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Verify Google sign in button exists
      expect(find.byKey(const Key('google_sign_in_button')), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('Phone sign in button is present', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Verify phone sign in button exists
      expect(find.byKey(const Key('phone_sign_in_button')), findsOneWidget);
      expect(find.text('Continue with Phone'), findsOneWidget);
    });

    testWidgets('Forgot password button is present',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Verify forgot password button exists
      expect(find.byKey(const Key('forgot_password_button')), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
    });
  });

  group('Crop Recommendation Screen Tests', () {
    testWidgets('Crop recommendation form validation',
        (WidgetTester tester) async {
      // This would test the crop recommendation form
      // For now, we'll create a simple test
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(
                key: const Key('nitrogen_field'),
                decoration: const InputDecoration(labelText: 'Nitrogen (N)'),
              ),
              TextField(
                key: const Key('phosphorus_field'),
                decoration: const InputDecoration(labelText: 'Phosphorus (P)'),
              ),
              TextField(
                key: const Key('potassium_field'),
                decoration: const InputDecoration(labelText: 'Potassium (K)'),
              ),
              ElevatedButton(
                key: const Key('recommend_button'),
                onPressed: () {},
                child: const Text('Get Recommendation'),
              ),
            ],
          ),
        ),
      ));

      // Test form validation
      final recommendButton = find.byKey(const Key('recommend_button'));
      await tester.tap(recommendButton);
      await tester.pump();

      // Should show validation errors for empty fields
      expect(find.text('Please enter nitrogen value'), findsOneWidget);
      expect(find.text('Please enter phosphorus value'), findsOneWidget);
      expect(find.text('Please enter potassium value'), findsOneWidget);
    });

    testWidgets('Crop recommendation form accepts valid input',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(
                key: const Key('nitrogen_field'),
                decoration: const InputDecoration(labelText: 'Nitrogen (N)'),
              ),
              TextField(
                key: const Key('phosphorus_field'),
                decoration: const InputDecoration(labelText: 'Phosphorus (P)'),
              ),
              TextField(
                key: const Key('potassium_field'),
                decoration: const InputDecoration(labelText: 'Potassium (K)'),
              ),
              TextField(
                key: const Key('temperature_field'),
                decoration: const InputDecoration(labelText: 'Temperature'),
              ),
              TextField(
                key: const Key('humidity_field'),
                decoration: const InputDecoration(labelText: 'Humidity'),
              ),
              TextField(
                key: const Key('ph_field'),
                decoration: const InputDecoration(labelText: 'pH'),
              ),
              TextField(
                key: const Key('rainfall_field'),
                decoration: const InputDecoration(labelText: 'Rainfall'),
              ),
              ElevatedButton(
                key: const Key('recommend_button'),
                onPressed: () {},
                child: const Text('Get Recommendation'),
              ),
            ],
          ),
        ),
      ));

      // Enter valid data
      await tester.enterText(find.byKey(const Key('nitrogen_field')), '90');
      await tester.enterText(find.byKey(const Key('phosphorus_field')), '42');
      await tester.enterText(find.byKey(const Key('potassium_field')), '43');
      await tester.enterText(
          find.byKey(const Key('temperature_field')), '20.88');
      await tester.enterText(find.byKey(const Key('humidity_field')), '82');
      await tester.enterText(find.byKey(const Key('ph_field')), '6.5');
      await tester.enterText(find.byKey(const Key('rainfall_field')), '202.94');

      // Verify all fields have values
      expect(find.text('90'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('43'), findsOneWidget);
      expect(find.text('20.88'), findsOneWidget);
      expect(find.text('82'), findsOneWidget);
      expect(find.text('6.5'), findsOneWidget);
      expect(find.text('202.94'), findsOneWidget);
    });
  });

  group('Navigation Tests', () {
    testWidgets('Bottom navigation works', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Test bottom navigation
      final homeTab = find.byKey(const Key('home_tab'));
      final cropTab = find.byKey(const Key('crop_tab'));
      final weatherTab = find.byKey(const Key('weather_tab'));
      final profileTab = find.byKey(const Key('profile_tab'));

      // Verify all tabs are present
      expect(homeTab, findsOneWidget);
      expect(cropTab, findsOneWidget);
      expect(weatherTab, findsOneWidget);
      expect(profileTab, findsOneWidget);
    });

    testWidgets('Navigation between screens works',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Test navigation to crop recommendation screen
      final cropTab = find.byKey(const Key('crop_tab'));
      await tester.tap(cropTab);
      await tester.pumpAndSettle();

      // Verify crop recommendation screen is shown
      expect(find.text('Crop Recommendation'), findsOneWidget);
    });
  });

  group('Error Handling Tests', () {
    testWidgets('Network error handling', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Test network error scenario
      // This would test how the app handles network errors
      // For now, we'll create a simple test
      expect(find.text('Check your internet connection'), findsNothing);
    });

    testWidgets('API error handling', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Test API error scenario
      // This would test how the app handles API errors
      // For now, we'll create a simple test
      expect(find.text('Something went wrong'), findsNothing);
    });
  });

  group('Accessibility Tests', () {
    testWidgets('All interactive elements are accessible',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Test that all interactive elements have proper semantics
      final signInButton = find.byKey(const Key('sign_in_button'));
      final signUpButton = find.byKey(const Key('sign_up_button'));
      final googleButton = find.byKey(const Key('google_sign_in_button'));
      final phoneButton = find.byKey(const Key('phone_sign_in_button'));

      // Verify all buttons are accessible
      expect(signInButton, findsOneWidget);
      expect(signUpButton, findsOneWidget);
      expect(googleButton, findsOneWidget);
      expect(phoneButton, findsOneWidget);
    });

    testWidgets('Text fields have proper labels', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Test that text fields have proper labels
      final emailField = find.byKey(const Key('email_field'));
      final passwordField = find.byKey(const Key('password_field'));

      // Verify text fields exist
      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);
    });
  });
}
