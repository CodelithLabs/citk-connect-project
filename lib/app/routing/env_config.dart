import 'package:flutter/foundation.dart';

/// 🔐 ENVIRONMENT CONFIGURATION
/// Centralized access to API keys injected via --dart-define.
/// Example: flutter run --dart-define=GEMINI_API_KEY=AIza...
class EnvConfig {
  EnvConfig._(); // Private constructor

  /// Gemini AI API Key
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Google Maps API Key
  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  /// Validates that critical keys are present in Debug mode
  static void validate() {
    if (kDebugMode) {
      if (geminiApiKey.isEmpty) {
        debugPrint('⚠️ [EnvConfig] GEMINI_API_KEY is missing!');
      }
      if (googleMapsApiKey.isEmpty) {
        debugPrint('⚠️ [EnvConfig] GOOGLE_MAPS_API_KEY is missing!');
      }
    }
  }
}
