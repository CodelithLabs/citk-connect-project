import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/services/chat_repository.dart';
import 'package:mobile_app/services/chat_service.dart';

class ChatbotView extends ConsumerStatefulWidget {
  const ChatbotView({super.key});

  @override
  ConsumerState<ChatbotView> createState() => _ChatbotViewState();
}

class _ChatbotViewState extends ConsumerState<ChatbotView> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final chatHistory = ref.watch(chatHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('The Brain - AI Assistant'),
      ),
      body: Column(
        children: [
          Expanded(
            child: chatHistory.when(
              data: (snapshot) {
                final messages = snapshot.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isUserMessage = message['isFromUser'];
                    return ListTile(
                      title: Align(
                        alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isUserMessage ? Theme.of(context).colorScheme.primary : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            message['text'],
                            style: TextStyle(color: isUserMessage ? Colors.white : Colors.black),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask CITK anything...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final messageText = _messageController.text;
    _messageController.clear();

    try {
      // Save user message to Firestore
      await ref.read(chatRepositoryProvider).addMessage(messageText, true);

      // Get AI response
      final response = await ref.read(chatServiceProvider).sendMessage(messageText);

      // Save AI response to Firestore
      await ref.read(chatRepositoryProvider).addMessage(response, false);
    } catch (e) {
       if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

// Provider for the chat history stream
final chatHistoryProvider = StreamProvider.autoDispose((ref) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.getChatHistory();
});
