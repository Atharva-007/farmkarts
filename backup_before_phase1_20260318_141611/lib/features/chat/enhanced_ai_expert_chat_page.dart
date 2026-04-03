import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import '../../models/ai_chat_model.dart';
import '../../services/ai_chat_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';
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
  late AnimationController _fabAnimationController;
  late Animation<double> _typingAnimation;
  late Animation<double> _fabAnimation;

  StreamSubscription<List<AIChatMessage>>? _messagesSubscription;
  bool _showSuggestions = true;
  bool _isDarkMode = false;
  bool _showEmojiPanel = false;

  // Quick suggestion categories
  final List<Map<String, dynamic>> _quickSuggestions = [
    {
      'text': '🌾 How can I improve my wheat yield?',
      'icon': Icons.agriculture,
      'category': AIChatCategory.crops,
    },
    {
      'text': '💧 What\'s the best irrigation schedule for rice?',
      'icon': Icons.water_drop,
      'category': AIChatCategory.irrigation,
    },
    {
      'text': '🐛 How do I identify and control pests?',
      'icon': Icons.bug_report,
      'category': AIChatCategory.pestControl,
    },
    {
      'text': '🌱 Which fertilizers should I use for corn?',
      'icon': Icons.grass,
      'category': AIChatCategory.fertilizers,
    },
    {
      'text': '🌤️ How does weather affect my crops?',
      'icon': Icons.wb_cloudy,
      'category': AIChatCategory.weather,
    },
    {
      'text': '💰 What are current market prices?',
      'icon': Icons.trending_up,
      'category': AIChatCategory.market,
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeSession();
    
    // Add initial prompt if provided
    if (widget.initialPrompt != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _messageController.text = widget.initialPrompt!;
      });
    }
  }

  void _setupAnimations() {
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _typingAnimationController, curve: Curves.easeInOut),
    );
    
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.elasticOut),
    );

    _typingAnimationController.repeat();
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _typingAnimationController.dispose();
    _fabAnimationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _messagesSubscription?.cancel();
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
        'Agricultural Consultation - $category',
        category,
      );

      setState(() {
        _currentSession = session;
        _selectedCategory = category;
        _isLoading = false;
      });

      _loadMessages();
      _addSystemMessage('🌾 Welcome to FarmKart AI Agricultural Expert! I\'m here to help you with professional farming advice. What would you like to know?');
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to start consultation session. Please try again.');
    }
  }

  void _loadMessages() {
    if (_currentSession == null) return;

    _messagesSubscription?.cancel();
    _messagesSubscription = _aiChatService.getSessionMessages(_currentSession!.id).listen(
      (messages) {
        setState(() {
          _messages = messages;
          _showSuggestions = messages.where((m) => m.type != AIChatMessageType.system).isEmpty;
        });
        _scrollToBottom();
      },
      onError: (e) => _showError('Connection error: $e'),
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
      backgroundColor: _isDarkMode ? Colors.grey[900] : AppTheme.backgroundLight,
      drawer: const UniversalDrawer(currentPage: 'ai-chat'),
      appBar: _buildEnhancedAppBar(),
      body: Column(
        children: [
          if (_currentSession != null) _buildChatHeader(),
          Expanded(child: _buildMessagesList()),
          if (_showSuggestions && _messages.where((m) => m.type != AIChatMessageType.system).isEmpty) 
            _buildQuickSuggestions(),
          _buildTypingIndicator(),
          _buildEnhancedMessageInput(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop, // Move to top-right
    );
  }

  PreferredSizeWidget _buildEnhancedAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: _isDarkMode ? Colors.grey[800] : AppTheme.primaryGreen,
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.psychology, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Agricultural Expert',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _currentSession != null 
                        ? '${_messages.where((m) => m.type != AIChatMessageType.system).length} messages • $_selectedCategory'
                        : 'Initializing...',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
          onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          tooltip: 'Toggle theme',
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'new_chat',
              child: ListTile(
                leading: Icon(Icons.add_comment, color: AppTheme.primaryGreen),
                title: Text('New Consultation'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'export_chat',
              child: ListTile(
                leading: Icon(Icons.download, color: AppTheme.primaryGreen),
                title: Text('Export Chat'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'clear_chat',
              child: ListTile(
                leading: Icon(Icons.clear_all, color: AppTheme.warning),
                title: Text('Clear Messages'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'help',
              child: ListTile(
                leading: Icon(Icons.help_outline, color: AppTheme.info),
                title: Text('Help & Tips'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _isDarkMode ? Colors.grey[700]! : AppTheme.borderGrey,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: AppTheme.success,
                ),
                const SizedBox(width: 6),
                Text(
                  'Online',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Specialized in: ${_selectedCategory}',
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : AppTheme.textGrey,
                fontSize: 14,
              ),
            ),
          ),
          _buildCategoryChips(),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return PopupMenuButton<String>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.accentOrange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.accentOrange.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedCategory,
              style: TextStyle(
                color: AppTheme.accentOrange,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: AppTheme.accentOrange,
              size: 16,
            ),
          ],
        ),
      ),
      onSelected: (category) {
        setState(() => _selectedCategory = category);
      },
      itemBuilder: (context) => [
        AIChatCategory.general,
        AIChatCategory.crops,
        AIChatCategory.weather,
        AIChatCategory.market,
        AIChatCategory.irrigation,
        AIChatCategory.fertilizers,
        AIChatCategory.pestControl,
        AIChatCategory.soilHealth,
      ].map((category) => PopupMenuItem(
        value: category,
        child: Text(category),
      )).toList(),
    );
  }

  Widget _buildMessagesList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryGreen),
            const SizedBox(height: 16),
            Text(
              'Starting consultation...',
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : AppTheme.textGrey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message, index);
      },
    );
  }

  Widget _buildMessageBubble(AIChatMessage message, int index) {
    final isFromUser = message.isFromUser;
    final isSystemMessage = message.isSystemMessage;
    
    if (isSystemMessage) {
      return _buildSystemMessage(message);
    }

    return Container(
      margin: EdgeInsets.only(
        bottom: 16,
        left: isFromUser ? 50 : 0,
        right: isFromUser ? 0 : 50,
      ),
      child: Column(
        crossAxisAlignment: isFromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isFromUser) _buildAIAvatar(),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isFromUser 
                      ? AppTheme.primaryGreen 
                      : (_isDarkMode ? Colors.grey[800] : Colors.white),
                    borderRadius: BorderRadius.circular(20).copyWith(
                      bottomLeft: isFromUser ? Radius.circular(20) : Radius.circular(4),
                      bottomRight: isFromUser ? Radius.circular(4) : Radius.circular(20),
                    ),
                    boxShadow: AppTheme.defaultShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        message.content,
                        style: TextStyle(
                          color: isFromUser 
                            ? Colors.white 
                            : (_isDarkMode ? Colors.white : AppTheme.textDark),
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                      if (!isFromUser && message.confidence != null)
                        _buildConfidenceIndicator(message.confidence!),
                      if (!isFromUser && message.sources != null && message.sources!.isNotEmpty)
                        _buildSourcesWidget(message.sources!),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isFromUser) _buildUserAvatar(),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _formatMessageTime(message.timestamp),
              style: TextStyle(
                color: _isDarkMode ? Colors.white38 : AppTheme.textGrey,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(AIChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.info.withOpacity(0.3)),
          ),
          child: Text(
            message.content,
            style: TextStyle(
              color: AppTheme.info,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildAIAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.defaultShadow,
      ),
      child: Icon(
        Icons.psychology,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accentOrange, AppTheme.lightOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.defaultShadow,
      ),
      child: Icon(
        Icons.person,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildConfidenceIndicator(double confidence) {
    final percentage = (confidence * 100).round();
    Color indicatorColor;
    
    if (confidence >= 0.8) {
      indicatorColor = AppTheme.success;
    } else if (confidence >= 0.6) {
      indicatorColor = AppTheme.warning;
    } else {
      indicatorColor = AppTheme.error;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: indicatorColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified,
            color: indicatorColor,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '$percentage% Confidence',
            style: TextStyle(
              color: indicatorColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcesWidget(List<String> sources) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sources:',
            style: TextStyle(
              color: _isDarkMode ? Colors.white70 : AppTheme.textGrey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: sources.map((source) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.info.withOpacity(0.3)),
              ),
              child: Text(
                source,
                style: TextStyle(
                  color: AppTheme.info,
                  fontSize: 10,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick suggestions:',
            style: TextStyle(
              color: _isDarkMode ? Colors.white70 : AppTheme.textGrey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _quickSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _quickSuggestions[index];
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () => _sendQuickSuggestion(suggestion['text']),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isDarkMode ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                        ),
                        boxShadow: AppTheme.defaultShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                suggestion['icon'],
                                color: AppTheme.primaryGreen,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  suggestion['category'],
                                  style: TextStyle(
                                    color: AppTheme.primaryGreen,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            suggestion['text'],
                            style: TextStyle(
                              color: _isDarkMode ? Colors.white : AppTheme.textDark,
                              fontSize: 12,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    if (!_isTyping) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildAIAvatar(),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.defaultShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _typingAnimation,
                  builder: (context, child) {
                    return Row(
                      children: List.generate(3, (index) {
                        final delay = index * 0.3;
                        final value = (_typingAnimation.value - delay).clamp(0.0, 1.0);
                        return Container(
                          margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                          child: Transform.translate(
                            offset: Offset(0, math.sin(value * 2 * math.pi) * -3),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  'AI is thinking...',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white70 : AppTheme.textGrey,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), // Added bottom padding
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
        border: Border(
          top: BorderSide(
            color: _isDarkMode ? Colors.grey[700]! : AppTheme.borderGrey,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end, // Align to bottom
            children: [
              Expanded(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: 120, // Limit max height
                  ),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.grey[700] : AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: _focusNode.hasFocus 
                        ? AppTheme.primaryGreen 
                        : (_isDarkMode ? Colors.grey[600]! : AppTheme.borderGrey),
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything about farming...',
                      hintStyle: TextStyle(
                        color: _isDarkMode ? Colors.white38 : AppTheme.textGrey,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.emoji_emotions_outlined,
                              color: _isDarkMode ? Colors.white54 : AppTheme.textGrey,
                            ),
                            onPressed: () {
                              setState(() => _showEmojiPanel = !_showEmojiPanel);
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.attach_file,
                              color: _isDarkMode ? Colors.white54 : AppTheme.textGrey,
                            ),
                            onPressed: _showAttachmentOptions,
                          ),
                        ],
                      ),
                    ),
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : AppTheme.textDark,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Send button with better visibility
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ScaleTransition(
                  scale: _fabAnimation,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    onPressed: _messageController.text.trim().isEmpty ? null : _sendMessage,
                    child: Icon(
                      _isTyping ? Icons.stop : Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_showEmojiPanel) _buildEmojiPanel(),
        ],
      ),
    );
  }

  Widget _buildEmojiPanel() {
    final emojis = ['🌾', '🚜', '🌱', '🌽', '🍅', '🥕', '🌶️', '🥔', '🌈', '☀️', '🌧️', '⛈️'];
    
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: emojis.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              _messageController.text += emojis[index];
              _messageController.selection = TextSelection.fromPosition(
                TextPosition(offset: _messageController.text.length),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[700] : AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                emojis[index],
                style: TextStyle(fontSize: 20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 100), // Add top padding to move below app bar
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Voice button - primary action
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              heroTag: "voice_input",
              backgroundColor: AppTheme.primaryGreen,
              onPressed: _showVoiceInputDialog,
              child: Icon(Icons.mic, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(height: 16),
          // Scroll to bottom - secondary action
          if (_messages.length > 5)
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentOrange.withOpacity(0.3),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: FloatingActionButton.small(
                heroTag: "scroll_to_bottom",
                backgroundColor: AppTheme.accentOrange,
                onPressed: _scrollToBottom,
                child: Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _sendQuickSuggestion(String message) {
    _messageController.text = message;
    _sendMessage();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _currentSession == null) return;

    // Clear input and hide suggestions
    _messageController.clear();
    setState(() {
      _showSuggestions = false;
      _isTyping = true;
      _showEmojiPanel = false;
    });

    try {
      // Add user message
      final userMessage = AIChatMessage(
        id: '',
        sessionId: _currentSession!.id,
        content: message,
        type: AIChatMessageType.user,
        timestamp: DateTime.now(),
        userId: FirebaseAuth.instance.currentUser?.uid,
      );

      print('Starting to send message: $message');
      await _aiChatService.addMessageToSession(_currentSession!.id, userMessage);
      print('User message added successfully');

      // Get AI response
      print('Getting AI response...');
      final aiResponse = await _aiChatService.askExpert(
        message,
        context: _selectedCategory,
      );
      print('AI response received: ${aiResponse.answer.substring(0, math.min(100, aiResponse.answer.length))}...');

      // Add AI message
      final aiMessage = AIChatMessage(
        id: '',
        sessionId: _currentSession!.id,
        content: aiResponse.answer,
        type: AIChatMessageType.ai,
        timestamp: DateTime.now(),
        confidence: aiResponse.confidence,
        sources: aiResponse.sources,
      );

      print('Adding AI message to session...');
      await _aiChatService.addMessageToSession(_currentSession!.id, aiMessage);
      print('AI message added successfully');

    } catch (e) {
      print('Error sending message: $e');
      _showError('Failed to send message: ${e.toString()}');
      
      // Add error message for user feedback
      final errorMessage = AIChatMessage(
        id: '',
        sessionId: _currentSession!.id,
        content: 'Sorry, I\'m having trouble connecting right now. Please try again in a moment.',
        type: AIChatMessageType.ai,
        timestamp: DateTime.now(),
        confidence: 0.0,
      );
      
      try {
        await _aiChatService.addMessageToSession(_currentSession!.id, errorMessage);
      } catch (e2) {
        print('Failed to add error message: $e2');
      }
    } finally {
      setState(() => _isTyping = false);
    }
  }

  void _addSystemMessage(String message) async {
    if (_currentSession == null) return;
    
    final systemMessage = AIChatMessage(
      id: '',
      sessionId: _currentSession!.id,
      content: message,
      type: AIChatMessageType.system,
      timestamp: DateTime.now(),
    );

    try {
      await _aiChatService.addMessageToSession(_currentSession!.id, systemMessage);
    } catch (e) {
      print('Failed to add system message: $e');
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'new_chat':
        _startNewChat();
        break;
      case 'export_chat':
        _exportChat();
        break;
      case 'clear_chat':
        _showClearChatDialog();
        break;
      case 'help':
        _showHelpDialog();
        break;
    }
  }

  void _startNewChat() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedAIExpertChatPage(),
      ),
    );
  }

  void _exportChat() {
    final chatText = _messages
        .where((m) => m.type != AIChatMessageType.system)
        .map((m) => '${m.isFromUser ? "You" : "AI Expert"}: ${m.content}')
        .join('\n\n');
    
    Clipboard.setData(ClipboardData(text: chatText));
    _showSuccess('Chat exported to clipboard!');
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Messages'),
        content: Text('This will remove all messages from this conversation. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearChat();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _clearChat() {
    if (_currentSession != null) {
      _aiChatService.deleteChatSession(_currentSession!.id);
      Navigator.pop(context);
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: AppTheme.info),
            const SizedBox(width: 8),
            Text('Help & Tips'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpItem(
                '🌾',
                'Ask specific questions',
                'Be specific about your crops, location, and problems for better advice.',
              ),
              _buildHelpItem(
                '📷',
                'Describe symptoms',
                'Describe plant symptoms, soil conditions, or weather patterns clearly.',
              ),
              _buildHelpItem(
                '🔍',
                'Use categories',
                'Change the consultation category for specialized advice.',
              ),
              _buildHelpItem(
                '💬',
                'Follow up',
                'Ask follow-up questions to get more detailed guidance.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add to your message',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  Icons.photo_camera,
                  'Camera',
                  () {
                    Navigator.pop(context);
                    _showComingSoon('Camera feature');
                  },
                ),
                _buildAttachmentOption(
                  Icons.photo_library,
                  'Gallery',
                  () {
                    Navigator.pop(context);
                    _showComingSoon('Gallery feature');
                  },
                ),
                _buildAttachmentOption(
                  Icons.location_on,
                  'Location',
                  () {
                    Navigator.pop(context);
                    _addLocationToMessage();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryGreen,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _addLocationToMessage() {
    final locationText = "\n📍 Location: [Your Farm Location]";
    _messageController.text += locationText;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
  }

  void _showVoiceInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.mic, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            Text('Voice Input'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.mic_none,
                    size: 48,
                    color: AppTheme.primaryGreen,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Voice input feature coming soon!',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'re working on adding voice recognition to make your farming consultations even more convenient.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'For now, you can:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.keyboard, size: 16, color: AppTheme.textGrey),
                    const SizedBox(width: 8),
                    Text('Type your questions', style: TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.touch_app, size: 16, color: AppTheme.textGrey),
                    const SizedBox(width: 8),
                    Text('Use quick suggestions', style: TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.emoji_emotions, size: 16, color: AppTheme.textGrey),
                    const SizedBox(width: 8),
                    Text('Add emojis for context', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: AppTheme.info,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.success,
      ),
    );
  }
}