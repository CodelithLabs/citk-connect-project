import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:mobile_app/models/chat_message.dart';
import 'package:mobile_app/providers/services_provider.dart';

// 1. State provider to hold the list of chat messages
final chatMessagesProvider = StateProvider<List<ChatMessage>>((ref) => []);

// 2. State provider to track the loading state
final isLoadingProvider = StateProvider<bool>((ref) => false);


class ChatbotView extends ConsumerWidget {
  const ChatbotView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatMessagesProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final textController = TextEditingController();

    void handleSendMessage() async {
      final messageText = textController.text;
      if (messageText.isEmpty) return;

      // Add user message to the list
      ref.read(chatMessagesProvider.notifier).update((state) => [
            ...state,
            ChatMessage(text: messageText, type: MessageType.user)
          ]);
      textController.clear();

      // Set loading state and get response from AI
      ref.read(isLoadingProvider.notifier).state = true;
      final response = await ref.read(chatServiceProvider).sendMessage(messageText);
      ref.read(isLoadingProvider.notifier).state = false;
      
      // Add bot response to the list
      ref.read(chatMessagesProvider.notifier).update((state) => [
            ...state,
            ChatMessage(text: response, type: MessageType.bot)
          ]);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('The Brain'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Align(
                  alignment: message.type == MessageType.user 
                      ? Alignment.centerRight 
                      : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: message.type == MessageType.user 
                          ? Colors.blue[100] 
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(message.text),
                  ),
                );
              },
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          // Input area
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      hintText: 'Ask about CITK...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30.0)),
                      ),
                    ),
                    onSubmitted: (_) => handleSendMessage(),
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: handleSendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
