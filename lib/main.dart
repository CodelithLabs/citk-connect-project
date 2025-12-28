import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:citk_connect/app/routing/app_router.dart'; // Ensure this import exists

void main() {
  runApp(const App());
}

// 1. Change to ConsumerWidget
class App extends ConsumerWidget {
  const App({super.key});

  @override
  // 2. Add 'WidgetRef ref' parameter
  Widget build(BuildContext context, WidgetRef ref) {
    // 3. Watch the router provider
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      routerConfig: router,
      title: 'CITK Connect',
      // ... rest of your code
    );
  }
}