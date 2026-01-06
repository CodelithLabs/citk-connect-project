import 'package:flutter/foundation.dart';

/// 🔐 ENVIRONMENT CONFIGURATION
///
/// Centralized, secure access to environment variables.
///
/// Sources supported:
/// 1. --dart-define (CI/CD, local dev)
/// 2. Firebase Remote Config (future)
/// 3. Platform secrets (future)
///
/// DESIGN GOALS:
/// - ❌ No hard-coded secrets
/// - ❌ No crashes in release
/// - ✅ Strict validation in debug
/// - ✅ Silent + safe in production
/// - ✅ Extensible without breaking API
///
/// Example:
/// flutter run --dart-define=GEMINI_API_KEY=AIza...
class EnvConfig {
  EnvConfig._(); // Prevent instantiation

  // ─────────────────────────────────────────────────────────────────────────
  // 🔑 RAW ENV VARIABLES (dart-define)
  // ─────────────────────────────────────────────────────────────────────────

  static const String _geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY');

  static const String _googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static const String _weatherApiKey =
      String.fromEnvironment('WEATHER_API_KEY');

  // ─────────────────────────────────────────────────────────────────────────
  // ✅ SAFE PUBLIC GETTERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Gemini AI API Key
  static String get geminiApiKey => _geminiApiKey;

  /// Google Maps API Key
  static String get googleMapsApiKey => _googleMapsApiKey;

  /// Weather API Key (optional)
  static String get weatherApiKey => _weatherApiKey;

  // ─────────────────────────────────────────────────────────────────────────
  // 🛡️ VALIDATION (Debug strict, Release safe)
  // ─────────────────────────────────────────────────────────────────────────

  /// Validates critical environment variables.
  ///
  /// DEBUG:
  /// - Logs detailed warnings
  /// - Helps catch misconfiguration early
  ///
  /// RELEASE:
  /// - Never crashes
  /// - Never logs secrets
  /// - Allows app to run (graceful degradation)
  static void validate() {
    if (kDebugMode) {
      _debugValidate();
    }
  }

  static void _debugValidate() {
    final missingKeys = <String>[];

    if (_geminiApiKey.isEmpty) {
      missingKeys.add('GEMINI_API_KEY');
    }

    if (_googleMapsApiKey.isEmpty) {
      missingKeys.add('GOOGLE_MAPS_API_KEY');
    }

    if (missingKeys.isNotEmpty) {
      debugPrint(
        '⚠️ [EnvConfig] Missing environment variables:\n'
        '→ ${missingKeys.join(', ')}\n\n'
        'ℹ️ Fix by running:\n'
        'flutter run --dart-define=KEY=VALUE\n\n'
        '⚠️ App will continue running in DEBUG mode.',
      );
    } else {
      debugPrint('✅ [EnvConfig] Environment validation passed');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 🔒 SECURITY HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns true if a secret exists (without exposing it)
  static bool hasSecret(String key) {
    switch (key) {
      case 'GEMINI_API_KEY':
        return _geminiApiKey.isNotEmpty;
      case 'GOOGLE_MAPS_API_KEY':
        return _googleMapsApiKey.isNotEmpty;
      case 'WEATHER_API_KEY':
        return _weatherApiKey.isNotEmpty;
      default:
        return false;
    }
  }

  /// Prevent accidental logging of secrets
  static String masked(String secret) {
    if (secret.isEmpty) return 'EMPTY';
    if (secret.length <= 6) return '***';
    return '${secret.substring(0, 3)}***${secret.substring(secret.length - 3)}';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 🚀 FUTURE EXTENSION POINTS (DO NOT REMOVE)
  // ─────────────────────────────────────────────────────────────────────────

  /// TODO: Load secrets from Firebase Remote Config
  /// static Future<void> loadFromRemoteConfig() async {}

  /// TODO: Inject secrets from secure storage / native keystore
  /// static Future<void> loadFromSecureStorage() async {}

  /// TODO: Environment switching (dev / staging / prod)
  /// static String get environment => const String.fromEnvironment('APP_ENV', defaultValue: 'prod');
}
