import 'package:flutter/material.dart';
import 'lib/screens/splash_screen.dart';

void main() {
  runApp(const SplashTestApp());
}

class SplashTestApp extends StatelessWidget {
  const SplashTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Splash Screen Test',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const SplashScreen(),
      routes: {
        '/auth': (context) => const TestAuthScreen(),
      },
    );
  }
}

class TestAuthScreen extends StatelessWidget {
  const TestAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            Text(
              'Splash Screen Test Successful!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'The splash screen animations completed and navigated correctly.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/');
              },
              child: const Text('Test Again'),
            ),
          ],
        ),
      ),
    );
  }
}

