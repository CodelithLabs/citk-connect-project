import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:citk_connect/app/routing/app_router.dart';
import 'firebase_options.dart'; // Uncomment this line after running 'flutterfire configure'

void main() async {
  // 1. Initialize the Flutter Engine immediately
  // This is required before calling any platform channels (like Firebase)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase
  // Ideally, you should generate firebase_options.dart using 'flutterfire configure'
  // For now, this generic init works for Android/iOS auto-configuration.
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform, // Uncomment this once generated
      );

  // 3. Run the App wrapped in ProviderScope
  // This initializes the Riverpod state container.
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 4. Watch the router provider
    // This allows the router to update if your auth state changes (redirects)
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      // 5. Connect GoRouter
      routerConfig: goRouter,

      // 6. App Metadata & theming
      title: 'CITK Connect',
      debugShowCheckedModeBanner: false, // Clean UI for demos

      // Standard Material 3 Theme setup
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4), // Replace with your brand color
          brightness: Brightness.light,
        ),
      ),

      // Dark mode support (Good practice to have ready)
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system, // Respects user's system setting
    );
  }
}
