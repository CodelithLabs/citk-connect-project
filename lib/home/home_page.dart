import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome',
            ),
            SizedBox(height: 16),
            Text(
              'You are an early access user.',
            ),
            SizedBox(height: 16),
            Text(
              'This app is under active development.',
            ),
          ],
        ),
      ),
    );
  }
}
