import 'package:flutter/material.dart';
import 'lib/screens/custom_splash_screen.dart';

void main() {
  runApp(const CustomSplashTestApp());
}

class CustomSplashTestApp extends StatelessWidget {
  const CustomSplashTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom Splash Screen Test',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const CustomSplashScreen(),
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
              'Custom Splash Screen Test Successful!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your Canva design integration is ready!',
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

