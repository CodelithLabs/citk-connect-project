import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Environment configuration for the app
class EnvConfig {
  // ✅ Environment Detection
  static bool get isProduction => kReleaseMode;
  static bool get isDevelopment => kDebugMode;
  static bool get isProfile => kProfileMode;

  // ✅ API Keys
  // PRO TIP: These are injected at build time using --dart-define
  // They can be overridden by Firebase Remote Config at runtime.
  static String _geminiApiKey = const String.fromEnvironment('GEMINI_API_KEY');
  static String get geminiApiKey => _geminiApiKey;

  static String _googleMapsKey =
      const String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  static String get googleMapsKey => _googleMapsKey;

  static String _weatherApiKey =
      const String.fromEnvironment('WEATHER_API_KEY');
  static String get weatherApiKey => _weatherApiKey;

  // ✅ Feature Flags (Can be overridden by Firebase Remote Config)
  static bool get enableBusTracking =>
      _remoteConfig?.getBool('enable_bus_tracking') ?? true;
  static bool get enableAIAssistant =>
      _remoteConfig?.getBool('enable_ai_assistant') ?? true;
  static bool get enableWeatherWidget =>
      _remoteConfig?.getBool('enable_weather_widget') ?? false;
  static bool get enableAnalytics =>
      _remoteConfig?.getBool('enable_analytics') ?? false;
  static bool get enableCrashReporting =>
      _remoteConfig?.getBool('enable_crash_reporting') ?? false;

  // ✅ Rate Limits
  static const int maxAiQueriesPerDay = 50;
  static const Duration aiRequestCooldown = Duration(seconds: 2);
  static const int maxBusUpdatesPerMinute = 4;

  // ✅ Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration authTimeout = Duration(seconds: 60);

  // ✅ App Metadata
  static const String appName = "CITK Connect";
  static const String appVersion = "1.0.0+1";
  static const String buildNumber = "1";

  // ✅ URLs
  static const String supportEmail = "support@citk.ac.in";
  static const String websiteUrl = "https://cit.ac.in";
  static const String privacyPolicyUrl = "https://cit.ac.in/privacy";
  static const String termsOfServiceUrl = "https://cit.ac.in/terms";

  // ✅ Logging Configuration
  static bool get enableLogging => isDevelopment;
  static bool get enableVerboseLogging => isDevelopment;

  static bool get enableCrashlytics => isProduction;

  static FirebaseRemoteConfig? _remoteConfig;

  /// Initialize environment-specific settings
  static Future<void> initialize() async {
    if (isDevelopment) {
      print("[EnvConfig] Running in DEVELOPMENT mode");
      print("[EnvConfig] Logging: ENABLED");
    } else if (isProduction) {
      print("[EnvConfig] Running in PRODUCTION mode");
      print("[EnvConfig] Logging: DISABLED");
    }

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: isDevelopment
            ? const Duration(minutes: 5)
            : const Duration(hours: 12),
      ));

      await _remoteConfig!.setDefaults({
        'enable_bus_tracking': true,
        'enable_ai_assistant': true,
        'enable_weather_widget': false,
        'enable_analytics': false,
        'enable_crash_reporting': false,
      });

      await _remoteConfig!.fetchAndActivate();

      // Load keys from Remote Config if available
      if (_remoteConfig!.getString('GEMINI_API_KEY').isNotEmpty) {
        _geminiApiKey = _remoteConfig!.getString('GEMINI_API_KEY');
      }
      if (_remoteConfig!.getString('GOOGLE_MAPS_API_KEY').isNotEmpty) {
        _googleMapsKey = _remoteConfig!.getString('GOOGLE_MAPS_API_KEY');
      }
      if (_remoteConfig!.getString('WEATHER_API_KEY').isNotEmpty) {
        _weatherApiKey = _remoteConfig!.getString('WEATHER_API_KEY');
      }
    } catch (e) {
      print("[EnvConfig] Failed to fetch Remote Config: $e");
    }

    if (enableAnalytics) {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    }

    if (enableCrashReporting && !kIsWeb) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    }
  }

  /// Get API key for a specific service (with fallback)
  static String getApiKey(String service) {
    switch (service) {
      case 'gemini':
        return geminiApiKey;
      case 'maps':
        return googleMapsKey;
      case 'weather':
        return weatherApiKey;
      default:
        throw Exception('Unknown API service: $service');
    }
  }

  /// Check if a feature is enabled
  static bool isFeatureEnabled(String feature) {
    switch (feature) {
      case 'busTracking':
        return enableBusTracking;
      case 'aiAssistant':
        return enableAIAssistant;
      case 'weather':
        return enableWeatherWidget;
      case 'analytics':
        return enableAnalytics;
      case 'crashReporting':
        return enableCrashReporting;
      default:
        return false;
    }
  }
}
