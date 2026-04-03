import 'dart:ui';
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
  State<WhatsAppStyleContactSellerPage> createState() => _WhatsAppStyleContactSellerPageState();
}

class _WhatsAppStyleContactSellerPageState extends State<WhatsAppStyleContactSellerPage>
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
  late Animation<double> _typingAnimation;
  
  // State variables
  bool _isSending = false;
  bool _isTyping = false;
  User? _currentUser;
  EnhancedConversation? _currentConversation;
  
  // UI State
  bool _showBidCard = true;
  bool _isCardExpanded = false;
  bool _showEmojiPicker = false;
  bool _isRecording = false;
  
  // Typing indicator
  String _typingIndicatorText = '';

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
    
    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingController,
      curve: Curves.elasticInOut,
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
        final conversationId = await _chatService.createOrGetEnhancedConversation(
          product: widget.product!,
          buyerName: _currentUser?.displayName ?? _currentUser?.email ?? 'Buyer',
        );
        
        final conversation = await _chatService.getEnhancedConversation(conversationId);
        setState(() {
          _currentConversation = conversation;
        });
      } catch (e) {
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
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFECE5DD), // WhatsApp background color
      appBar: _buildWhatsAppAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Background pattern (optional)
            _buildBackgroundPattern(),
            
            // Main chat content
            Column(
              children: [
                // Product banner
                _buildEnhancedProductBanner(),
                
                // Messages list
                Expanded(
                  child: _buildMessagesStream(),
                ),
                
                // Typing indicator
                _buildTypingIndicator(),
                
                // Message input
                _buildWhatsAppMessageInput(),
              ],
            ),
            
            // Floating bid card
            if (_showBidCard)
              SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _bidCardAnimation,
                  child: _buildEnhancedBidCard(),
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
            'phone': _currentConversation!.sellerPhone,
          }
        : {
            'name': _currentConversation!.buyerName,
            'avatar': _currentConversation!.buyerAvatar,
            'phone': _currentConversation!.buyerPhone,
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
          // Profile picture
          GestureDetector(
            onTap: _showUserProfile,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white.withOpacity(0.2),
              backgroundImage: otherUser['avatar']?.isNotEmpty == true
                  ? CachedNetworkImageProvider(otherUser['avatar']!)
                  : null,
              child: otherUser['avatar']?.isEmpty != false
                  ? Text(
                      otherUser['name']?.isNotEmpty == true
                          ? otherUser['name']![0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          
          // User info
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
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 1),
                  StreamBuilder<List<TypingIndicator>>(
                    stream: _chatService.getTypingIndicators(_currentConversation!.id),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        return AnimatedBuilder(
                          animation: _typingAnimation,
                          builder: (context, child) {
                            return const Text(
                              'typing...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                              ),
                            );
                          },
                        );
                      }
                      return const Text(
                        'Tap for product info',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Video call button
        IconButton(
          onPressed: () => _initiateCall(CallType.video),
          icon: const Icon(Icons.videocam, color: Colors.white),
          tooltip: 'Video Call',
        ),
        
        // Audio call button
        IconButton(
          onPressed: () => _initiateCall(CallType.call),
          icon: const Icon(Icons.call, color: Colors.white),
          tooltip: 'Voice Call',
        ),
        
        // More options
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          icon: const Icon(Icons.more_vert, color: Colors.white),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'product_details',
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 8),
                  Text('Product Details'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle_bid_card',
              child: Row(
                children: [
                  Icon(_showBidCard ? Icons.visibility_off : Icons.visibility),
                  const SizedBox(width: 8),
                  Text(_showBidCard ? 'Hide Bid Card' : 'Show Bid Card'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear_chat',
              child: Row(
                children: [
                  Icon(Icons.clear_all),
                  SizedBox(width: 8),
                  Text('Clear Chat'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'block_user',
              child: Row(
                children: [
                  Icon(Icons.block, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Block User'),
                ],
              ),
            ),
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
              image: AssetImage('assets/images/whatsapp_bg.png'), // Add WhatsApp pattern
              repeat: ImageRepeat.repeat,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedProductBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main product info row
          Row(
            children: [
              // Product image carousel
              _buildProductImageCarousel(),
              
              const SizedBox(width: 16),
              
              // Product details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentConversation!.productName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.getTextColor(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Price and bidding info
                    Row(
                      children: [
                        Text(
                          '₹${_currentConversation!.productPrice}',
                          style: TextStyle(
                            color: AppTheme.getPrimaryAccent(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '/${_currentConversation!.productUnit}',
                          style: TextStyle(
                            color: AppTheme.getSecondaryTextColor(context),
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        if (_currentConversation!.currentHighestBid != null &&
                            _currentConversation!.currentHighestBid! > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppTheme.accentOrange.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'Highest: ₹${_currentConversation!.currentHighestBid}',
                              style: const TextStyle(
                                color: AppTheme.accentOrange,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Quick info chips
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildInfoChip(
                          Icons.location_on,
                          _currentConversation!.productDetails['location'] ?? 'Unknown',
                          Colors.blue,
                        ),
                        _buildInfoChip(
                          Icons.category,
                          _currentConversation!.productDetails['category'] ?? 'Unknown',
                          Colors.green,
                        ),
                        if (_currentConversation!.totalBids > 0)
                          _buildInfoChip(
                            Icons.local_offer,
                            '${_currentConversation!.totalBids} bids',
                            Colors.orange,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Quick action buttons
              Column(
                children: [
                  _buildQuickActionButton(
                    Icons.local_offer,
                    'Bid',
                    AppTheme.accentOrange,
                    _showQuickBidDialog,
                  ),
                  const SizedBox(height: 8),
                  _buildQuickActionButton(
                    Icons.info_outline,
                    'Info',
                    AppTheme.getPrimaryAccent(context),
                    _showDetailedProductInfo,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductImageCarousel() {
    final images = _currentConversation!.productImages.isNotEmpty
        ? _currentConversation!.productImages
        : [_currentConversation!.productImageUrl];

    if (images.isEmpty || images.first.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.image, color: Colors.grey[600], size: 40),
      );
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: PageView.builder(
          itemCount: images.length,
          itemBuilder: (context, index) {
            return CachedNetworkImage(
              imageUrl: images[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: Icon(Icons.image, color: Colors.grey[600]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesStream() {
    return StreamBuilder<List<EnhancedChatMessage>>(
      stream: _chatService.getEnhancedMessages(_currentConversation!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Failed to load messages',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final messages = snapshot.data ?? [];
        
        if (messages.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.only(
            left: _showBidCard ? 220 : 8,
            right: 8,
            top: 8,
            bottom: 8,
          ),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = message.senderId == _currentUser?.uid;
            final showDateHeader = _shouldShowDateHeader(messages, index);
            
            return Column(
              children: [
                if (showDateHeader) _buildDateHeader(message.timestamp),
                _buildEnhancedMessageBubble(message, isMe),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(left: _showBidCard ? 220 : 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 60,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Start your conversation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Discuss about ${_currentConversation!.productName}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _messageController.text = 'Hi! I\'m interested in your ${_currentConversation!.productName}. ';
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.chat),
                  label: const Text('Start Chat'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showQuickBidDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.local_offer),
                  label: const Text('Make Offer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowDateHeader(List<EnhancedChatMessage> messages, int index) {
    if (index == 0) return true;
    
    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];
    
    final currentDate = DateTime(
      currentMessage.timestamp.year,
      currentMessage.timestamp.month,
      currentMessage.timestamp.day,
    );
    
    final previousDate = DateTime(
      previousMessage.timestamp.year,
      previousMessage.timestamp.month,
      previousMessage.timestamp.day,
    );
    
    return !currentDate.isAtSameMomentAs(previousDate);
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String dateText;
    if (messageDate.isAtSameMomentAs(today)) {
      dateText = 'Today';
    } else if (messageDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      dateText = 'Yesterday';
    } else {
      dateText = '${date.day}/${date.month}/${date.year}';
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateText,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(EnhancedChatMessage message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.reply, color: isDark ? Colors.white70 : null),
              title: Text('Reply', style: TextStyle(color: isDark ? Colors.white : null)),
              onTap: () {
                Navigator.pop(context);
                // Implement reply functionality
              },
            ),
            ListTile(
              leading: Icon(Icons.copy, color: isDark ? Colors.white70 : null),
              title: Text('Copy', style: TextStyle(color: isDark ? Colors.white : null)),
              onTap: () {
                Navigator.pop(context);
                // Implement copy functionality
              },
            ),
            if (message.senderId == _currentUser?.uid)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  // Implement delete functionality
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showClearChatDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : null,
        title: Text('Clear Chat', style: TextStyle(color: isDark ? Colors.white : null)),
        content: Text('Are you sure you want to clear all messages? This action cannot be undone.', style: TextStyle(color: isDark ? Colors.white70 : null)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement clear chat functionality
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showBlockUserDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : null,
        title: Text('Block User', style: TextStyle(color: isDark ? Colors.white : null)),
        content: Text('Are you sure you want to block this user? They will no longer be able to contact you.', style: TextStyle(color: isDark ? Colors.white70 : null)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement block user functionality
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview(String replyToMessageId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: AppTheme.getPrimaryAccent(context), width: 3)),
      ),
      child: Text(
        'Reply preview...', // Implement actual reply preview
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white60 : Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  void _showUserProfile() {
    // Show user profile modal
    print('Show user profile');
  }

  void _showDetailedProductInfo() {
    // Show detailed product information
    print('Show product details');
  }

  void _showFullScreenImage(String imageUrl) {
    // Show full screen image viewer
    print('Show full screen image: $imageUrl');
  }

  void _playVideo(String videoUrl) {
    // Play video
    print('Play video: $videoUrl');
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'product_details':
        _showDetailedProductInfo();
        break;
      case 'toggle_bid_card':
        setState(() {
          _showBidCard = !_showBidCard;
        });
        break;
      case 'clear_chat':
        _showClearChatDialog();
        break;
      case 'block_user':
        _showBlockUserDialog();
        break;
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

  // Helper methods for bid card
  IconData _getBidStatusIcon(BidStatus status) {
    switch (status) {
      case BidStatus.accepted:
        return Icons.check_circle;
      case BidStatus.rejected:
        return Icons.cancel;
      case BidStatus.negotiating:
        return Icons.chat;
      case BidStatus.expired:
        return Icons.access_time;
      default:
        return Icons.schedule;
    }
  }

  Color _getBidStatusColor(BidStatus status) {
    switch (status) {
      case BidStatus.accepted:
        return Colors.green;
      case BidStatus.rejected:
        return Colors.red;
      case BidStatus.negotiating:
        return Colors.blue;
      case BidStatus.expired:
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _formatBidTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}
