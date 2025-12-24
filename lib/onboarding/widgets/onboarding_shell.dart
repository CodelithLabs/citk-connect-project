import 'package:citk_connect/app/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingShell extends StatefulWidget {
  const OnboardingShell({super.key, required this.children});

  final List<Widget> children;

  @override
  State<OnboardingShell> createState() => _OnboardingShellState();
}

class _OnboardingShellState extends State<OnboardingShell> {
  final _controller = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _controller,
        children: widget.children,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_controller.page == widget.children.length - 1) {
            context.go('/');
          } else {
            _controller.nextPage(
              duration: AppDurations.fast,
              curve: AppCurves.primary,
            );
          }
        },
        child: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
