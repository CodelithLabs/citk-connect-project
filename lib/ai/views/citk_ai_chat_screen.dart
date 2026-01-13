// Purpose: Enhanced chat UI with Firebase integration
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_agent_provider.dart';
import '../services/citk_ai_agent.dart';

class CITKAIChatScreen extends ConsumerStatefulWidget {
  const CITKAIChatScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CITKAIChatScreen> createState() => _CITKAIChatScreenState();
}

class _CITKAIChatScreenState extends ConsumerState<CITKAIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _showWelcomeMessage();
  }

  void _showWelcomeMessage() async {
    // Show important notices when screen opens
    final notices = await ref.read(importantNoticesProvider.future);
    
    if (notices.isNotEmpty) {
      final welcomeMessage = ChatMessage(
        text: '👋 Welcome! Here are some important updates:\n\n' +
            notices.take(2).map((n) => '• ${n.title}').join('\n'),
        isUser: false,
        notices: notices.take(2).toList(),
      );
      
      ref.read(chatMessagesProvider.notifier).update(
        (state) => [welcomeMessage],
      );
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() => _isLoading = true);

    // Add user message
    final userMsg = ChatMessage(text: message, isUser: true);
    ref.read(chatMessagesProvider.notifier).update(
      (state) => [...state, userMsg],
    );
    _controller.clear();
    _scrollToBottom();

    try {
      // Get AI response
      final agent = ref.read(citkAIAgentProvider);
      final response = await agent.sendMessage(message);

      // Add AI message
      final aiMsg = ChatMessage(
        text: response.message,
        isUser: false,
        action: response.action,
        notices: response.relatedNotices,
      );
      
      ref.read(chatMessagesProvider.notifier).update(
        (state) => [...state, aiMsg],
      );

      // Execute action
      if (response.action != null) {
        _executeAction(response.action!, response.params);
      }

      _scrollToBottom();
    } catch (e) {
      final errorMsg = ChatMessage(
        text: 'Error: $e',
        isUser: false,
      );
      ref.read(chatMessagesProvider.notifier).update(
        (state) => [...state, errorMsg],
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _executeAction(AIAction action, Map<String, dynamic>? params) {
    switch (action) {
      case AIAction.openBusTracker:
        Navigator.pushNamed(context, '/bus-tracker');
        break;
      case AIAction.openMap:
        Navigator.pushNamed(context, '/map');
        break;
      case AIAction.openNotices:
        Navigator.pushNamed(context, '/notices');
        break;
      case AIAction.showNoticeDetail:
        // Handle notice detail
        break;
      default:
        break;
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final initState = ref.watch(aiInitProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CITK AI Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(citkAIAgentProvider).reset();
              ref.read(chatMessagesProvider.notifier).state = [];
              _showWelcomeMessage();
            },
          ),
        ],
      ),
      body: initState.when(
        data: (_) => _buildChatUI(messages),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildChatUI(List<ChatMessage> messages) {
    return Column(
      children: [
        _buildQuickActions(),
        Expanded(
          child: messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) =>
                      _buildMessageBubble(messages[index]),
                ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          ),
        _buildInputField(),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        children: [
          ActionChip(
            avatar: const Icon(Icons.campaign, size: 18),
            label: const Text('Important'),
            onPressed: () => _sendMessage('Show me important notices'),
          ),
          ActionChip(
            avatar: const Icon(Icons.directions_bus, size: 18),
            label: const Text('Bus'),
            onPressed: () => _sendMessage('Track bus'),
          ),
          ActionChip(
            avatar: const Icon(Icons.library_books, size: 18),
            label: const Text('Library'),
            onPressed: () => _sendMessage('Library timings'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.smart_toy, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Ask me anything about CITK!',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black87,
              ),
            ),
            if (message.notices != null && message.notices!.isNotEmpty)
              ...message.notices!.map((notice) => _buildNoticeCard(notice)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeCard(CITKNotice notice) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        title: Text(notice.title, style: const TextStyle(fontSize: 14)),
        subtitle: Text(notice.date),
        trailing: Icon(
          notice.isImportant ? Icons.priority_high : Icons.info_outline,
          color: notice.isImportant ? Colors.red : Colors.blue,
        ),
        onTap: () {
          // Open notice detail
        },
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Ask about CITK...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _sendMessage(_controller.text),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}