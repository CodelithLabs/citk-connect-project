import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Provider for the Gemini AI Service
final geminiServiceProvider =
    Provider<GeminiService>((ref) => GeminiService(ref));

/// Provider to track AI status (Online, Thinking, Error)
final aiStatusProvider = StateProvider<String>((ref) => '');

class GeminiService {
  final Ref ref;
  GenerativeModel? _model;
  ChatSession? _chat;

  // ⚠️ Replace with your actual API Key or use --dart-define
  static const String _apiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  GeminiService(this.ref);

  /// Initialize the Gemini Model
  void init() {
    if (_apiKey.isEmpty) {
      ref.read(aiStatusProvider.notifier).state = 'API Key Missing';
      return;
    }

    try {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        systemInstruction: Content.system('''
          You are CITK Connect AI, a helpful assistant for the Central Institute of Technology, Kokrajhar.
          
          Key Info:
          - Library: Open 9 AM - 8 PM (Mon-Sat).
          - Hostels: Boys (Dwimalu, Jwhwlao), Girls (Gwzwon, Nivedita).
          - Bus: Runs from Kokrajhar Railgate to Campus at 8:30 AM, 9:30 AM.
          - Exams: Usually in May/June and Dec/Jan.
          - The app crea
          Keep answers concise, friendly, and relevant to students.
        '''),
      );
      _startNewChat();
    } catch (e) {
      ref.read(aiStatusProvider.notifier).state = 'Init Failed';
    }
  }

  void _startNewChat() {
    if (_model == null) return;
    _chat = _model!.startChat();
    ref.read(aiStatusProvider.notifier).state = 'Online';
  }

  /// Send a message to Gemini and get the response
  Future<String> sendMessage(String message) async {
    if (_model == null) {
      init();
      if (_model == null)
        return "AI Service is not initialized. Check API Key.";
    }

    ref.read(aiStatusProvider.notifier).state = 'Thinking...';

    try {
      final response = await _chat?.sendMessage(Content.text(message));
      ref.read(aiStatusProvider.notifier).state = 'Online';
      return response?.text ?? "I didn't get that. Could you try again?";
    } catch (e) {
      ref.read(aiStatusProvider.notifier).state = 'Error';
      return "Connection error. Please check your internet.";
    }
  }

  /// Reset the conversation history
  void resetChat() {
    _startNewChat();
  }

  /// Submits feedback for an AI response.
  Future<void> submitFeedback(
      String query, String response, bool isHelpful) async {
    try {
      // Placeholder for Firestore integration
      // print("Feedback Submitted: $query -> Helpful: $isHelpful");
    } catch (e) {
      // print("Error submitting feedback: $e");
    }
  }
}
