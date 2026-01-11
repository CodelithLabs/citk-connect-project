import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:citk_connect/ai/services/gemini_service.dart'; // Import the service
import 'package:share_plus/share_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _flutterTts = FlutterTts();

  // Initial History
  final List<Map<String, String>> _messages = [
    {
      'role': 'ai',
      'text':
          'Hello! I am your CITK Digital Senior. Ask me anything about hostels, exams, or campus life!'
    },
  ];

  // 💡 SUGGESTED QUESTIONS
  final List<String> _suggestedQuestions = [
    "Bus Schedule? 🚌",
    "Hostel Rules? 🏠",
    "Exam Dates? 📅",
    "Library Timing? 📚",
    "Holiday List? 🎉",
  ];

  bool _isTyping = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _setupTts();
    _loadHistory(); // 📥 Load saved chats
  }

  Future<void> _setupTts() async {
    // ⚙️ TTS CONFIGURATION
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0); // 0.5 to 2.0
    await _flutterTts.setSpeechRate(0.5); // 0.0 to 1.0

    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _flutterTts.setCancelHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _flutterTts.setErrorHandler((_) {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  // 💾 LOAD HISTORY
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedChat = prefs.getString('chat_history');

    if (savedChat != null && mounted) {
      try {
        final List<dynamic> decoded = jsonDecode(savedChat);
        setState(() {
          _messages.clear();
          // Convert dynamic list back to List<Map<String, String>>
          _messages.addAll(decoded.map((e) => Map<String, String>.from(e)));
        });
        // Scroll to bottom after loading
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      } catch (e) {
        debugPrint("Error loading chat history: $e");
      }
    }
  }

  // 💾 SAVE HISTORY
  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_history', jsonEncode(_messages));
  }

  @override
  void dispose() {
    _flutterTts.stop(); // 🛑 Stop speaking if user leaves screen
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? customText]) async {
    final text = customText ?? _controller.text.trim();
    if (text.isEmpty) return;

    // 1. Add User Message to UI
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isTyping = true; // Show loading bubble
    });
    _saveHistory(); // Save user message
    if (customText == null) _controller.clear(); // Only clear if typed manually
    _scrollToBottom();

    try {
      // 2. CALL GEMINI (The Real AI)
      // We use ref.read to get the service and await the response
      final response = await ref.read(geminiServiceProvider).sendMessage(text);

      if (mounted) {
        // 🛑 STOP CHECK: If user cancelled, don't show response
        if (!_isTyping) return;

        setState(() {
          _isTyping = false;
          _messages.add({'role': 'ai', 'text': response});
        });
        _saveHistory(); // Save AI response
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        if (!_isTyping) return;

        setState(() {
          _isTyping = false;
          _messages.add({
            'role': 'ai',
            'text': "Oops! My brain is offline. Check your internet connection."
          });
        });
        _saveHistory(); // Save error message
        _scrollToBottom();
      }
    }
  }

  void _regenerateLastResponse() async {
    // 1. Find last user message
    String? lastUserText;
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i]['role'] == 'user') {
        lastUserText = _messages[i]['text'];
        break;
      }
    }
    if (lastUserText == null) return;

    setState(() {
      if (_messages.isNotEmpty && _messages.last['role'] == 'ai') {
        _messages.removeLast();
      }
      _isTyping = true;
    });
    _saveHistory(); // Save state after removal

    try {
      final response =
          await ref.read(geminiServiceProvider).sendMessage(lastUserText);
      if (mounted) {
        // 🛑 STOP CHECK
        if (!_isTyping) return;

        setState(() {
          _isTyping = false;
          _messages.add({'role': 'ai', 'text': response});
        });
        _saveHistory(); // Save new response
        _scrollToBottom();
      }
    } catch (e) {
      // Error handling is managed by the service or UI state
      if (mounted) setState(() => _isTyping = false);
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
    final aiStatus = ref.watch(aiStatusProvider);
    final isError = aiStatus.toLowerCase().contains('offline') ||
        aiStatus.toLowerCase().contains('failed');
    final statusColor = isError ? Colors.redAccent : const Color(0xFF6C63FF);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const FaIcon(FontAwesomeIcons.robot,
                size: 20, color: Colors.blueAccent),
            const SizedBox(width: 10),
            Text("CITK Assistant",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Clear Chat",
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white70),
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  backgroundColor: const Color(0xFF2C2C2C),
                  title: Text("Clear Chat History?",
                      style: GoogleFonts.inter(color: Colors.white)),
                  content: Text(
                      "This will wipe the AI's memory of this conversation. You can't undo this.",
                      style: GoogleFonts.inter(color: Colors.white70)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text("Cancel",
                          style: GoogleFonts.inter(color: Colors.grey)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        // 1. Reset AI Memory
                        ref.read(geminiServiceProvider).resetChat();

                        // 2. Reset UI
                        setState(() {
                          _messages.clear();
                          _messages.add({
                            'role': 'ai',
                            'text':
                                'Hello! I am your CITK Digital Senior. Ask me anything about hostels, exams, or campus life!'
                          });
                          _isTyping = false;
                        });
                        _saveHistory(); // Save reset state

                        // 3. Vibe Check
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Memory wiped! 🧠✨",
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold)),
                              backgroundColor: const Color(0xFF6C63FF),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Text("Clear",
                          style: GoogleFonts.inter(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 0. AI Status Indicator (Connecting / Retrying)
          if (aiStatus.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: statusColor.withValues(alpha: 0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isError)
                    SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: statusColor)),
                  if (!isError) const SizedBox(width: 8),
                  Text(aiStatus,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.5, end: 0),

          // 1. Chat List
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show Typing Indicator
                    if (index == _messages.length) {
                      return _buildTypingIndicator(theme);
                    }

                    final msg = _messages[index];
                    final isUser = msg['role'] == 'user';

                    final isLast = index == _messages.length - 1;
                    // Don't regenerate the initial welcome message (index 0)
                    final showRegen =
                        !isUser && isLast && !_isTyping && index > 0;

                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: isUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onLongPress: () async {
                              // 📳 HAPTIC: Tactile feedback for the long press
                              await HapticFeedback.mediumImpact();

                              if (!mounted) return;

                              showModalBottomSheet(
                                context: context,
                                backgroundColor: const Color(0xFF2C2C2C),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20)),
                                ),
                                builder: (context) => SafeArea(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 4,
                                          margin:
                                              const EdgeInsets.only(bottom: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                        ListTile(
                                          leading: const Icon(
                                              Icons.copy_rounded,
                                              color: Colors.white),
                                          title: Text("Copy Text",
                                              style: GoogleFonts.inter(
                                                  color: Colors.white)),
                                          onTap: () async {
                                            Navigator.pop(context);
                                            await Clipboard.setData(
                                                ClipboardData(
                                                    text: msg['text']!));
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      "Copied to clipboard! 📋",
                                                      style: GoogleFonts.inter(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  backgroundColor:
                                                      const Color(0xFF6C63FF),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10)),
                                                  duration: const Duration(
                                                      seconds: 1),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(
                                              Icons.volume_up_rounded,
                                              color: Colors.white),
                                          title: Text("Speak",
                                              style: GoogleFonts.inter(
                                                  color: Colors.white)),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _flutterTts.speak(msg['text']!);
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(
                                              Icons.share_rounded,
                                              color: Colors.white),
                                          title: Text("Share",
                                              style: GoogleFonts.inter(
                                                  color: Colors.white)),
                                          onTap: () {
                                            Navigator.pop(context);
                                            SharePlus.instance.share(
                                              ShareParams(text: msg['text']!),
                                            );
                                          },
                                        ),
                                        if (!isUser)
                                          ListTile(
                                            leading: const Icon(
                                                Icons.flag_rounded,
                                                color: Colors.white),
                                            title: Text("Report Issue",
                                                style: GoogleFonts.inter(
                                                    color: Colors.white)),
                                            onTap: () {
                                              Navigator.pop(context);
                                              if (mounted) {
                                                showDialog(
                                                  context: context,
                                                  builder: (dialogContext) =>
                                                      AlertDialog(
                                                    backgroundColor:
                                                        const Color(0xFF2C2C2C),
                                                    title: Text(
                                                        "Report Response",
                                                        style:
                                                            GoogleFonts.inter(
                                                                color: Colors
                                                                    .white)),
                                                    content: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                            "Help us improve! What's wrong with this response?",
                                                            style: GoogleFonts
                                                                .inter(
                                                                    color: Colors
                                                                        .white70)),
                                                        const SizedBox(
                                                            height: 16),
                                                        TextField(
                                                          maxLines: 3,
                                                          style:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .white),
                                                          decoration:
                                                              InputDecoration(
                                                            hintText:
                                                                "Tell us more...",
                                                            hintStyle: TextStyle(
                                                                color: Colors
                                                                    .grey[600]),
                                                            filled: true,
                                                            fillColor:
                                                                const Color(
                                                                    0xFF1E1E1E),
                                                            border:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                              borderSide:
                                                                  BorderSide
                                                                      .none,
                                                            ),
                                                            contentPadding:
                                                                const EdgeInsets
                                                                    .all(12),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                dialogContext),
                                                        child: Text("Cancel",
                                                            style: GoogleFonts
                                                                .inter(
                                                                    color: Colors
                                                                        .grey)),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              dialogContext);
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                  "Thanks! Feedback received. 🛡️",
                                                                  style: GoogleFonts.inter(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold)),
                                                              backgroundColor:
                                                                  const Color(
                                                                      0xFF6C63FF),
                                                              behavior:
                                                                  SnackBarBehavior
                                                                      .floating,
                                                              shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              10)),
                                                            ),
                                                          );
                                                        },
                                                        child: Text("Submit",
                                                            style: GoogleFonts.inter(
                                                                color: Colors
                                                                    .redAccent,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin:
                                  EdgeInsets.only(bottom: showRegen ? 4 : 16),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? theme.colorScheme.primary
                                    : const Color(0xFF2C2C2C),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: isUser
                                      ? const Radius.circular(4)
                                      : const Radius.circular(20),
                                  bottomRight: isUser
                                      ? const Radius.circular(20)
                                      : const Radius.circular(4),
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
                          ),
                          if (showRegen)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 16, left: 4),
                              child: InkWell(
                                onTap: _regenerateLastResponse,
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.refresh_rounded,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text("Regenerate",
                                          style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: 300.ms),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .moveY(begin: 10, end: 0);
                  },
                ),
                // ⚡ Quick Actions FAB
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    heroTag: "quick_actions_fab",
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: const Color(0xFF2C2C2C),
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 40,
                                  height: 4,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                Text("Quick Actions ⚡",
                                    style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 16),
                                ..._suggestedQuestions.map((q) => ListTile(
                                      leading: const Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          color: Colors.white70),
                                      title: Text(q,
                                          style: GoogleFonts.inter(
                                              color: Colors.white)),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _sendMessage(q);
                                      },
                                    )),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    backgroundColor: theme.colorScheme.primary,
                    child: const Icon(Icons.bolt_rounded, color: Colors.white),
                  ).animate().scale(
                      delay: 300.ms,
                      duration: 400.ms,
                      curve: Curves.easeOutBack),
                ),
              ],
            ),
          ),

          // 1.5 Suggested Chips (Quick Starters)
          if (!_isTyping)
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _suggestedQuestions.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ActionChip(
                    label: Text(_suggestedQuestions[index],
                        style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                    backgroundColor: const Color(0xFF2C2C2C),
                    side:
                        BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    labelStyle: const TextStyle(color: Colors.white),
                    onPressed: () => _sendMessage(_suggestedQuestions[index]),
                  )
                      .animate()
                      .fade()
                      .slideX(begin: 0.2, end: 0, delay: (index * 100).ms);
                },
              ),
            ),

          // 1.6 Stop Generating Button (Only when typing)
          if (_isTyping)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _isTyping = false),
                  icon: const Icon(Icons.stop_circle_outlined, size: 16),
                  label: const Text("Stop Generating"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(
                        color: Colors.redAccent.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.2, end: 0),

          // 1.7 Stop Speaking Button (Only when speaking)
          if (_isSpeaking)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () => _flutterTts.stop(),
                  icon: const Icon(Icons.volume_off_rounded, size: 16),
                  label: const Text("Stop Speaking"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF6C63FF).withValues(alpha: 0.2),
                    foregroundColor: const Color(0xFF6C63FF),
                    side: BorderSide(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.2, end: 0),

          // 2. Input Field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
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
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Color(0xFF2C2C2C),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🧠 Brain Icon (Pulsing)
            const FaIcon(FontAwesomeIcons.brain,
                    size: 14, color: Color(0xFF6C63FF))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.8, end: 1.1, duration: 800.ms)
                .tint(color: Colors.purpleAccent, duration: 800.ms),
            const SizedBox(width: 8),

            // "Thinking..." Text with Shimmer
            Text("Thinking...",
                    style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500))
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1200.ms, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
