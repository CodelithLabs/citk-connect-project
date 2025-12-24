import 'package:citk_connect/auth/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: _OnboardingView(),
    );
  }
}

class _OnboardingView extends HookConsumerWidget {
  const _OnboardingView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = PageController();

    final pages = [
      const _OnboardingPage(
        title: 'Welcome to CITK-CONNECT',
        description: 'An open innovation platform for the CITK community.',
      ),
      const _OnboardingPage(
        title: 'Powered by Google',
        description: 'Built with Flutter and Firebase, leveraging the best of Google\'s technology.',
      ),
      _OnboardingPage(
        title: 'Ready to Begin?',
        description: 'Sign in to start exploring.',
        child: ElevatedButton(
          onPressed: () => ref.read(authServiceProvider).signInWithGoogle(),
          child: const Text('Sign in with Google'),
        ),
      ),
    ];

    return Stack(
      children: [
        PageView(
          controller: pageController,
          children: pages,
        ),
        Positioned(
          top: 40,
          right: 20,
          child: TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Skip'),
          ),
        ),
      ],
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.title,
    required this.description,
    this.child,
  });

  final String title;
  final String description;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (child != null) ...[
            const SizedBox(height: 40),
            child!,
          ],
        ],
      ),
    );
  }
}
