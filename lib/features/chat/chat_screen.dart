import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/conversation_model.dart';
import '../../models/product_model.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../marketplace/product_detail_page.dart';

/// Individual chat screen for seller-buyer communication
class ChatScreen extends StatefulWidget {
  final String conversationId;
  final Product? product;
  final String? otherUserId;
  final String? otherUserName;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.product,
    this.otherUserId,
    this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  Conversation? _conversation;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadConversation();
    _markAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversation() async {
    // Mark as read when opening
    await _chatService.markAsRead(widget.conversationId);
  }

  void _markAsRead() {
    _chatService.markAsRead(widget.conversationId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (widget.product != null) _buildProductHeader(),
          Expanded(
            child: _buildMessagesList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  /// Build app bar with user info and actions
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.getAppBarColor(context),
      foregroundColor: AppTheme.getAppBarTextColor(context),
      elevation: 1,
      title: GestureDetector(
        onTap: _showUserProfile,
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                widget.otherUserName?.isNotEmpty == true
                    ? widget.otherUserName![0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName ?? 'User',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getAppBarTextColor(context),
                    ),
                  ),
                  Text(
                    'Tap for profile',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.getAppBarTextColor(context).withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: AppTheme.getAppBarTextColor(context)),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view_product',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 18),
                  SizedBox(width: 8),
                  Text('View Product'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(Icons.block, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Block User', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build product header
  Widget _buildProductHeader() {
    if (widget.product == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: AppTheme.getDividerColor(context)),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: widget.product!.imageUrls.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.product!.imageUrls.first,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      width: 50,
                      height: 50,
                      color: isDark ? AppTheme.darkHighlight : Colors.grey.shade200,
                      child: Icon(Icons.image, color: AppTheme.getSecondaryTextColor(context)),
                    ),
                  )
                : Container(
                    width: 50,
                    height: 50,
                    color: isDark ? AppTheme.darkHighlight : Colors.grey.shade200,
                    child: Icon(Icons.image, color: AppTheme.getSecondaryTextColor(context)),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product!.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '₹${widget.product!.price.toInt()}/${widget.product!.unit}',
                  style: TextStyle(
                    color: AppTheme.getPrimaryAccent(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _viewProduct,
            child: Text('View', style: TextStyle(color: AppTheme.getPrimaryAccent(context))),
          ),
        ],
      ),
    );
  }

  /// Build messages list
  Widget _buildMessagesList() {
    return StreamBuilder<List<Message>>(
      stream: _chatService.getMessages(widget.conversationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.getPrimaryAccent(context)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final messages = snapshot.data!;
        
        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = message.senderId == _currentUserId;
            
            return _buildMessageBubble(message, isMe);
          },
        );
      },
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppTheme.getSecondaryTextColor(context).withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Start the conversation!',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.getSecondaryTextColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to begin chatting',
            style: TextStyle(
              color: AppTheme.getSecondaryTextColor(context).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Build message bubble
  Widget _buildMessageBubble(Message message, bool isMe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.getPrimaryAccent(context) : Theme.of(context).cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: !isMe && isDark ? Border.all(color: AppTheme.getBorderColor(context)) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildMessageContent(message, isMe),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.getSecondaryTextColor(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build message content based on type
  Widget _buildMessageContent(Message message, bool isMe) {
    switch (message.type) {
      case MessageType.image:
        return _buildImageMessage(message, isMe);
      case MessageType.system:
        return _buildSystemMessage(message);
      default:
        return Text(
          message.content,
          style: TextStyle(
            color: isMe ? Colors.white : AppTheme.getTextColor(context),
            fontSize: 16,
          ),
        );
    }
  }

  /// Build bid message (currently disabled - feature coming soon)
  /*
  Widget _buildBidMessage(Message message, bool isMe) {
    final bid = message.bidOffer!;
    final isExpired = bid.validUntil.isBefore(DateTime.now());
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.local_offer,
              color: isMe ? Colors.white : AppTheme.primaryGreen,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Bid Offer',
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '₹${bid.amount.toStringAsFixed(0)} for ${bid.quantity} ${bid.unit}',
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (bid.notes?.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Text(
            bid.notes!,
            style: TextStyle(
              color: isMe ? Colors.white70 : Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              _getBidStatusText(bid.status),
              style: TextStyle(
                color: isMe ? Colors.white70 : _getBidStatusColor(bid.status),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (!isExpired && bid.status == BidStatus.pending && !isMe)
              Row(
                children: [
                  TextButton(
                    onPressed: () => _respondToBid(message.id, 'rejected'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(60, 30),
                    ),
                    child: const Text('Decline', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton(
                    onPressed: () => _respondToBid(message.id, 'accepted'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(60, 30),
                    ),
                    child: const Text('Accept', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
  */

  /// Build image message
  Widget _buildImageMessage(Message message, bool isMe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: message.imageUrl!,
              width: 200,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 200,
                height: 150,
                color: isDark ? AppTheme.darkHighlight : Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                width: 200,
                height: 150,
                color: isDark ? AppTheme.darkHighlight : Colors.grey.shade200,
                child: Icon(Icons.error, color: AppTheme.getSecondaryTextColor(context)),
              ),
            ),
          ),
        if (message.content.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            message.content,
            style: TextStyle(
              color: isMe ? Colors.white : AppTheme.getTextColor(context),
              fontSize: 16,
            ),
          ),
        ],
      ],
    );
  }

  /// Build system message
  Widget _buildSystemMessage(Message message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.3)),
      ),
      child: Text(
        message.content,
        style: TextStyle(
          color: AppTheme.getSecondaryTextColor(context),
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Build message input
  Widget _buildMessageInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: AppTheme.getDividerColor(context)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: _showBidDialog,
              icon: const Icon(Icons.local_offer),
              color: AppTheme.getPrimaryAccent(context),
              tooltip: 'Make Bid Offer',
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkHighlight : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(color: AppTheme.getTextColor(context)),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context).withOpacity(0.6)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (value) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isLoading ? null : _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.getPrimaryAccent(context),
                  shape: BoxShape.circle,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Send message
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);
    _messageController.clear();

    try {
      await _chatService.sendMessage(
        conversationId: widget.conversationId,
        content: message,
      );
      
      // Scroll to bottom
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      _showMessage('Failed to send message: $e', isError: true);
      _messageController.text = message; // Restore message on error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Show bid dialog
  void _showBidDialog() {
    if (widget.product == null) return;
    
    // TODO: Implement bid dialog when BidDialog widget is available
    _showMessage('Bid feature coming soon!');
    
    /* Commented out until BidDialog is implemented
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BidDialog(
        product: widget.product!,
        onBidSubmitted: (amount, quantity, notes) async {
          try {
            await _chatService.sendBidOffer(
              conversationId: widget.conversationId,
              amount: amount,
              quantity: quantity,
              unit: widget.product!.unit,
              notes: notes,
            );
            _showMessage('Bid offer sent successfully!');
          } catch (e) {
            _showMessage('Failed to send bid: $e', isError: true);
          }
        },
      ),
    );
    */
  }

  /// Show user profile
  void _showUserProfile() {
    if (widget.otherUserId == null) return;
    
    // TODO: Implement user profile when dialog and API are available
    _showMessage('User profile feature coming soon!');
    
    /* Commented out until BuyerProfileDialog and rateUser are implemented
    showDialog(
      context: context,
      builder: (context) => BuyerProfileDialog(
        buyerId: widget.otherUserId!,
        onRateUser: (rating, review) async {
          try {
            await _chatService.rateUser(
              userId: widget.otherUserId!,
              rating: rating,
              review: review,
            );
            _showMessage('Rating submitted successfully!');
          } catch (e) {
            _showMessage('Failed to submit rating: $e', isError: true);
          }
        },
      ),
    );
    */
  }

  /// View product
  void _viewProduct() {
    if (widget.product == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(product: widget.product!),
      ),
    );
  }

  /// Respond to bid
  Future<void> _respondToBid(String messageId, String status) async {
    // TODO: Implement when respondToBid API is available
    _showMessage('Bid response feature coming soon!');
    
    /* Commented out until respondToBid is implemented
    try {
      await _chatService.respondToBid(
        messageId: messageId,
        status: status,
      );
      
      final statusText = status == 'accepted' ? 'accepted' : 'declined';
      _showMessage('Bid $statusText successfully!');
    } catch (e) {
      _showMessage('Failed to respond to bid: $e', isError: true);
    }
    */
  }

  /// Handle menu actions
  void _handleMenuAction(String action) {
    switch (action) {
      case 'view_product':
        _viewProduct();
        break;
      case 'block':
        _showBlockConfirmation();
        break;
    }
  }

  /// Show block confirmation
  void _showBlockConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: const Text('Block feature coming soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    
    /* Commented out until blockUser is implemented
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: const Text('Are you sure you want to block this user? You won\'t receive any more messages from them.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _chatService.blockUser(
                  conversationId: widget.conversationId,
                  userId: widget.otherUserId!,
                );
                _showMessage('User blocked successfully');
                Navigator.pop(context);
              } catch (e) {
                _showMessage('Failed to block user: $e', isError: true);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    */
  }

  /// Format time
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  /// Get bid status text (currently disabled - feature coming soon)
  /*
  String _getBidStatusText(BidStatus status) {
    switch (status) {
      case BidStatus.pending:
        return 'Pending';
      case BidStatus.accepted:
        return 'Accepted';
      case BidStatus.rejected:
        return 'Declined';
      case BidStatus.expired:
        return 'Expired';
      case BidStatus.withdrawn:
        return 'Withdrawn';
    }
  }

  /// Get bid status color (currently disabled - feature coming soon)
  Color _getBidStatusColor(BidStatus status) {
    switch (status) {
      case BidStatus.pending:
        return Colors.orange;
      case BidStatus.accepted:
        return Colors.green;
      case BidStatus.rejected:
        return Colors.red;
      case BidStatus.expired:
        return Colors.grey;
      case BidStatus.withdrawn:
        return Colors.grey;
    }
  }
  */

  /// Show message
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}