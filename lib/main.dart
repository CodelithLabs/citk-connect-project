import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:citk_connect/firebase_options.dart';
import 'package:citk_connect/app/routing/app_router.dart';

void main() async {
  // 1️⃣ Ensure Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // 2️⃣ Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3️⃣ Run App with Riverpod
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Use ONE router provider (choose this name in app_router.dart)
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'CITK Connect',
      debugShowCheckedModeBanner: false,

      // 🔥 Force Dark Mode (Hackathon / Premium feel)
      themeMode: ThemeMode.dark,

      routerConfig: router,

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,

        scaffoldBackgroundColor: const Color(0xFF121212),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4285F4), // Google Blue
          brightness: Brightness.dark,
          primary: const Color(0xFF8AB4F8),
          surface: const Color(0xFF1E1E1E),
        ),

        // ✨ Google Fonts (Inter)
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),

        // 🧱 Professional Input Fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF8AB4F8),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
