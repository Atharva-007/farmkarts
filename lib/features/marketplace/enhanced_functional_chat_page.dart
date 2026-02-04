import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../models/product_model.dart';
import '../../models/chat_model.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';

/// Enhanced chat page for seller-buyer communication
class EnhancedFunctionalChatPage extends StatefulWidget {
  final String conversationId;
  final Product product;

  const EnhancedFunctionalChatPage({
    super.key,
    required this.conversationId,
    required this.product,
  });

  @override
  State<EnhancedFunctionalChatPage> createState() => _EnhancedFunctionalChatPageState();
}

class _EnhancedFunctionalChatPageState extends State<EnhancedFunctionalChatPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = true;
  bool _isSending = false;
  List<ChatMessage> _messages = [];
  ChatConversation? _conversation;
  
  @override
  void initState() {
    super.initState();
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
    try {
      // Mark conversation as read
      await _chatService.markAsRead(widget.conversationId);
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  void _markAsRead() {
    Future.delayed(const Duration(seconds: 1), () {
      _chatService.markAsRead(widget.conversationId);
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      await _chatService.sendMessage(
        conversationId: widget.conversationId,
        message: messageText,
        type: MessageType.text,
      );

      _messageController.clear();
      
      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      _showErrorMessage('Failed to send message: $e');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _sendBid() async {
    final bidController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Bid Offer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: bidController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Bid Amount',
                  prefixText: '₹',
                  suffixText: 'per ${widget.product.unit}',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  suffixText: widget.product.unit,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(bidController.text);
              final quantity = int.tryParse(quantityController.text);
              
              if (amount != null && quantity != null && amount > 0 && quantity > 0) {
                Navigator.pop(context);
                
                try {
                  await _chatService.sendBidOffer(
                    conversationId: widget.conversationId,
                    amount: amount,
                    quantity: quantity,
                    unit: widget.product.unit,
                    notes: notesController.text.trim().isNotEmpty 
                        ? notesController.text.trim() 
                        : null,
                  );
                  _showSuccessMessage('Bid sent successfully!');
                } catch (e) {
                  _showErrorMessage('Failed to send bid: $e');
                }
              } else {
                _showErrorMessage('Please enter valid amount and quantity');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Bid'),
          ),
        ],
      ),
    );
  }

  Future<void> _respondToBid(ChatMessage message, BidStatus status) async {
    try {
      final response = status == BidStatus.accepted 
          ? 'Bid accepted! Please contact me to proceed with the transaction.'
          : 'Sorry, I cannot accept this bid at this time.';
          
      await _chatService.respondToBid(
        messageId: message.id,
        status: status,
        responseMessage: response,
      );
      
      _showSuccessMessage(status == BidStatus.accepted 
          ? 'Bid accepted!' 
          : 'Bid declined');
    } catch (e) {
      _showErrorMessage('Failed to respond to bid: $e');
    }
  }

  void _showSuccessMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: AppTheme.success,
      textColor: Colors.white,
    );
  }

  void _showErrorMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: AppTheme.error,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isSeller = currentUser?.uid == widget.product.sellerId;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.product.name),
            Text(
              isSeller ? 'Buyer Chat' : 'Seller Chat',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          if (!isSeller)
            IconButton(
              onPressed: _sendBid,
              icon: const Icon(Icons.local_offer),
              tooltip: 'Send Bid',
            ),
        ],
      ),
      body: Column(
        children: [
          // Product info header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: widget.product.imageUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.product.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.image, color: Colors.grey);
                            },
                          ),
                        )
                      : const Icon(Icons.image, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '₹${widget.product.price.toStringAsFixed(2)} per ${widget.product.unit}',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Messages list
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('Error loading messages: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {});
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                _messages = snapshot.data ?? [];
                
                if (_messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _buildMessageBubble(message, currentUser?.uid);
                  },
                );
              },
            ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isSending ? null : _sendMessage,
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, String? currentUserId) {
    final isMe = message.senderId == currentUserId;
    final isSeller = currentUserId == widget.product.sellerId;
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: 8,
        left: isMe ? 50 : 0,
        right: isMe ? 0 : 50,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              backgroundColor: AppTheme.primaryGreen,
              radius: 16,
              child: Text(
                message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? AppTheme.primaryGreen : Colors.grey[200],
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.type == MessageType.bid && message.bidOffer != null)
                        _buildBidMessage(message, isMe, isSeller),
                      
                      Text(
                        message.message,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppTheme.primaryGreen,
              radius: 16,
              child: Text(
                message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBidMessage(ChatMessage message, bool isMe, bool isSeller) {
    final bid = message.bidOffer!;
    final totalAmount = bid.amount * bid.quantity;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe 
            ? Colors.white.withOpacity(0.2) 
            : AppTheme.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.warning.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_offer,
                color: isMe ? Colors.white : AppTheme.warning,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Bid Offer',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isMe ? Colors.white : AppTheme.warning,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Amount: ₹${bid.amount.toStringAsFixed(2)} per ${bid.unit}',
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 14,
            ),
          ),
          Text(
            'Quantity: ${bid.quantity} ${bid.unit}',
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 14,
            ),
          ),
          Text(
            'Total: ₹${totalAmount.toStringAsFixed(2)}',
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          if (bid.notes != null && bid.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Notes: ${bid.notes}',
              style: TextStyle(
                color: isMe ? Colors.white.withOpacity(0.8) : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
          
          // Bid status and actions
          const SizedBox(height: 8),
          if (bid.status == BidStatus.pending && isSeller && !isMe) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () => _respondToBid(message, BidStatus.accepted),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 30),
                  ),
                  child: const Text('Accept', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _respondToBid(message, BidStatus.rejected),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: BorderSide(color: AppTheme.error),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 30),
                  ),
                  child: const Text('Decline', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getBidStatusColor(bid.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getBidStatusText(bid.status),
                style: TextStyle(
                  color: _getBidStatusColor(bid.status),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBidStatusColor(BidStatus status) {
    switch (status) {
      case BidStatus.pending:
        return AppTheme.warning;
      case BidStatus.accepted:
        return AppTheme.success;
      case BidStatus.rejected:
        return AppTheme.error;
      case BidStatus.expired:
        return Colors.grey;
      case BidStatus.withdrawn:
        return Colors.grey;
    }
  }

  String _getBidStatusText(BidStatus status) {
    switch (status) {
      case BidStatus.pending:
        return 'Pending Response';
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

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}