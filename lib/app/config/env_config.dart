import 'package:flutter/foundation.dart';

/// Environment configuration for the app
/// TODO: Move sensitive keys to Firebase Remote Config or .env file
class EnvConfig {
  // ✅ Environment Detection
  static bool get isProduction => kReleaseMode;
  static bool get isDevelopment => kDebugMode;
  static bool get isProfile => kProfileMode;

  // ✅ API Keys (TEMPORARY - Move to secure storage)
  // TODO: Replace with Firebase Remote Config or flutter_dotenv
  static const String geminiApiKey = "AIzaSyCWKKqwxg20qZ1ygN50Gpeh4wKoz4ZZvw4";
  static const String googleMapsKey = "AIzaSyCCGy6iOdFSvq_Agq6QQP_FbwWmM4Q2pOc";
  static const String weatherApiKey = "YOUR_API_KEY"; // TODO: Get from OpenWeatherMap

  // ✅ Feature Flags (Can be overridden by Firebase Remote Config)
  static const bool enableBusTracking = true;
  static const bool enableAIAssistant = true;
  static const bool enableWeatherWidget = false; // No API key yet
  static const bool enableAnalytics = false; // TODO: Implement
  static const bool enableCrashReporting = false; // TODO: Implement

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

  /// Initialize environment-specific settings
  static Future<void> initialize() async {
    if (isDevelopment) {
      print("[EnvConfig] Running in DEVELOPMENT mode");
      print("[EnvConfig] Logging: ENABLED");
    } else if (isProduction) {
      print("[EnvConfig] Running in PRODUCTION mode");
      print("[EnvConfig] Logging: DISABLED");
    }

    // TODO: Load Firebase Remote Config here
    // TODO: Initialize analytics if enabled
    // TODO: Initialize crash reporting if enabled
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
