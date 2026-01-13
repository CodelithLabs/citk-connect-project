// Purpose: Riverpod providers for AI agent
// ===========================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/citk_ai_agent.dart';

/// AI Agent provider
final citkAIAgentProvider = Provider<CITKAIAgent>((ref) {
  const apiKey = String.fromEnvironment('GEMINI_API_KEY');
  final firestore = FirebaseFirestore.instance;

  final agent = CITKAIAgent(
    apiKey: apiKey,
    firestore: firestore,
  );

  ref.onDispose(() {
    agent.dispose();
  });

  return agent;
});

/// AI initialization provider
final aiInitProvider = FutureProvider<void>((ref) async {
  final agent = ref.watch(citkAIAgentProvider);
  await agent.initialize();
});

/// Recent important notices provider
final importantNoticesProvider = FutureProvider<List<CITKNotice>>((ref) async {
  final agent = ref.watch(citkAIAgentProvider);
  return await agent.getImportantNotices(limit: 5);
});

/// Chat messages provider
final chatMessagesProvider = StateProvider<List<ChatMessage>>((ref) => []);

/// Chat message model
class ChatMessage {
  final String text;
  final bool isUser;
  final AIAction? action;
  final List<CITKNotice>? notices;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.action,
    this.notices,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
