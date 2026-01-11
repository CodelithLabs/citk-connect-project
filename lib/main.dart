import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:citk_connect/firebase_options.dart';
import 'package:citk_connect/app/routing/app_router.dart';
import 'package:citk_connect/app/routing/settings_provider.dart';
import 'package:citk_connect/app/config/env_config.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 🔧 GLOBAL PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

final onboardingStateProvider = StateProvider<bool>((ref) => false);
final appInitializationProvider = StateProvider<bool>((ref) => false);

// Future: Add feature flags, analytics, crashlytics providers

// Track Firebase initialization status for error logging
bool _firebaseInitialized = false;

// ═══════════════════════════════════════════════════════════════════════════
// 🚀 MAIN ENTRY POINT (Production-Grade Error Handling)
// ═══════════════════════════════════════════════════════════════════════════

void main() async {
  // ─────────────────────────────────────────────────────────────────────────
  // 🛡️ CRITICAL: Global Error Handling
  // ─────────────────────────────────────────────────────────────────────────
  await runZonedGuarded(
    () async {
      try {
        // 1️⃣ Initialize Flutter bindings
        WidgetsFlutterBinding.ensureInitialized();

        // 2️⃣ Configure System UI
        await _configureSystemUI();

        // 3️⃣ Initialize Firebase with circuit breaker
        try {
          await _initializeFirebaseWithRetry();
          _firebaseInitialized = true;
        } catch (e) {
          // ⚠️ Firebase Fallback: App continues in degraded mode
          developer.log('Firebase init failed. Running in degraded mode.',
              error: e);
        }

        // 4️⃣ Initialize SharedPreferences
        final prefs = await _initializeSharedPreferences();

        // 5️⃣ Load onboarding state
        final seenOnboarding = _getOnboardingState(prefs);

        // ─────────────────────────────────────────────────────────────────────────
        // 🐛 FLUTTER FRAMEWORK ERROR HANDLER
        // ─────────────────────────────────────────────────────────────────────────
        FlutterError.onError = (FlutterErrorDetails details) {
          FlutterError.presentError(details);
          _logError('Flutter Error', details.exception, details.stack);

          if (!kDebugMode &&
              EnvConfig.enableCrashlytics &&
              _firebaseInitialized) {
            FirebaseCrashlytics.instance.recordFlutterError(details);
          }
        };

        // ─────────────────────────────────────────────────────────────────────────
        // 🕸️ PLATFORM DISPATCHER ERROR HANDLER
        // ─────────────────────────────────────────────────────────────────────────
        PlatformDispatcher.instance.onError = (error, stack) {
          _logError('Platform Error', error, stack);
          if (!kDebugMode &&
              EnvConfig.enableCrashlytics &&
              _firebaseInitialized) {
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          }
          return true; // Mark as handled
        };

        // 6️⃣ Run app with dependency injection
        runApp(
          ProviderScope(
            overrides: [
              onboardingStateProvider.overrideWith((ref) => seenOnboarding),
              appInitializationProvider.overrideWith((ref) => true),
              sharedPreferencesProvider.overrideWithValue(prefs),
            ],
            child: const MyApp(),
          ),
        );
      } catch (error, stackTrace) {
        _handleFatalError(error, stackTrace);
      }
    },
    (error, stackTrace) {
      // Catches async errors that escape try-catch
      _handleFatalError(error, stackTrace);
    },
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔧 INITIALIZATION FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════

Future<void> _configureSystemUI() async {
  try {
    // Lock to portrait mode (comment out if landscape needed)
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // System UI styling
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0F1115),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _logInfo('System UI configured');
  } catch (e, stack) {
    _logError('System UI config failed', e, stack);
    // Non-critical, continue
  }
}

/// Initialize Firebase with retry logic and circuit breaker
Future<void> _initializeFirebaseWithRetry() async {
  const maxRetries = 3;
  const retryDelay = Duration(seconds: 2);
  int retryCount = 0;

  while (retryCount < maxRetries) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Firebase initialization timeout');
        },
      );

      _logInfo('Firebase initialized successfully');
      return;
    } catch (e, stack) {
      retryCount++;
      _logError(
        'Firebase init failed (attempt $retryCount/$maxRetries)',
        e,
        stack,
      );

      if (retryCount >= maxRetries) {
        // CRITICAL: Firebase failed after retries
        _logError('Firebase initialization failed permanently', e, stack);

        // Rethrow to trigger degraded mode in main()
        rethrow;
      }

      await Future.delayed(retryDelay);
    }
  }
}

Future<SharedPreferences> _initializeSharedPreferences() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    _logInfo('SharedPreferences initialized');
    return prefs;
  } catch (e, stack) {
    _logError('SharedPreferences failed', e, stack);

    _logInfo('Using in-memory SharedPreferences fallback');
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    return await SharedPreferences.getInstance();
  }
}

bool _getOnboardingState(SharedPreferences? prefs) {
  try {
    if (prefs == null) return false;
    final seen = prefs.getBool('seenOnboarding') ?? false;
    _logInfo('Onboarding state: $seen');
    return seen;
  } catch (e, stack) {
    _logError('Failed to read onboarding state', e, stack);
    return false; // Safe default
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🐛 ERROR HANDLING & LOGGING
// ═══════════════════════════════════════════════════════════════════════════

void _handleFatalError(Object error, StackTrace stackTrace) {
  _logError('FATAL ERROR', error, stackTrace);

  // Show graceful error screen
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _FatalErrorScreen(error: error.toString()),
    ),
  );
}

void _logError(String message, Object error, StackTrace? stack) {
  if (kDebugMode) {
    developer.log(
      '❌ $message',
      error: error,
      stackTrace: stack,
      name: 'CITK_ERROR',
    );
  } else if (EnvConfig.enableCrashlytics && _firebaseInitialized) {
    FirebaseCrashlytics.instance.recordError(error, stack, reason: message);
  }
}

void _logInfo(String message) {
  if (kDebugMode) {
    developer.log('✅ $message', name: 'CITK_INFO');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🎨 MAIN APP WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🛡️ OFFLINE MODE / ERROR SCREEN
    if (!_firebaseInitialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _FatalErrorScreen(
            error: 'Connection Failed.\nUnable to connect to servers.'),
      );
    }

    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsControllerProvider);
    final themeMode = settings.themeMode;

    return MaterialApp.router(
      title: 'CITK Connect',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      routerConfig: router,

      // ─────────────────────────────────────────────────────────────────────
      // ☀️ LIGHT THEME
      // ─────────────────────────────────────────────────────────────────────
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4285F4),
          brightness: Brightness.light,
          primary: const Color(0xFF1976D2), // Darker blue for contrast
          secondary: const Color(0xFF388E3C),
          surface: const Color(0xFFFFFFFF),
          error: const Color(0xFFB00020),
        ),

        // Typography (Google Fonts - Inter)
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.light().textTheme,
        ),

        // Input Fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F3F4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF1976D2),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFB00020),
              width: 1,
            ),
          ),
        ),

        // Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),

        // Cards
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFFFF),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // App Bar
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F9FA),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),

        // Snackbar
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // ─────────────────────────────────────────────────────────────────────
      // 🎨 DARK THEME (Production-ready)
      // ─────────────────────────────────────────────────────────────────────
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1115),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4285F4),
          brightness: Brightness.dark,
          primary: const Color(0xFF8AB4F8),
          secondary: const Color(0xFF81C995),
          surface: const Color(0xFF1E1E1E),
          error: const Color(0xFFCF6679),
        ),

        // Typography (Google Fonts - Inter)
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),

        // Input Fields
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFCF6679),
              width: 1,
            ),
          ),
        ),

        // Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),

        // Cards
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // App Bar
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F1115),
          elevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        ),

        // Snackbar
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 💀 FATAL ERROR SCREEN (Last resort)
// ═══════════════════════════════════════════════════════════════════════════

class _FatalErrorScreen extends StatelessWidget {
  final String error;

  const _FatalErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCF6679).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Color(0xFFCF6679),
                    size: 80,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'App Failed to Start',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  kDebugMode
                      ? error
                      : 'Something went wrong. Please restart the app.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // Attempt to restart (platform-specific)
                    SystemNavigator.pop(); // Exit app
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Exit App'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8AB4F8),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
