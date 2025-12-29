import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:citk_connect/app/routing/app_router.dart';
import 'firebase_options.dart'; 

void main() async {
  // 1. Initialize Flutter Engine
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Run App
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
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      routerConfig: goRouter,
      title: 'CITK Connect',
      debugShowCheckedModeBanner: false,
      
      // Force Dark Mode for the Hackathon/Premium feel
      themeMode: ThemeMode.dark, 
      
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212), // Premium Dark Grey
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4285F4), // Google Blue
          brightness: Brightness.dark,
          primary: const Color(0xFF8AB4F8), // Lighter Blue for Dark Mode
          surface: const Color(0xFF1E1E1E), // Card Surface
        ),
        // Google Typography
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        
        // Professional Input Fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF8AB4F8), width: 2),
          ),
        ),
      ),
    );
  }
}