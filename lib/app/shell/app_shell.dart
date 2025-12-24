import 'package:citk_connect/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: child,
      bottomNavigationBar: const Footer(),
    );
  }
}
