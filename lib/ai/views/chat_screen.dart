import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:citk_connect/ai/services/gemini_service.dart'; // Import the service

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Initial History
  final List<Map<String, String>> _messages = [
    {'role': 'ai', 'text': 'Hello! I am your CITK Digital Senior. Ask me anything about hostels, exams, or campus life!'},
  ];

  bool _isTyping = false;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // 1. Add User Message to UI
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isTyping = true; // Show loading bubble
    });
    _controller.clear();
    _scrollToBottom();

    try {
      // 2. CALL GEMINI (The Real AI)
      // We use ref.read to get the service and await the response
      final response = await ref.read(geminiServiceProvider).sendMessage(text);

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({'role': 'ai', 'text': response});
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({'role': 'ai', 'text': "Oops! My brain is offline. Check your internet connection."});
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const FaIcon(FontAwesomeIcons.robot, size: 20, color: Colors.blueAccent),
            const SizedBox(width: 10),
            Text("CITK Assistant", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
               // In a real app, you might want to restart the Gemini chat session here too
               setState(() => _messages.removeRange(1, _messages.length)); 
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Chat List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                // Show Typing Indicator
                if (index == _messages.length) {
                  return _buildTypingIndicator(theme);
                }

                final msg = _messages[index];
                final isUser = msg['role'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? theme.colorScheme.primary : const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: isUser ? const Radius.circular(4) : const Radius.circular(20),
                        bottomRight: isUser ? const Radius.circular(20) : const Radius.circular(4),
                      ),
                    ),
                    child: Text(
                      msg['text']!,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms).moveY(begin: 10, end: 0);
              },
            ),
          ),

          // 2. Input Field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Ask about exams, hostels...",
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2C),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.small(
                  onPressed: _sendMessage,
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFF2C2C2C),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.circle, size: 8, color: Colors.grey).animate(onPlay: (c) => c.repeat()).fade().scale(delay: 0.ms),
            const SizedBox(width: 4),
            const Icon(Icons.circle, size: 8, color: Colors.grey).animate(onPlay: (c) => c.repeat()).fade().scale(delay: 200.ms),
            const SizedBox(width: 4),
            const Icon(Icons.circle, size: 8, color: Colors.grey).animate(onPlay: (c) => c.repeat()).fade().scale(delay: 400.ms),
          ],
        ),
      ),
    );
  }
}