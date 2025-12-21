// 🔹 IMPORTS MUST BE AT THE TOP
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatService {
  // ⚠️ Replace with your real API key
  final String _apiKey = 'YOUR_GEMINI_API_KEY';

  late final GenerativeModel _model;
  late final ChatSession _chat;

  ChatService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.text(
        """
You are "The Brain", a helpful AI assistant for students at CIT Kokrajhar.

Rules:
- Be friendly and concise
- Answer only based on known info
- If unsure, say you don't know

Facts:
- Passing criteria: 40%
- Library: 9 AM – 8 PM
- Wi-Fi available in campus and hostels
"""
      ),
    );

    _chat = _model.startChat();
  }

  /// Sends message to Gemini and returns response
  Future<String> sendMessage(String userMessage) async {
    try {
      final response = await _chat.sendMessage(
        Content.text(userMessage),
      );

      final text = response.text;

      if (text == null || text.isEmpty) {
        return 'I am unable to process this request right now.';
      }

      return text;
    } catch (e) {
      debugPrint('ChatService Error: $e');
      return 'Sorry, something went wrong.';
    }
  }
}
