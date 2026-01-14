// lib/ai/providers/chat_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:citk_connect/ai/services/chat_history_service.dart';

final chatHistoryServiceProvider = Provider<ChatHistoryService>((ref) {
  return ChatHistoryService();
});
