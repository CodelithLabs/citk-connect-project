
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/services/chat_service.dart';

// Provides an instance of our ChatService
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});
