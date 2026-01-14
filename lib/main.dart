import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:citk_connect/firebase_options.dart';
import 'package:citk_connect/app/routing/app_router.dart';
import 'package:citk_connect/app/routing/navigator_key.dart';
import 'package:citk_connect/app/routing/settings_provider.dart';
import 'package:citk_connect/app/config/env_config.dart';
import 'package:citk_connect/auth/services/onboarding_service.dart';
import 'package:citk_connect/app/config/feature_flags.dart';
import 'package:citk_connect/app/utils/firestore_seeder.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 🔧 GLOBAL PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

final onboardingStateProvider = StateProvider<bool>((ref) => false);
final appInitializationProvider = StateProvider<bool>((ref) => false);

// Future: Add feature flags, analytics, crashlytics providers

// Track initialization status
enum AppStatus { loading, success, error }

final ValueNotifier<AppStatus> _appStatus = ValueNotifier(AppStatus.loading);

// ═══════════════════════════════════════════════════════════════════════════
// 🕒 WORKMANAGER CONFIG
// ═══════════════════════════════════════════════════════════════════════════
const String updateWidgetTask = "updateWidgetTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == updateWidgetTask) {
      // TODO: Fetch actual data from API/Firebase here
      await updateAttendanceWidget("95%");
    }
    return Future.value(true);
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// ☁️ FIREBASE MESSAGING BACKGROUND HANDLER
// ═══════════════════════════════════════════════════════════════════════════
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (message.data.containsKey('attendance')) {
    await updateAttendanceWidget(message.data['attendance']);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 📱 HOME WIDGET BACKGROUND CALLBACK
// ═══════════════════════════════════════════════════════════════════════════

/// Helper to update the widget from anywhere (Foreground or Background Service)
@pragma('vm:entry-point')
Future<void> updateAttendanceWidget(String value) async {
  try {
    // 1. Save data to SharedPreferences (accessible by Native Android code)
    await HomeWidget.saveWidgetData('attendance', value);

    // 2. Trigger the native update
    await HomeWidget.updateWidget(
      name: 'AttendanceWidgetProvider',
      iOSName: 'AttendanceWidget',
    );
    developer.log('Widget updated to: $value');
  } catch (e) {
    developer.log('Failed to update widget', error: e);
  }
}

@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  // Check if triggered by the refresh button
  if (uri?.host == 'refresh') {
    await updateAttendanceWidget('Loading...');

    // Simulate network fetch (Replace with actual API call)
    await Future.delayed(const Duration(seconds: 1));

    await updateAttendanceWidget('92%');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🚀 MAIN ENTRY POINT (Production-Grade Error Handling)
// ═══════════════════════════════════════════════════════════════════════════

void main() async {
  // ─────────────────────────────────────────────────────────────────────────
  // 🛡️ CRITICAL: Global Error Handling
  // ─────────────────────────────────────────────────────────────────────────
  // 1️⃣ Initialize Flutter bindings (Root Zone)
  WidgetsFlutterBinding.ensureInitialized();

  // 2️⃣ Configure System UI
  await _configureSystemUI();

  // 3️⃣ Initialize Hive (Fix for HiveError)
  await Hive.initFlutter();

  // 4️⃣ Initialize WorkManager
  Workmanager().initialize(
    callbackDispatcher,
  );

  // Register Periodic Task (Every 15 minutes)
  Workmanager().registerPeriodicTask(
    "com.citk.connect.widget.update",
    updateWidgetTask,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // 🐛 FLUTTER FRAMEWORK ERROR HANDLER
  // ─────────────────────────────────────────────────────────────────────────
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _logError('Flutter Error', details.exception, details.stack);

    if (!kDebugMode &&
        EnvConfig.enableCrashlytics &&
        _appStatus.value == AppStatus.success) {
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
        _appStatus.value == AppStatus.success) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    return true; // Mark as handled
  };

  try {
    // 4️⃣ Start Firebase Init (Background - DO NOT AWAIT)
    _initializeFirebaseWithRetry().then((_) async {
      _appStatus.value = AppStatus.success;

      // ☁️ Setup Firebase Messaging
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.data.containsKey('attendance')) {
          updateAttendanceWidget(message.data['attendance']);
        }
      });

      // Initialize Home Widget
      try {
        HomeWidget.setAppGroupId('group.citk.connect.widget');
        HomeWidget.registerInteractivityCallback(backgroundCallback);
      } catch (e) {
        developer.log('HomeWidget init failed', error: e);
      }

      // 6️⃣ Seed Data (Debug Only) - Moved here to ensure Firebase is initialized
      if (kDebugMode) {
        await FirestoreSeeder.seedNotices();
      }
    }).catchError((e) {
      developer.log('Firebase init failed', error: e);
      _appStatus.value = AppStatus.error;
    });

    // 5️⃣ Initialize SharedPreferences
    final prefs = await _initializeSharedPreferences();

    // 7️⃣ Run app with dependency injection
    runApp(
      ProviderScope(
        overrides: [
          appInitializationProvider.overrideWith((ref) => true),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        // 🛡️ Bootstrap: Show loading or error before mounting MyApp
        child: ValueListenableBuilder<AppStatus>(
          valueListenable: _appStatus,
          builder: (context, status, _) {
            if (status == AppStatus.loading) {
              return const MaterialApp(
                debugShowCheckedModeBanner: false,
                home: Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            if (status == AppStatus.error) {
              return const MaterialApp(
                debugShowCheckedModeBanner: false,
                home: _FatalErrorScreen(
                    error: 'Connection Failed.\nUnable to connect to servers.'),
              );
            }
            return const MyApp();
          },
        ),
      ),
    );
  } catch (error, stackTrace) {
    _handleFatalError(error, stackTrace);
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});
  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // 1. Register lifecycle observer to detect when user returns
    WidgetsBinding.instance.addObserver(this);
    // Initialize Onboarding Service
    ref.read(onboardingServiceProvider.notifier).init();

    // Check permissions on app startup
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkNotificationPermission());
  }

  @override
  void dispose() {
    // 2. Remove observer to prevent memory leaks
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 3. Detect when app resumes (user returns from Settings)
    if (state == AppLifecycleState.resumed) {
      _checkNotificationPermission();
    }
  }

  /// Re-checks permission status when user returns to the app
  Future<void> _checkNotificationPermission() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    final prefs = ref.read(sharedPreferencesProvider);
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _logInfo('User granted notification permissions manually.');
      // Optional: Trigger a widget update now that we have permission
      updateAttendanceWidget("Syncing..."); 
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      // Check "Don't show again" preference
      if (prefs.getBool(kPrefHidePermissionDialog) ?? false) return;

      // 🛑 Automatically show dialog if permanently denied
      if (rootNavigatorKey.currentContext != null) {
        PermissionDeniedDialog.show(rootNavigatorKey.currentContext!, prefs);
      }
    } else {
      _logInfo('Notification permission is still ${settings.authorizationStatus}.');
    }
  }

  @override
  Widget build(BuildContext context) {
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
// 🛑 CUSTOM PERMISSION DIALOG (Gen Z Style)
// ═══════════════════════════════════════════════════════════════════════════

class PermissionDeniedDialog extends ConsumerWidget {
  static bool _isShown = false;
  final SharedPreferences prefs;

  const PermissionDeniedDialog({super.key, required this.prefs});

  /// Helper method to show this dialog easily
  static Future<void> show(BuildContext context, SharedPreferences prefs) async {
    if (_isShown) return;
    _isShown = true;
    await showDialog(
      context: context,
      builder: (context) => PermissionDeniedDialog(prefs: prefs),
    ).then((_) => _isShown = false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🚩 Check Feature Flag
    final isGenZ = ref.watch(featureFlagsProvider).isGenZDialogEnabled;

    // 🔽 Fallback: Standard Material Dialog
    if (!isGenZ) {
      return AlertDialog(
        title: const Text("Permission Required"),
        content: const Text(
            "To see your attendance on the home screen widget, we need notification permissions."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Maybe Later"),
          ),
          TextButton(
            onPressed: () async {
              await prefs.setBool(kPrefHidePermissionDialog, true);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Don't ask again"),
          ),
          TextButton(
            onPressed: () => AppSettings.openAppSettings(type: AppSettingsType.notification),
            child: const Text("Open Settings"),
          ),
        ],
      );
    }

    // ✨ Gen Z Style (Glassmorphism)
    return Dialog(
      backgroundColor: Colors.transparent, // Glassmorphism base
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF181B21).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF4285F4).withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_off_outlined, color: Color(0xFFCF6679), size: 48),
            const SizedBox(height: 16),
            const Text(
              "Don't Miss Out",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "To see your attendance on the home screen widget, we need notification permissions.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // 🚀 Direct link to Notification Settings
                AppSettings.openAppSettings(type: AppSettingsType.notification);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4285F4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Open Settings"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Maybe Later", style: TextStyle(color: Colors.white38)),
            ),
            TextButton(
              onPressed: () async {
                await prefs.setBool(kPrefHidePermissionDialog, true);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Don't ask again", style: TextStyle(color: Colors.white24, fontSize: 12)),
            ),
          ],
        ),
      ),
    )
    .animate()
    .fade(duration: 400.ms)
    .scale(duration: 400.ms, curve: Curves.easeOutBack);
  }
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

      // Request Notification Permissions (Required for Android 13+)
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _logInfo(
            '❌ Notification permission denied. Falling back to periodic WorkManager updates.');
        // Note: Real-time updates via FCM will not work, but WorkManager will still update every 15m.
      } else {
        _logInfo(
            'Notification permission granted: ${settings.authorizationStatus}');
      }

      // Initialize Feature Flags (Remote Config)
      await FeatureFlags().initialize();

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
    // 🛡️ Prevent app from hanging if storage is slow
    final prefs = await SharedPreferences.getInstance().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        throw TimeoutException('SharedPreferences init timeout');
      },
    );
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
  } else if (EnvConfig.enableCrashlytics &&
      _appStatus.value == AppStatus.success) {
    FirebaseCrashlytics.instance.recordError(error, stack, reason: message);
  }
}

void _logInfo(String message) {
  if (kDebugMode) {
    developer.log('✅ $message', name: 'CITK_INFO');
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
