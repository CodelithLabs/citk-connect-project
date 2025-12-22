import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// Use dart-define to pass the API key
const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

class ChatService {
  final GenerativeModel _model;

  ChatService()
      : _model = GenerativeModel(
          model: 'gemini-pro',
          apiKey: _apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.7,
            topP: 1.0,
            topK: 1,
            maxOutputTokens: 2048,
          ),
          safetySettings: [
            SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
            SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
            SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
            SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
          ],
          systemInstruction: Content.text(
              'You are a helpful AI assistant for students of Central Institute of Technology, Kokrajhar. \n'
              'Your name is \"The Brain\".\n'
              'You should provide information about the campus, events, and academic life.\n'
              'Here is some information you should know:\n'
              ' - The library is open from 9 AM to 8 PM on weekdays.\n'
              ' - The Registrar sits in the Admin Block.\n'
              ' - The annual cultural fest is called "Ecstasy".\n'
              ' - The technical fest is called "Techsrijan".\n'
              ' - You can find the academic calendar on the official CITK website.\n'
              'When asked about topics outside of CITK, you should politely decline to answer.\n'),
        ) {
    if (_apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is not set. Please provide it using --dart-define=GEMINI_API_KEY=<YOUR_API_KEY>');
    }
  }

  Future<String> sendMessage(String message) async {
    try {
      final content = [Content.text(message)];
      final response = await _model.generateContent(content);
      return response.text ?? 'No response from API.';
    } catch (e) {
      print('Error sending message: $e');
      return 'Error: Could not communicate with the AI.';
    }
  }
}

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});
