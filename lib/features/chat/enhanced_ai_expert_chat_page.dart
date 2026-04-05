import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/ai_chat_model.dart';
import '../../services/ai_chat_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/toast_helper.dart';
import '../../widgets/universal_header.dart';
import '../../widgets/universal_drawer.dart';

class EnhancedAIExpertChatPage extends StatefulWidget {
  final AIChatSession? session;
  final String? initialCategory;
  final String? initialPrompt;

  const EnhancedAIExpertChatPage({
    super.key,
    this.session,
    this.initialCategory,
    this.initialPrompt,
  });

  @override
  State<EnhancedAIExpertChatPage> createState() =>
      _EnhancedAIExpertChatPageState();
}

class _EnhancedAIExpertChatPageState extends State<EnhancedAIExpertChatPage>
    with TickerProviderStateMixin {
  final AIChatService _aiChatService = AIChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  AIChatSession? _currentSession;
  final bool _isLoading = false;
  bool _isTyping = false;
  List<AIChatMessage> _messages = [];
  String _selectedCategory = AIChatCategory.general;

  late AnimationController _typingAnimationController;

  // Voice Mode State
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _speechEnabled = false;
  bool _autoSpeak = false;

  StreamSubscription<List<AIChatMessage>>? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _initSpeech();
    _initTts();
    _initializeSession();

    if (widget.initialPrompt != null) {
      _messageController.text = widget.initialPrompt!;
    }
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    try {
      _speechEnabled = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          setState(() => _isListening = false);
        },
      );
    } catch (e) {
      _speechEnabled = false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("en-IN");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  void _startListening() async {
    if (!_speechEnabled) return;

    setState(() {
      _isListening = true;
    });

    _speech.listen(
      onResult: (val) {
        setState(() {
          _messageController.text = val.recognizedWords;
        });
      },
    );
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    await _flutterTts.speak(text);
  }

  Future<void> _initializeSession() async {
    if (widget.session != null) {
      _currentSession = widget.session;
      _selectedCategory = widget.session!.category;
      _subscribeToMessages();
    } else if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
  }

  void _subscribeToMessages() {
    _messagesSubscription?.cancel();
    if (_currentSession == null) return;

    _messagesSubscription =
        _aiChatService.getChatMessages(_currentSession!.id).listen((messages) {
      if (mounted) {
        setState(() {
          _messages = messages;
        });
        _scrollToBottom();
      }
    });
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
  void dispose() {
    _typingAnimationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _messagesSubscription?.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      drawer: const UniversalDrawer(currentPage: 'ai_expert'),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                UniversalHeader(
                  title: 'AI Expert',
                  subtitle:
                      _currentSession?.title ?? 'Ask anything about farming',
                  icon: Icons.psychology_rounded,
                  showBackButton: true,
                  showProfile: true,
                  actions: [
                    IconButton(
                      icon: Icon(
                        _autoSpeak
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => setState(() => _autoSpeak = !_autoSpeak),
                      tooltip: 'Auto-speak responses',
                    ),
                  ],
                ),
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final message = _messages[index];
                        return _buildMessageBubble(message);
                      },
                      childCount: _messages.length,
                    ),
                  ),
                ),
                if (_isTyping)
                  SliverToBoxAdapter(
                    child: _buildTypingIndicator(),
                  ),
              ],
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AIChatMessage message) {
    final isUser = message.type == AIChatMessageType.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) _buildAIAvatar(),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppTheme.getPrimaryAccent(context)
                        : AppTheme.getAIBubbleColor(context),
                    borderRadius: BorderRadius.circular(20).copyWith(
                      bottomRight: isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(20),
                      bottomLeft: isUser
                          ? const Radius.circular(20)
                          : const Radius.circular(4),
                    ),
                    border: !isUser
                        ? Border.all(
                            color: AppTheme.getBorderColor(context)
                                .withValues(alpha: 0.5))
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : AppTheme.getTextColor(context),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isUser) _buildUserAvatar(),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 4,
              left: isUser ? 0 : 48,
              right: isUser ? 48 : 0,
            ),
            child: Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.getSecondaryTextColor(context)
                    .withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.getPrimaryAccent(context).withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.psychology,
          size: 18, color: AppTheme.getPrimaryAccent(context)),
    );
  }

  Widget _buildUserAvatar() {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        image: user?.photoURL != null
            ? DecorationImage(
                image: NetworkImage(user!.photoURL!), fit: BoxFit.cover)
            : null,
      ),
      child: user?.photoURL == null
          ? Icon(Icons.person,
              size: 18, color: AppTheme.getSecondaryTextColor(context))
          : null,
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 56, bottom: 20),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _typingAnimationController,
            builder: (context, child) {
              return Opacity(
                opacity: _typingAnimationController.value,
                child: Text(
                  'Expert is thinking...',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none_rounded,
                color: _isListening
                    ? Colors.red
                    : AppTheme.getSecondaryTextColor(context),
              ),
              onPressed: _isListening ? _stopListening : _startListening,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBackground : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: AppTheme.getBorderColor(context)
                          .withValues(alpha: 0.3)),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  maxLines: 4,
                  minLines: 1,
                  style: TextStyle(color: AppTheme.getTextColor(context)),
                  decoration: InputDecoration(
                    hintText: 'Ask your expert...',
                    hintStyle: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context)
                            .withValues(alpha: 0.5)),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              onPressed: _isTyping ? null : _handleSendMessage,
              mini: true,
              backgroundColor: AppTheme.getPrimaryAccent(context),
              elevation: 0,
              child:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    _focusNode.unfocus();

    if (mounted) setState(() => _isTyping = true);

    try {
      if (_currentSession == null) {
        final sessionId = await _aiChatService.createNewSession(
          title:
              content.length > 30 ? '${content.substring(0, 30)}...' : content,
          category: _selectedCategory,
        );
        final sessionDoc = await _aiChatService.getSession(sessionId);
        if (sessionDoc != null) {
          _currentSession = sessionDoc;
          _subscribeToMessages();
        }
      }

      if (_currentSession != null) {
        final response = await _aiChatService.sendMessage(
          sessionId: _currentSession!.id,
          content: content,
        );

        if (_autoSpeak) {
          _speak(response);
        }
      }
    } catch (e) {
      if (mounted) ToastHelper.showError(context, 'Expert connection error');
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
