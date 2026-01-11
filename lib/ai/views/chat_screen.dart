import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:citk_connect/ai/services/gemini_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _flutterTts = FlutterTts();
  final FocusNode _focusNode = FocusNode();

  late AnimationController _fabController;
  late AnimationController _welcomeController;

  final List<Map<String, String>> _messages = [
    {
      'role': 'ai',
      'text':
          'Hello! I am your CITK Digital Senior. Ask me anything about hostels, exams, or campus life!'
    },
  ];

  final List<String> _suggestedQuestions = [
    "Bus Schedule? 🚌",
    "Hostel Rules? 🏠",
    "Exam Dates? 📅",
    "Library Timing? 📚",
    "Holiday List? 🎉",
  ];

  bool _isTyping = false;
  bool _isSpeaking = false;
  bool _showScrollToBottom = false;
  int _characterCount = 0;

  @override
  void initState() {
    super.initState();
    _setupTts();
    _loadHistory();
    _setupAnimations();
    _setupScrollListener();
    _controller.addListener(_updateCharacterCount);
  }

  void _setupAnimations() {
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _welcomeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final show =
          _scrollController.hasClients && _scrollController.offset > 200;
      if (show != _showScrollToBottom) {
        setState(() => _showScrollToBottom = show);
        if (show) {
          _fabController.forward();
        } else {
          _fabController.reverse();
        }
      }
    });
  }

  void _updateCharacterCount() {
    setState(() => _characterCount = _controller.text.length);
  }

  Future<void> _setupTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

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

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedChat = prefs.getString('chat_history');

    if (savedChat != null && mounted) {
      try {
        final List<dynamic> decoded = jsonDecode(savedChat);
        setState(() {
          _messages.clear();
          _messages.addAll(decoded.map((e) => Map<String, String>.from(e)));
        });
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      } catch (e) {
        debugPrint("Error loading chat history: $e");
      }
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_history', jsonEncode(_messages));
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _fabController.dispose();
    _welcomeController.dispose();
    super.dispose();
  }

  void _sendMessage([String? customText]) async {
    final text = customText ?? _controller.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isTyping = true;
    });
    _saveHistory();
    if (customText == null) _controller.clear();
    _scrollToBottom();

    try {
      final response = await ref.read(geminiServiceProvider).sendMessage(text);
      if (mounted) {
        if (!_isTyping) return;
        setState(() {
          _isTyping = false;
          _messages.add({'role': 'ai', 'text': response});
        });
        _saveHistory();
        _scrollToBottom();
        HapticFeedback.mediumImpact();
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
        _saveHistory();
        _scrollToBottom();
      }
    }
  }

  void _regenerateLastResponse() async {
    String? lastUserText;
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i]['role'] == 'user') {
        lastUserText = _messages[i]['text'];
        break;
      }
    }
    if (lastUserText == null) return;

    HapticFeedback.mediumImpact();
    setState(() {
      if (_messages.isNotEmpty && _messages.last['role'] == 'ai') {
        _messages.removeLast();
      }
      _isTyping = true;
    });
    _saveHistory();

    try {
      final response =
          await ref.read(geminiServiceProvider).sendMessage(lastUserText);
      if (mounted) {
        if (!_isTyping) return;
        setState(() {
          _isTyping = false;
          _messages.add({'role': 'ai', 'text': response});
        });
        _saveHistory();
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
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
      backgroundColor: const Color(0xFF0A0A0F),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(statusColor, aiStatus, isError),
      body: Stack(
        children: [
          // Animated gradient background
          _buildAnimatedBackground(),

          // Main content
          Column(
            children: [
              if (aiStatus.isNotEmpty)
                _buildStatusBanner(statusColor, aiStatus, isError),
              Expanded(child: _buildChatList(theme)),
              if (!_isTyping) _buildSuggestedChips(),
              if (_isTyping) _buildStopGeneratingButton(),
              if (_isSpeaking) _buildStopSpeakingButton(),
              _buildInputField(theme),
            ],
          ),

          // Floating action buttons
          if (_showScrollToBottom) _buildScrollToBottomFab(),
          _buildQuickActionsFab(theme),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A0A0F),
            const Color(0xFF1A1A2E),
            const Color(0xFF16213E),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _GridPainter(),
        child: Container(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      Color statusColor, String aiStatus, bool isError) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: .05),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF6C63FF).withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const FaIcon(
              FontAwesomeIcons.robot,
              size: 18,
              color: Colors.white,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(duration: 2000.ms)
              .shake(hz: 0.5, curve: Curves.easeInOut),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "CITK Assistant",
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                "Powered by Gemini AI",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.white60,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: "Search Chat",
          icon: const Icon(Icons.search_rounded, color: Colors.white70),
          onPressed: () {
            HapticFeedback.lightImpact();
            _showSearchDialog();
          },
        ),
        IconButton(
          tooltip: "Clear Chat",
          icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white70),
          onPressed: () {
            HapticFeedback.mediumImpact();
            _showClearDialog();
          },
        ),
      ],
    );
  }

  Widget _buildStatusBanner(Color statusColor, String aiStatus, bool isError) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 100, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.15),
            statusColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!isError)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: statusColor,
              ),
            ),
          if (!isError) const SizedBox(width: 10),
          Icon(
            isError ? Icons.error_outline : Icons.cloud_sync_rounded,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 8),
          Text(
            aiStatus,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.3, end: 0);
  }

  Widget _buildChatList(ThemeData theme) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _buildTypingIndicator(theme);
        }

        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        final isLast = index == _messages.length - 1;
        final showRegen = !isUser && isLast && !_isTyping && index > 0;
        final isFirst = index == 0;

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onLongPress: () => _showMessageOptions(msg, isUser),
                child: Container(
                  margin: EdgeInsets.only(bottom: showRegen ? 4 : 16),
                  padding: const EdgeInsets.all(16),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
                          )
                        : LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.08),
                              Colors.white.withValues(alpha: 0.04),
                            ],
                          ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isUser
                          ? const Radius.circular(20)
                          : const Radius.circular(4),
                      bottomRight: isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(20),
                    ),
                    border: Border.all(
                      color: isUser
                          ? Colors.transparent
                          : Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? Color(0xFF6C63FF).withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser && isFirst)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Color(0xFF6C63FF).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: FaIcon(
                                  FontAwesomeIcons.wandMagicSparkles,
                                  size: 12,
                                  color: Color(0xFF6C63FF),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "CITK Bot",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        msg['text']!,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          height: 1.5,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (showRegen) _buildRegenerateButton(),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, curve: Curves.easeOut)
            .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
      },
    );
  }

  Widget _buildRegenerateButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _regenerateLastResponse();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  "Regenerate",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).scale();
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.wandMagicSparkles,
              size: 14,
              color: const Color(0xFF6C63FF),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 1000.ms),
            const SizedBox(width: 12),
            SizedBox(
              width: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(3, (index) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white70,
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(
                        onPlay: (c) => c.repeat(),
                        delay: (index * 200).ms,
                      )
                      .moveY(begin: 0, end: -5, duration: 400.ms, curve: Curves.easeOut)
                      .then()
                      .moveY(begin: -5, end: 0, duration: 400.ms, curve: Curves.easeIn);
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedChips() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _suggestedQuestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                _sendMessage(_suggestedQuestions[index]);
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _suggestedQuestions[index],
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(delay: (index * 100).ms)
              .slideX(begin: 0.3, end: 0, curve: Curves.easeOutCubic);
        },
      ),
    );
  }

  Widget _buildStopGeneratingButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              setState(() => _isTyping = false);
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.redAccent.withValues(alpha: 0.2),
                    Colors.red.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stop_circle_outlined,
                      size: 18, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Text(
                    "Stop Generating",
                    style: GoogleFonts.inter(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildStopSpeakingButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              _flutterTts.stop();
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF6C63FF).withValues(alpha: 0.25),
                    Color(0xFF6C63FF).withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Color(0xFF6C63FF).withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.volume_off_rounded,
                      size: 18, color: Color(0xFF6C63FF)),
                  const SizedBox(width: 8),
                  Text(
                    "Stop Speaking",
                    style: GoogleFonts.inter(
                      color: Color(0xFF6C63FF),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildInputField(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A0A0F).withValues(alpha: 0.95),
            const Color(0xFF0A0A0F),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (_characterCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "$_characterCount / 500",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: _characterCount > 450
                            ? Colors.orange
                            : Colors.white38,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: _focusNode.hasFocus
                            ? Color(0xFF6C63FF).withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.1),
                        width: 1.5,
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLength: 500,
                      buildCounter: (_,
                              {required currentLength,
                              required isFocused,
                              maxLength}) =>
                          null,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: "Ask about exams, hostels, campus life...",
                        hintStyle: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Colors.white38,
                          size: 20,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF6C63FF).withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _sendMessage,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 0.95, end: 1.05, duration: 2000.ms),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollToBottomFab() {
    return Positioned(
      bottom: 180,
      right: 16,
      child: ScaleTransition(
        scale: CurvedAnimation(
          parent: _fabController,
          curve: Curves.easeOutBack,
        ),
        child: FloatingActionButton.small(
          heroTag: "scroll_to_bottom",
          onPressed: () {
            HapticFeedback.lightImpact();
            _scrollToBottom();
          },
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          child: Icon(Icons.arrow_downward_rounded, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildQuickActionsFab(ThemeData theme) {
    return Positioned(
      bottom: 180,
      left: 16,
      child: FloatingActionButton(
        heroTag: "quick_actions",
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showQuickActions();
        },
        backgroundColor: Color(0xFF6C63FF),
        child: Icon(Icons.bolt_rounded, color: Colors.white),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(duration: 2000.ms)
          .then()
          .shake(hz: 0.3),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF0A0A0F),
            ],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Quick Actions ⚡",
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 20),
              ..._suggestedQuestions.map((q) => _buildQuickActionTile(q)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionTile(String question) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _sendMessage(question);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFF6C63FF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF6C63FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  question,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white38,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(Map<String, String> msg, bool isUser) async {
    await HapticFeedback.mediumImpact();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF0A0A0F),
            ],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _buildOptionTile(
                icon: Icons.copy_rounded,
                title: "Copy Text",
                onTap: () async {
                  Navigator.pop(context);
                  await Clipboard.setData(ClipboardData(text: msg['text']!));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      _buildSnackBar("Copied to clipboard! 📋"),
                    );
                  }
                },
              ),
              _buildOptionTile(
                icon: Icons.volume_up_rounded,
                title: "Speak",
                onTap: () {
                  Navigator.pop(context);
                  _flutterTts.speak(msg['text']!);
                },
              ),
              _buildOptionTile(
                icon: Icons.share_rounded,
                title: "Share",
                onTap: () {
                  Navigator.pop(context);
                  SharePlus.instance.share(ShareParams(text: msg['text']!));
                },
              ),
              if (!isUser)
                _buildOptionTile(
                  icon: Icons.flag_rounded,
                  title: "Report Issue",
                  onTap: () {
                    Navigator.pop(context);
                    _showReportDialog();
                  },
                  isDestructive: true,
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive ? Colors.redAccent : Colors.white,
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: isDestructive ? Colors.redAccent : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchDialog() {
    // Search functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Search Chat",
          style: GoogleFonts.spaceGrotesk(color: Colors.white),
        ),
        content: TextField(
          autofocus: true,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Search messages...",
            hintStyle: TextStyle(color: Colors.white38),
            prefixIcon: Icon(Icons.search, color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close",
                style: GoogleFonts.inter(color: Color(0xFF6C63FF))),
          ),
        ],
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Clear Chat History?",
          style: GoogleFonts.spaceGrotesk(color: Colors.white),
        ),
        content: Text(
          "This will wipe the AI's memory of this conversation. You can't undo this.",
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("Cancel", style: GoogleFonts.inter(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(geminiServiceProvider).resetChat();
              setState(() {
                _messages.clear();
                _messages.add({
                  'role': 'ai',
                  'text':
                      'Hello! I am your CITK Digital Senior. Ask me anything about hostels, exams, or campus life!'
                });
                _isTyping = false;
              });
              _saveHistory();
              ScaffoldMessenger.of(context).showSnackBar(
                _buildSnackBar("Memory wiped! 🧠✨"),
              );
            },
            child: Text(
              "Clear",
              style: GoogleFonts.inter(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Report Response",
          style: GoogleFonts.spaceGrotesk(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Help us improve! What's wrong with this response?",
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 3,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Tell us more...",
                hintStyle: TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Color(0xFF0A0A0F),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("Cancel", style: GoogleFonts.inter(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                _buildSnackBar("Thanks! Feedback received. 🛡️"),
              );
            },
            child: Text(
              "Submit",
              style: GoogleFonts.inter(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  SnackBar _buildSnackBar(String message) {
    return SnackBar(
      content: Text(
        message,
        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
      ),
      backgroundColor: Color(0xFF6C63FF),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: Duration(seconds: 2),
    );
  }
}

// Custom painter for grid background
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 1;

    const spacing = 40.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
