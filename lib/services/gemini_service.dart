import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:citk_connect/app/routing/env_config.dart';

/// 🧠 GEMINI AI SERVICE
/// Handles communication with Google's Gemini API.
final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());

class GeminiService {
  // Google Gemini Pro Endpoint
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  /// Sends a prompt to Gemini and returns the text response.
  Future<String> generateContent(String prompt) async {
    // 🔐 SECURITY: Access key from EnvConfig (injected via --dart-define)
    final apiKey = EnvConfig.geminiApiKey;

    if (apiKey.isEmpty) {
      _logError('Gemini API Key is missing! Check --dart-define.');
      return "Brain freeze! 🥶 API Key is missing.";
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] ??
            "No response.";
      } else {
        _logError('Gemini Error: ${response.statusCode} ${response.body}');
        return "Glitch in the matrix. Status: ${response.statusCode}";
      }
    } catch (e, stack) {
      _logError('Network Error', e, stack);
      return "Connection severed. Is the wifi down?";
    }
  }

  void _logError(String message, [Object? error, StackTrace? stack]) {
    developer.log('❌ $message',
        error: error, stackTrace: stack, name: 'GEMINI');
  }
}
