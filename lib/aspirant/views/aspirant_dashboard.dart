import 'package:flutter/material.dart';

class AspirantDashboard extends StatelessWidget {
  const AspirantDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aspirant Dashboard'),
      ),
      body: const Center(
        child: Text('Aspirant Dashboard - Coming Soon'),
      ),
    );
  }
}