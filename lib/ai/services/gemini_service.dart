import 'dart:convert';
import 'package:flutter/services.dart'; // To read the JSON file
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

class GeminiService {
  GenerativeModel? _model;
  ChatSession? _chat;
  bool _isInitialized = false;

  // USE YOUR NEW KEY HERE
  final String _apiKey = "AIzaSyCWKKqwxg20qZ1ygN50Gpeh4wKoz4ZZvw4"; 

  // Initialize and load the "Brain" (JSON Data)
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Load the CITK Data from the file
      final String jsonString = await rootBundle.loadString('assets/data/citk_data.json');
      
      // 2. Configure the Model (Using 1.5-flash for speed & free tier)
      _model = GenerativeModel(
        model: 'gemini-2.5-flash', 
        apiKey: _apiKey,
        generationConfig: GenerationConfig(maxOutputTokens: 200),
      );

      // 3. Create the System Instruction (The "Context")
      // We tell Gemini: "Here is the data about CITK. Only answer using this."
      final systemInstruction = Content.text(
        "You are an intelligent assistant for CITK (Central Institute of Technology Kokrajhar). "
        "Use the following JSON data to answer student questions accurately. "
        "Data: $jsonString "
        "If the answer is not in the data, say 'I don't have that info yet, please check with the admin.' "
        "Keep answers short and helpful."
      );

      // 4. Start Chat with this context
      _chat = _model!.startChat(history: [
        systemInstruction, // <--- This injects the knowledge!
        Content.model([TextPart("Understood. I have read the CITK data and am ready to help.")]),
      ]);

      _isInitialized = true;
    } catch (e) {
      print("Error initializing AI: $e");
    }
  }

  Future<String> sendMessage(String message) async {
    if (!_isInitialized) await init(); // Auto-init if needed

    try {
      final response = await _chat!.sendMessage(Content.text(message));
      return response.text ?? "I am thinking...";
    } catch (e) {
      return "Network Error. Please try again.";
    }
  }
}