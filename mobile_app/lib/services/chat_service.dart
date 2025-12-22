import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:developer';

class ChatService {
  final GenerativeModel _model;

  ChatService(String apiKey) :
    _model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);

  Future<String> sendMessage(String message) async {
    try {
      final content = [Content.text(message)];
      final response = await _model.generateContent(content);
      return response.text ?? 'No response from AI.';
    } catch (e) {
      log('Error sending message to AI: $e');
      return 'Error: Could not communicate with the AI.';
    }
  }
}

// Provider for ChatService
final chatServiceProvider = Provider<ChatService>((ref) {
  // Ideally, you would use a more secure way to provide the API key.
  const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  if (apiKey.isEmpty) {
    throw Exception('GEMINI_API_KEY is not set.');
  }
  return ChatService(apiKey);
});
