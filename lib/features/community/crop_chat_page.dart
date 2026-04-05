import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../../theme/app_theme.dart';
import '../../models/ai_chat_model.dart';
import '../../services/ai_chat_service.dart';

class CropChatPage extends StatefulWidget {
  final String? initialQuery;
  const CropChatPage({super.key, this.initialQuery});

  @override
  State<CropChatPage> createState() => _CropChatPageState();
}

class _CropChatPageState extends State<CropChatPage> {
  final AIChatService _aiChatService = AIChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AIChatMessage> _messages = [];

  // Voice Services
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isTyping = false;
  bool _isInitializing = true;
  bool _isListening = false;
  bool _isVoiceEnabled = true;
  bool _isSpeaking = false;
  String? _sessionId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeSession();
  }

  Future<void> _initializeServices() async {
    // Initialize TTS
    await _flutterTts.setLanguage("en-IN");
    await _flutterTts.setSpeechRate(0.5); // Better quality
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);

    _flutterTts.setStartHandler(() => setState(() => _isSpeaking = true));
    _flutterTts.setCompletionHandler(() => setState(() => _isSpeaking = false));
    _flutterTts.setErrorHandler((msg) => setState(() => _isSpeaking = false));

    // Initialize STT
    bool available = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) => setState(() => _isListening = false),
    );
    debugPrint('Speech recognition available: $available');
  }

  Future<void> _initializeSession() async {
    if (!mounted) return;

    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Please login to use AI expert chat';
      });
      return;
    }

    try {
      final session = await _aiChatService.getOrCreateChatSession(
          'Crop Consultation', 'crops');

      _sessionId = session.id;

      // Load existing messages
      final messagesStream = _aiChatService.getSessionMessages(_sessionId!);
      await for (final messages in messagesStream) {
        if (!mounted) break;

        setState(() {
          _messages.clear();
          // Clean existing messages if they have asterisks
          _messages.addAll(messages.map((m) => AIChatMessage(
                id: m.id,
                sessionId: m.sessionId,
                content: _aiChatService.cleanResponse(m.content),
                type: m.type,
                timestamp: m.timestamp,
                userId: m.userId,
                confidence: m.confidence,
                sources: m.sources,
              )));
          _isInitializing = false;
        });

        // If no messages, add greeting
        if (_messages.isEmpty) {
          final welcomeMsg = AIChatMessage(
            id: 'welcome',
            sessionId: _sessionId!,
            content:
                'Hello! I am your FarmKart Crop Expert. How can I help you with your crops today?',
            type: AIChatMessageType.ai,
            timestamp: DateTime.now(),
          );
          setState(() => _messages.add(welcomeMsg));
          await _aiChatService.addMessageToSession(_sessionId!, welcomeMsg);
          if (_isVoiceEnabled) _speak(welcomeMsg.content);
        }

        if (widget.initialQuery != null && _messages.length <= 1) {
          _sendMessage(widget.initialQuery!);
        }

        _scrollToBottom();
        break;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage =
              'Failed to initialize session. Please check your connection.';
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _flutterTts.stop();
    _speechToText.stop();
    super.dispose();
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

  Future<void> _speak(String text) async {
    if (!_isVoiceEnabled) return;
    await _flutterTts.speak(text);
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() => _isSpeaking = false);
  }

  Future<void> _startListening() async {
    if (_isSpeaking) await _stopSpeaking();

    bool available = await _speechToText.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speechToText.listen(
        onResult: (result) {
          setState(() {
            _messageController.text = result.recognizedWords;
            if (result.finalResult) {
              _isListening = false;
              _sendMessage();
            }
          });
        },
      );
    }
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  Future<void> _sendMessage([String? text]) async {
    final rawContent = text ?? _messageController.text.trim();
    if (rawContent.isEmpty || _sessionId == null) return;

    if (text == null) _messageController.clear();
    if (_isSpeaking) _stopSpeaking();

    final userMessage = AIChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: _sessionId!,
      content: rawContent,
      type: AIChatMessageType.user,
      timestamp: DateTime.now(),
      userId: FirebaseAuth.instance.currentUser?.uid,
    );

    if (mounted) {
      setState(() {
        _messages.add(userMessage);
        _isTyping = true;
      });
    }

    _scrollToBottom();
    await _aiChatService.addMessageToSession(_sessionId!, userMessage);

    try {
      final response =
          await _aiChatService.askExpert(rawContent, context: 'crops');

      // Clean the response
      final cleanedAnswer = _aiChatService.cleanResponse(response.answer);

      final aiMessage = AIChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: _sessionId!,
        content: cleanedAnswer,
        type: AIChatMessageType.ai,
        timestamp: DateTime.now(),
        confidence: response.confidence,
        sources: response.sources,
      );

      if (mounted) {
        setState(() {
          _messages.add(aiMessage);
          _isTyping = false;
        });
        _scrollToBottom();

        await _aiChatService.addMessageToSession(_sessionId!, aiMessage);

        if (_isVoiceEnabled) {
          _speak(cleanedAnswer);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTyping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : Colors.white,
      body: Column(
        children: [
          _buildTopHeader(context),
          Expanded(
            child: _isInitializing
                ? _buildLoadingState()
                : _errorMessage != null
                    ? _buildErrorState()
                    : _buildChatList(isDark),
          ),
          _buildInputArea(isDark),
        ],
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen,
            AppTheme.lightGreen,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Crop Expert',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'AI Agriculture Assistant',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(
                _isVoiceEnabled ? Icons.volume_up : Icons.volume_off,
                size: 18,
                color: Colors.white70,
              ),
              Switch(
                value: _isVoiceEnabled,
                onChanged: (value) {
                  setState(() => _isVoiceEnabled = value);
                  if (!value) _stopSpeaking();
                },
                activeColor: Colors.white,
                activeTrackColor: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
          if (_isSpeaking)
            IconButton(
              icon: const Icon(Icons.stop_circle, color: Colors.white),
              onPressed: _stopSpeaking,
            ),
        ],
      ),
    );
  }

  Widget _buildChatList(bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _buildTypingIndicator(isDark);
        }
        final message = _messages[index];
        return _buildChatGPTMessage(message, isDark);
      },
    );
  }

  Widget _buildChatGPTMessage(AIChatMessage message, bool isDark) {
    final isAI = message.type == AIChatMessageType.ai;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(
        color: isAI
            ? (isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.grey.withValues(alpha: 0.05))
            : Colors.transparent,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isAI ? AppTheme.primaryGreen : AppTheme.accentOrange,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              isAI ? Icons.auto_awesome : Icons.person,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAI ? 'Expert' : 'You',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  message.content,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.textDark,
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
                if (isAI && (message.confidence != null)) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Confidence: ${(message.confidence! * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.primaryGreen),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        children: [
          if (_isListening)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Text(
                'Listening...',
                style: TextStyle(
                    color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white24
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening
                              ? AppTheme.error
                              : AppTheme.primaryGreen,
                        ),
                        onPressed:
                            _isListening ? _stopListening : _startListening,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Message Crop Expert...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          maxLines: 5,
                          minLines: 1,
                          style: TextStyle(
                              color: isDark ? Colors.white : AppTheme.textDark),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.send_rounded,
                          color: _messageController.text.trim().isEmpty
                              ? Colors.grey
                              : AppTheme.primaryGreen,
                        ),
                        onPressed: _messageController.text.trim().isEmpty
                            ? null
                            : () => _sendMessage(),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'FarmKart AI can make mistakes. Check important info.',
            style: TextStyle(
                fontSize: 10, color: isDark ? Colors.white38 : Colors.black38),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(color: AppTheme.primaryGreen),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
          const SizedBox(height: 16),
          Text(_errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
              onPressed: _initializeSession, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.grey.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(4),
            ),
            child:
                const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 16),
          const Text('...',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        ],
      ),
    );
  }
}
