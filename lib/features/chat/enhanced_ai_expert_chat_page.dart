import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/ai_chat_model.dart';
import '../../services/ai_chat_service.dart';
import '../../services/locale_service.dart';
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
  State<EnhancedAIExpertChatPage> createState() => _EnhancedAIExpertChatPageState();
}

class _EnhancedAIExpertChatPageState extends State<EnhancedAIExpertChatPage>
    with TickerProviderStateMixin {
  final AIChatService _aiChatService = AIChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  AIChatSession? _currentSession;
  bool _isLoading = false;
  bool _isTyping = false;
  List<AIChatMessage> _messages = [];
  String _selectedCategory = AIChatCategory.general;

  late AnimationController _typingAnimationController;
  
  // Voice Mode State
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _lastWords = '';
  double _voiceLevel = 0.0;
  bool _autoSpeak = false;

  StreamSubscription<List<AIChatMessage>>? _messagesSubscription;
  bool _isDarkMode = false;

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
    if (mounted) setState(() {});
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("en-IN");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  void _startListening() async {
    if (!_speechEnabled) {
      bool available = await _speech.initialize();
      if (!available) {
        ToastHelper.showError(context, 'Speech recognition not available');
        return;
      }
    }

    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      ToastHelper.showError(context, 'Microphone permission denied');
      return;
    }

    setState(() {
      _isListening = true;
      _lastWords = '';
    });

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _lastWords = result.recognizedWords;
          if (result.finalResult) {
            _messageController.text = _lastWords;
            _isListening = false;
            _sendMessage();
          }
        });
      },
      onSoundLevelChange: (level) {
        setState(() => _voiceLevel = level);
      },
    );
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    String cleanText = text.replaceAll(RegExp(r'[*#_~]'), '');
    await _flutterTts.speak(cleanText);
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

  Future<void> _initializeSession() async {
    if (widget.session != null) {
      setState(() {
        _currentSession = widget.session;
        _selectedCategory = widget.session!.category;
      });
      _loadMessages();
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final category = widget.initialCategory ?? AIChatCategory.general;
      final session = await _aiChatService.createChatSession(
        'Farming Advice - $category',
        category,
      );

      if (mounted) {
        setState(() {
          _currentSession = session;
          _selectedCategory = category;
          _isLoading = false;
        });
        _loadMessages();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ToastHelper.showError(context, 'Failed to start chat session');
      }
    }
  }

  void _loadMessages() {
    if (_currentSession == null) return;

    _messagesSubscription?.cancel();
    _messagesSubscription = _aiChatService.getSessionMessages(_currentSession!.id).listen(
      (messages) {
        if (mounted) {
          setState(() => _messages = messages);
          _scrollToBottom();
        }
      },
    );
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
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      drawer: const UniversalDrawer(currentPage: 'ai-chat'),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeaderSliver(),
                if (_messages.isEmpty && !_isLoading)
                  SliverToBoxAdapter(child: _buildWelcomeScreen()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildMessageBubble(_messages[index]),
                      childCount: _messages.length,
                    ),
                  ),
                ),
                if (_isTyping)
                  SliverToBoxAdapter(child: _buildTypingIndicator()),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildHeaderSliver() {
    return UniversalHeader(
      title: 'AI Expert',
      subtitle: 'Precision Farming Guidance',
      icon: Icons.psychology_rounded,
      showBackButton: true,
      actions: [
        _buildHeaderAction(
          _autoSpeak ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          () {
            setState(() => _autoSpeak = !_autoSpeak);
            ToastHelper.showInfo(context, _autoSpeak ? 'Auto-speak ON' : 'Auto-speak OFF');
          },
          _autoSpeak ? Colors.white : Colors.white60,
        ),
      ],
    );
  }

  Widget _buildHeaderAction(IconData icon, VoidCallback onTap, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Column(
        children: [
          _buildPulsingIcon(),
          const SizedBox(height: 32),
          Text(
            'Ready for Farming Success?',
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.w800,
              color: AppTheme.getTextColor(context),
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Ask me anything about crops, soil, market trends, or pest management.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.getSecondaryTextColor(context), 
              fontSize: 16,
              height: 1.5,
            ),
          ),
          if (_isListening) ...[
            const SizedBox(height: 48),
            _buildVoiceIndicator(),
          ],
          if (!_isListening) ...[
            const SizedBox(height: 40),
            _buildQuickPrompts(),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickPrompts() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        'Wheat sowing tips',
        'Organic pest control',
        'Market rates for rice',
        'Soil health booster',
      ].map((prompt) => ActionChip(
        label: Text(prompt),
        labelStyle: TextStyle(
          color: AppTheme.getPrimaryAccent(context),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: AppTheme.getPrimaryAccent(context).withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: AppTheme.getPrimaryAccent(context).withOpacity(0.2)),
        onPressed: () {
          _messageController.text = prompt;
          _sendMessage();
        },
      )).toList(),
    );
  }

  Widget _buildPulsingIcon() {
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.getPrimaryAccent(context).withOpacity(0.1),
            boxShadow: [
              BoxShadow(
                color: AppTheme.getPrimaryAccent(context).withOpacity(0.1 * _typingAnimationController.value),
                blurRadius: 20,
                spreadRadius: 10 * _typingAnimationController.value,
              ),
            ],
          ),
          child: Icon(
            Icons.psychology_outlined, 
            size: 80, 
            color: AppTheme.getPrimaryAccent(context).withOpacity(0.8),
          ),
        );
      },
    );
  }

  Widget _buildVoiceIndicator() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 15 + (math.Random().nextDouble() * 40 * (_voiceLevel + 10) / 10),
              width: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.getPrimaryAccent(context), AppTheme.getPrimaryAccent(context).withOpacity(0.5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        Text(
          'SPEAK NOW',
          style: TextStyle(
            color: AppTheme.getPrimaryAccent(context), 
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(AIChatMessage message) {
    if (message.isSystemMessage) return _buildSystemMessage(message);

    final isUser = message.isFromUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) _buildAvatar(Icons.psychology_rounded, AppTheme.getPrimaryAccent(context)),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUser 
                        ? AppTheme.getPrimaryAccent(context) 
                        : AppTheme.getCardColor(context),
                    borderRadius: BorderRadius.circular(20).copyWith(
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                      bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                    ),
                    border: !isUser ? Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5)) : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), 
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content.trim(),
                        style: TextStyle(
                          color: isUser ? Colors.white : AppTheme.getTextColor(context),
                          fontSize: 15,
                          height: 1.5,
                          fontWeight: isUser ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                      if (!isUser) ...[
                        const SizedBox(height: 12),
                        Divider(height: 1, color: AppTheme.getDividerColor(context)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildActionIcon(Icons.volume_up_rounded, 'Speak', () => _speak(message.content)),
                            const SizedBox(width: 20),
                            _buildActionIcon(Icons.copy_rounded, 'Copy', () {
                              Clipboard.setData(ClipboardData(text: message.content));
                              ToastHelper.showSuccess(context, 'Copied');
                            }),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isUser) _buildAvatar(Icons.person_rounded, AppTheme.accentOrange),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 4, 
              left: isUser ? 0 : 52, 
              right: isUser ? 52 : 0
            ),
            child: Text(
              _formatTime(message.timestamp),
              style: TextStyle(fontSize: 10, color: AppTheme.getSecondaryTextColor(context).withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildActionIcon(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.getPrimaryAccent(context)),
            const SizedBox(width: 6),
            Text(
              label, 
              style: TextStyle(
                fontSize: 12, 
                color: AppTheme.getPrimaryAccent(context), 
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _buildSystemMessage(AIChatMessage message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context), 
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5)),
        ),
        child: Text(
          message.content, 
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.getSecondaryTextColor(context)),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildAvatar(Icons.psychology_rounded, AppTheme.getPrimaryAccent(context)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.getCardColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Text(
                  'Expert is thinking', 
                  style: TextStyle(
                    color: AppTheme.getSecondaryTextColor(context), 
                    fontStyle: FontStyle.italic, 
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                _buildDotAnimation(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotAnimation() {
    return Row(
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _typingAnimationController,
          builder: (context, child) {
            double delay = index * 0.2;
            double value = math.sin((_typingAnimationController.value * 2 * math.pi) + delay);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 4,
              width: 4,
              decoration: BoxDecoration(
                color: AppTheme.getPrimaryAccent(context).withOpacity(0.3 + (value + 1) / 2 * 0.7),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildInputArea() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08), 
            blurRadius: 15, 
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.getBackgroundColor(context),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppTheme.getBorderColor(context).withOpacity(0.5),
                ),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                style: TextStyle(color: AppTheme.getTextColor(context)),
                decoration: InputDecoration(
                  hintText: _isListening ? 'Listening...' : 'Type a farming question...',
                  hintStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context).withOpacity(0.6)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  prefixIcon: IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded, 
                      color: _isListening ? Colors.red : AppTheme.getPrimaryAccent(context),
                    ),
                    onPressed: _isListening ? _stopListening : _startListening,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getPrimaryAccent(context),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.getPrimaryAccent(context).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _sendMessage,
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.send_rounded, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentSession == null) return;

    final localeService = Provider.of<LocaleService>(context, listen: false);
    final languageCode = localeService.locale.languageCode;

    _messageController.clear();
    setState(() => _isTyping = true);
    _scrollToBottom();

    try {
      final userMessage = AIChatMessage(
        id: '',
        sessionId: _currentSession!.id,
        content: text,
        type: AIChatMessageType.user,
        timestamp: DateTime.now(),
        userId: FirebaseAuth.instance.currentUser?.uid,
      );
      await _aiChatService.addMessageToSession(_currentSession!.id, userMessage);

      final aiResponse = await _aiChatService.askExpert(
        text, 
        context: _selectedCategory,
        languageCode: languageCode,
      );
      
      String cleanedResponse = aiResponse.answer.trim();

      final aiMessage = AIChatMessage(
        id: '',
        sessionId: _currentSession!.id,
        content: cleanedResponse,
        type: AIChatMessageType.ai,
        timestamp: DateTime.now(),
      );
      await _aiChatService.addMessageToSession(_currentSession!.id, aiMessage);

      if (_autoSpeak) {
        _speak(cleanedResponse);
      }
    } catch (e) {
      ToastHelper.showError(context, 'Expert connection timed out');
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }
}
