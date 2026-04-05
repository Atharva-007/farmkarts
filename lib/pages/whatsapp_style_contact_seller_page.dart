import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/enhanced_chat_models.dart';
import '../models/product_model.dart';
import '../services/enhanced_chat_service.dart';
import '../utils/media_service.dart';
import '../theme/app_theme.dart';
import '../utils/toast_helper.dart';

/// WhatsApp-Style Enhanced Contact Seller Page
class WhatsAppStyleContactSellerPage extends StatefulWidget {
  final EnhancedConversation? conversation;
  final Product? product;
  final String? conversationId;
  final String? otherUserId;
  final String? otherUserName;

  const WhatsAppStyleContactSellerPage({
    super.key,
    this.conversation,
    this.product,
    this.conversationId,
    this.otherUserId,
    this.otherUserName,
  });

  @override
  State<WhatsAppStyleContactSellerPage> createState() =>
      _WhatsAppStyleContactSellerPageState();
}

class _WhatsAppStyleContactSellerPageState
    extends State<WhatsAppStyleContactSellerPage>
    with TickerProviderStateMixin {
  final EnhancedChatService _chatService = EnhancedChatService();
  final MediaService _mediaService = MediaService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Animations
  late AnimationController _animationController;
  late AnimationController _bidCardController;
  late AnimationController _typingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bidCardAnimation;

  // State variables
  bool _isSending = false;
  bool _isTyping = false;
  User? _currentUser;
  EnhancedConversation? _currentConversation;

  // UI State
  bool _showBidCard = true;
  bool _isCardExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _setupAnimations();
    _initializeConversation();
    _setupMessageController();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _bidCardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _bidCardAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bidCardController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
    _bidCardController.forward();
    _typingController.repeat();
  }

  void _setupMessageController() {
    _messageController.addListener(() {
      final isTyping = _messageController.text.isNotEmpty;
      if (isTyping != _isTyping) {
        setState(() {
          _isTyping = isTyping;
        });
        if (_currentConversation != null) {
          _chatService.updateTypingStatus(_currentConversation!.id, isTyping);
        }
      }
    });
  }

  Future<void> _initializeConversation() async {
    if (widget.conversation != null) {
      setState(() {
        _currentConversation = widget.conversation;
      });
    } else if (widget.product != null) {
      try {
        final conversationId =
            await _chatService.createOrGetEnhancedConversation(
          product: widget.product!,
          buyerName:
              _currentUser?.displayName ?? _currentUser?.email ?? 'Buyer',
        );

        final conversation =
            await _chatService.getEnhancedConversation(conversationId);
        setState(() {
          _currentConversation = conversation;
        });
      } catch (e) {
        if (mounted)
          ToastHelper.showError(context, 'Failed to load conversation: $e');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bidCardController.dispose();
    _typingController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentConversation == null) {
      return Scaffold(
        backgroundColor: AppTheme.getBackgroundColor(context),
        appBar: AppBar(title: const Text('Loading...')),
        body: Center(
            child: CircularProgressIndicator(
                color: AppTheme.getPrimaryAccent(context))),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackground : const Color(0xFFECE5DD),
      appBar: _buildWhatsAppAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            _buildBackgroundPattern(),
            Column(
              children: [
                _buildEnhancedProductBanner(),
                Expanded(
                  child: _buildMessagesStream(),
                ),
                _buildTypingIndicator(),
                _buildWhatsAppMessageInput(),
              ],
            ),
            if (_showBidCard)
              Positioned(
                left: 16,
                top: 100,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ScaleTransition(
                    scale: _bidCardAnimation,
                    child: _buildEnhancedBidCard(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildWhatsAppAppBar() {
    final otherUser = _currentUser?.uid == _currentConversation!.buyerId
        ? {
            'name': _currentConversation!.sellerName,
            'avatar': _currentConversation!.sellerAvatar,
          }
        : {
            'name': _currentConversation!.buyerName,
            'avatar': _currentConversation!.buyerAvatar,
          };

    return AppBar(
      backgroundColor: AppTheme.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 1,
      titleSpacing: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      title: Row(
        children: [
          GestureDetector(
            onTap: _showUserProfile,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              backgroundImage: otherUser['avatar']?.isNotEmpty == true
                  ? CachedNetworkImageProvider(otherUser['avatar']!)
                  : null,
              child: otherUser['avatar']?.isEmpty != false
                  ? Text(
                      otherUser['name']?.isNotEmpty == true
                          ? otherUser['name']![0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _showUserProfile,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    otherUser['name'] ?? 'Unknown User',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  const Text(
                    'Tap for info',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _initiateCall(CallType.video),
          icon: const Icon(Icons.videocam, color: Colors.white),
        ),
        IconButton(
          onPressed: () => _initiateCall(CallType.audio),
          icon: const Icon(Icons.call, color: Colors.white),
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          icon: const Icon(Icons.more_vert, color: Colors.white),
          itemBuilder: (context) => [
            const PopupMenuItem(
                value: 'product_details', child: Text('Product Details')),
            PopupMenuItem(
              value: 'toggle_bid_card',
              child: Text(_showBidCard ? 'Hide Bid Card' : 'Show Bid Card'),
            ),
            const PopupMenuItem(value: 'clear_chat', child: Text('Clear Chat')),
          ],
        ),
      ],
    );
  }

  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: Opacity(
        opacity: Theme.of(context).brightness == Brightness.dark ? 0.05 : 0.1,
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/whatsapp_bg.png'),
              repeat: ImageRepeat.repeat,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedProductBanner() {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: _currentConversation!.productImageUrl.isNotEmpty
                  ? DecorationImage(
                      image:
                          NetworkImage(_currentConversation!.productImageUrl),
                      fit: BoxFit.cover)
                  : null,
            ),
            child: _currentConversation!.productImageUrl.isEmpty
                ? const Icon(Icons.image)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_currentConversation!.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('₹${_currentConversation!.productPrice}',
                    style:
                        TextStyle(color: AppTheme.getPrimaryAccent(context))),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.local_offer, color: Colors.orange),
            onPressed: _showQuickBidDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesStream() {
    return StreamBuilder<List<EnhancedChatMessage>>(
      stream: _chatService.getEnhancedMessages(_currentConversation!.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final messages = snapshot.data!;
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = message.senderId == _currentUser?.uid;
            return _buildEnhancedMessageBubble(message, isMe);
          },
        );
      },
    );
  }

  Widget _buildEnhancedMessageBubble(EnhancedChatMessage message, bool isMe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4, top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe
              ? (isDark ? const Color(0xFF005C4B) : const Color(0xFFE7FFDB))
              : (isDark ? const Color(0xFF202C33) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, 1)),
          ],
        ),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 2),
            Text(
              '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white60 : Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return StreamBuilder<List<TypingIndicator>>(
      stream: _chatService.getTypingIndicators(_currentConversation!.id),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('typing...',
                style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AppTheme.getSecondaryTextColor(context))),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildWhatsAppMessageInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202C33) : Colors.white,
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: _showAttachmentOptions),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A3942) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              onPressed: _sendMessage,
              mini: true,
              backgroundColor: AppTheme.primaryGreen,
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedBidCard() {
    return GestureDetector(
      onTap: () => setState(() => _isCardExpanded = !_isCardExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isCardExpanded ? 250 : 180,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.local_offer, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                const Text('Bidding',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Icon(_isCardExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18),
              ],
            ),
            if (_isCardExpanded) ...[
              const SizedBox(height: 8),
              Text('Current: ₹${_currentConversation!.currentHighestBid ?? 0}'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _showQuickBidDialog,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white),
                child: const Text('Bid Now'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      final otherUserId = _currentUser?.uid == _currentConversation!.buyerId
          ? _currentConversation!.sellerId
          : _currentConversation!.buyerId;
      await _chatService.sendEnhancedMessage(
        conversationId: _currentConversation!.id,
        content: text,
        type: MessageType.text,
        receiverId: otherUserId ?? '',
      );
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) ToastHelper.showError(context, 'Failed to send message');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _showAttachmentOptions() async {
    await _mediaService.showMediaPicker(
      context,
      onImageSelected: (file) => _sendMedia(file, MessageType.image),
      onVideoSelected: (file) => _sendMedia(file, MessageType.video),
      onDocumentSelected: (file) => _sendMedia(file, MessageType.document),
    );
  }

  Future<void> _sendMedia(File file, MessageType type) async {
    try {
      await _chatService.sendMediaMessage(
          conversationId: _currentConversation!.id, file: file, type: type);
      _scrollToBottom();
    } catch (e) {
      if (mounted) ToastHelper.showError(context, 'Failed to send media');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _initiateCall(CallType type) async {
    final otherUserId = _currentUser?.uid == _currentConversation!.buyerId
        ? _currentConversation!.sellerId
        : _currentConversation!.buyerId;
    final otherUserName = _currentUser?.uid == _currentConversation!.buyerId
        ? _currentConversation!.sellerName
        : _currentConversation!.buyerName;
    await _mediaService.initiateCall(
        context, otherUserId ?? '', otherUserName ?? '', type);
  }

  void _handleMenuAction(String action) {
    if (action == 'toggle_bid_card')
      setState(() => _showBidCard = !_showBidCard);
  }

  void _showUserProfile() {}

  Future<void> _showQuickBidDialog() async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Place Bid'),
        content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null) {
                _chatService.sendBidOffer(
                    conversationId: _currentConversation!.id,
                    amount: amount,
                    quantity: 1,
                    unit: _currentConversation!.productUnit);
                Navigator.pop(context);
              }
            },
            child: const Text('Place'),
          ),
        ],
      ),
    );
  }
}
