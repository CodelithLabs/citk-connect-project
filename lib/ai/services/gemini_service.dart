import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // To read the JSON file
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 📡 STATUS PROVIDER: UI listens to this for "Connecting...", "Retrying..."
final aiStatusProvider = StateProvider<String>((ref) => "");

// ⏳ RATE LIMIT PROVIDER: Tracks last request time
final lastAiRequestProvider = StateProvider<DateTime?>((ref) => null);

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService(ref);
});

class GeminiService {
  final Ref _ref;
  GeminiService(this._ref);

  GenerativeModel? _model;
  ChatSession? _chat;
  bool _isInitialized = false;
  Map<String, dynamic> _localKnowledge = {}; // 🧠 Local Brain (Parsed JSON)

  // USE YOUR NEW KEY HERE
  final String _apiKey = "AIzaSyCWKKqwxg20qZ1ygN50Gpeh4wKoz4ZZvw4";

  // Initialize and load the "Brain" (JSON Data)
  Future<void> init() async {
    if (_isInitialized) return;

    int retryCount = 0;
    const maxRetries = 3;

    while (!_isInitialized && retryCount < maxRetries) {
      try {
        _updateStatus(retryCount == 0
            ? "Connecting to Brain..."
            : "Retrying connection (${retryCount + 1}/$maxRetries)...");

        // 1. Load & Parse Data (Chunking Prep)
        try {
          final jsonString =
              await rootBundle.loadString('assets/data/citk_data.json');
          _localKnowledge = jsonDecode(jsonString);
        } catch (_) {
          _localKnowledge = {
            "info": "Offline Mode",
            "status": "Data unavailable"
          };
        }

        // 2. Configure the Model (Using 1.5-flash for speed & free tier)
        _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: _apiKey,
          generationConfig: GenerationConfig(maxOutputTokens: 200),
        );

        // 3. Lightweight System Instruction (Data injected per message)
        final systemInstruction = Content.text(
            "You are an intelligent assistant for CITK (Central Institute of Technology Kokrajhar). "
            "I will provide relevant context with each question. "
            "Answer based ONLY on that context. Keep it short, helpful, and Gen Z style.");

        // 4. Start Chat with this context
        _chat = _model!.startChat(history: [
          systemInstruction, // <--- This injects the knowledge!
          Content.model([
            TextPart(
                "Understood. I have read the CITK data and am ready to help.")
          ]),
        ]);

        _isInitialized = true;
        _updateStatus(""); // Clear status when ready
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          print("Error initializing AI after $maxRetries attempts: $e");
          _updateStatus("Offline Mode (Connection Failed)");
        } else {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
  }

  void _updateStatus(String status) {
    _ref.read(aiStatusProvider.notifier).state = status;
  }

  // 🧹 RESET: Clears AI memory for a fresh start
  void resetChat() {
    _chat = null;
    _isInitialized = false; // Forces re-init on next message
    _updateStatus("");
  }

  Future<String> sendMessage(String message) async {
    // 🧠 CACHE: Check local storage first to save quota
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = "ai_cache_${message.trim().toLowerCase()}";
    if (prefs.containsKey(cacheKey)) {
      return prefs.getString(cacheKey) ?? "Error loading cache.";
    }

    // 🛑 THROTTLE: Prevent spamming (Riverpod State)
    final lastRequest = _ref.read(lastAiRequestProvider);
    final now = DateTime.now();
    if (lastRequest != null &&
        now.difference(lastRequest) < const Duration(seconds: 2)) {
      return "Whoa, slow down! 🏎️ I'm processing...";
    }
    _ref.read(lastAiRequestProvider.notifier).state = now;

    if (!_isInitialized) await init(); // Auto-init if needed

    if (_chat == null) return "Unable to connect to AI.";

    try {
      // 🔍 NAIVE RAG: Inject only relevant data chunks
      final context = _findRelevantChunks(message);
      final prompt = "CONTEXT:\n$context\n\nUSER QUESTION:\n$message";

      final response = await _chat!.sendMessage(Content.text(prompt));
      final text = response.text ?? "I am thinking...";

      // Save to Cache
      await prefs.setString(cacheKey, text);
      return text;
    } catch (e) {
      return "Network Error. Please try again.";
    }
  }

  // 🧠 SMART CHUNKING: Filters JSON to save tokens
  String _findRelevantChunks(String query) {
    if (_localKnowledge.isEmpty) return "No data.";

    final queryLower = query.toLowerCase();
    final relevantData = <String, dynamic>{};

    _localKnowledge.forEach((key, value) {
      // If topic (key) matches query OR content (value) contains keywords
      if (queryLower.contains(key.toLowerCase()) ||
          jsonEncode(value).toLowerCase().contains(queryLower)) {
        relevantData[key] = value;
      }
    });

    return relevantData.isNotEmpty
        ? jsonEncode(relevantData)
        : "No specific data found.";
  }

  // 🗣️ FEEDBACK LOOP: Learn from users
  Future<void> submitFeedback(
      String query, String response, bool isHelpful) async {
    try {
      await FirebaseFirestore.instance.collection('ai_feedback').add({
        'query': query,
        'response': response,
        'isHelpful': isHelpful,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silent fail is okay for analytics
    }
  }
}
