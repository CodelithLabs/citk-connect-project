import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:citk_connect/firebase_options.dart';
import 'package:citk_connect/app/routing/app_router.dart';
//import 'package:citk_connect/app/config/env_config.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 🔧 GLOBAL PROVIDERS & STATE
// ═══════════════════════════════════════════════════════════════════════════

/// Tracks if user has completed onboarding
/// Default: false (show onboarding)
final onboardingStateProvider = StateProvider<bool>((ref) => false);

/// Tracks app initialization status for splash/loading screens
final appInitializationProvider = StateProvider<bool>((ref) => false);

// TODO: Add feature flags provider when implementing A/B testing
// final featureFlagsProvider = StateProvider<Map<String, bool>>((ref) => {});

// TODO: Add analytics provider when implementing tracking
// final analyticsProvider = Provider<AnalyticsService>((ref) => AnalyticsService());

// TODO: Add crash reporting provider (Firebase Crashlytics)
// final crashlyticsProvider = Provider<FirebaseCrashlytics>((ref) => FirebaseCrashlytics.instance);

// ═══════════════════════════════════════════════════════════════════════════
// 🚀 MAIN ENTRY POINT
// ═══════════════════════════════════════════════════════════════════════════

void main() async {
  // ─────────────────────────────────────────────────────────────────────────
  // 🛡️ CRITICAL: Global Error Handling
  // ─────────────────────────────────────────────────────────────────────────
  await runZonedGuarded(
    () async {
      try {
        // 1️⃣ FLUTTER BINDINGS (Required before any async operations)
        WidgetsFlutterBinding.ensureInitialized();

        // 🔐 VALIDATE ENVIRONMENT (Check for API Keys)
        //EnvConfig.validate();

        // 2️⃣ SYSTEM UI CONFIGURATION (Lock orientation, system chrome)
        await _configureSystemUI();

        // 3️⃣ FIREBASE INITIALIZATION (With retry logic)
        await _initializeFirebase();

        // 4️⃣ SHARED PREFERENCES (With fallback)
        final prefs = await _initializeSharedPreferences();

        // 5️⃣ ONBOARDING STATE (Read from local storage)
        final seenOnboarding = _getOnboardingState(prefs);

        // TODO: Load feature flags from remote config
        // final featureFlags = await _loadFeatureFlags();

        // TODO: Initialize analytics
        // await _initializeAnalytics();

        // TODO: Initialize crash reporting
        // await _initializeCrashlytics();

        // 6️⃣ RUN APP with injected state
        runApp(
          ProviderScope(
            overrides: [
              onboardingStateProvider.overrideWith((ref) => seenOnboarding),
              appInitializationProvider.overrideWith((ref) => true),
              // TODO: Inject feature flags
              // featureFlagsProvider.overrideWith((ref) => featureFlags),
            ],
            child: MyApp(),
          ),
        );
      } catch (error, stackTrace) {
        _handleFatalError(error, stackTrace);
      }
    },
    (error, stackTrace) {
      // Catches errors that escape the try-catch (e.g., async errors)
      _handleFatalError(error, stackTrace);
    },
  );

  // ─────────────────────────────────────────────────────────────────────────
  // 🐛 FLUTTER FRAMEWORK ERROR HANDLER
  // ─────────────────────────────────────────────────────────────────────────
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _logError('Flutter Framework Error', details.exception, details.stack);

    // TODO: Send to crash reporting service
    // FirebaseCrashlytics.instance.recordFlutterError(details);
  };

  // ─────────────────────────────────────────────────────────────────────────
  // 🕸️ PLATFORM DISPATCHER ERROR HANDLER (Web support)
  // ─────────────────────────────────────────────────────────────────────────
  PlatformDispatcher.instance.onError = (error, stack) {
    _logError('Platform Dispatcher Error', error, stack);
    // TODO: Send to crash reporting
    return true; // Handled
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔧 INITIALIZATION FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════

/// Configure system UI (orientation, status bar, etc.)
Future<void> _configureSystemUI() async {
  try {
    // Lock to portrait mode (remove if landscape needed)
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // System UI overlay style (status bar, navigation bar)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF121212),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _logInfo('System UI configured successfully');
  } catch (e, stack) {
    _logError('Failed to configure System UI', e, stack);
    // Non-critical, continue app launch
  }
}

/// Initialize Firebase with retry logic
Future<void> _initializeFirebase() async {
  int retryCount = 0;
  const maxRetries = 3;
  const retryDelay = Duration(seconds: 2);

  while (retryCount < maxRetries) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _logInfo('Firebase initialized successfully');
      return;
    } catch (e, stack) {
      retryCount++;
      _logError(
        'Firebase initialization failed (attempt $retryCount/$maxRetries)',
        e,
        stack,
      );

      if (retryCount >= maxRetries) {
        // CRITICAL: Firebase failed, decide if app can continue
        // TODO: Show error screen or use offline mode
        rethrow;
      }

      await Future.delayed(retryDelay);
    }
  }
}

/// Initialize SharedPreferences with fallback
Future<SharedPreferences> _initializeSharedPreferences() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    _logInfo('SharedPreferences initialized successfully');
    return prefs;
  } catch (e, stack) {
    _logError('Failed to initialize SharedPreferences', e, stack);
    // TODO: Implement fallback storage (in-memory or Hive)
    rethrow;
  }
}

/// Get onboarding state with safe fallback
bool _getOnboardingState(SharedPreferences? prefs) {
  try {
    if (prefs == null) return false;
    final seen = prefs.getBool('seenOnboarding') ?? false;
    _logInfo('Onboarding state loaded: $seen');
    return seen;
  } catch (e, stack) {
    _logError('Failed to read onboarding state', e, stack);
    return false; // Default to showing onboarding on error
  }
}

// TODO: Load feature flags from Firebase Remote Config
// Future<Map<String, bool>> _loadFeatureFlags() async {
//   try {
//     final remoteConfig = FirebaseRemoteConfig.instance;
//     await remoteConfig.setConfigSettings(RemoteConfigSettings(
//       fetchTimeout: const Duration(seconds: 10),
//       minimumFetchInterval: const Duration(hours: 1),
//     ));
//     await remoteConfig.fetchAndActivate();
//     return {
//       'enable_new_feature': remoteConfig.getBool('enable_new_feature'),
//       'show_premium_banner': remoteConfig.getBool('show_premium_banner'),
//     };
//   } catch (e, stack) {
//     _logError('Failed to load feature flags', e, stack);
//     return {}; // Return empty map on failure
//   }
// }

// ═══════════════════════════════════════════════════════════════════════════
// 🐛 ERROR HANDLING & LOGGING
// ═══════════════════════════════════════════════════════════════════════════

void _handleFatalError(Object error, StackTrace stackTrace) {
  _logError('FATAL ERROR', error, stackTrace);

  // In production, show a graceful error screen
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
  }
  // TODO: Send to analytics/crash reporting in production
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
    // Watch router (with error handling in app_router.dart)
    final router = ref.watch(appRouterProvider);

    // TODO: Watch feature flags
    // final featureFlags = ref.watch(featureFlagsProvider);

    return MaterialApp.router(
      title: 'CITK Connect',
      debugShowCheckedModeBanner: false,

      // ─────────────────────────────────────────────────────────────────────
      // 🎨 THEME CONFIGURATION
      // ─────────────────────────────────────────────────────────────────────
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
          error: const Color(0xFFCF6679),
        ),

        // ✨ Typography (Google Fonts - Inter)
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),

        // 🧱 Input Field Styling
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

        // 🔘 Button Styling
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // 📦 Card Styling
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 2,
          shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(16),
          ),
        ),

        // 🎯 App Bar Styling
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
          centerTitle: true,
        ),
      ),

      // TODO: Add light theme when design is ready
      // theme: ThemeData(...),

      // ─────────────────────────────────────────────────────────────────────
      // 🌍 LOCALIZATION (TODO)
      // ─────────────────────────────────────────────────────────────────────
      // localizationsDelegates: [
      //   GlobalMaterialLocalizations.delegate,
      //   GlobalWidgetsLocalizations.delegate,
      // ],
      // supportedLocales: [
      //   const Locale('en', 'US'),
      //   const Locale('hi', 'IN'),
      // ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 💀 FATAL ERROR SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class _FatalErrorScreen extends StatelessWidget {
  final String error;

  const _FatalErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFCF6679),
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'Something went wrong',
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
                    : 'Please restart the app. If the problem persists, contact support.',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Add restart logic or support contact
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Restart App'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8AB4F8),
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
