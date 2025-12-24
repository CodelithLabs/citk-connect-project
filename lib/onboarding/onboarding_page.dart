import 'package:citk_connect/onboarding/widgets/onboarding_shell.dart';
import 'package:flutter/material.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingShell(
      children: [
        _OnboardingPage(
          title: 'Welcome to CITK-CONNECT',
        ),
        _OnboardingPage(
          title: 'Open Innovation for the CITK community',
        ),
        _OnboardingPage(
          title: 'Built with Google Technologies',
        ),
        _OnboardingPage(
          title: 'Ready to begin?',
        ),
      ],
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
