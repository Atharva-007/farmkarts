import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/conversation_model.dart';
import '../models/product_model.dart';
import '../services/chat_service.dart';
import '../services/conversation_service.dart';
import '../theme/app_theme.dart';
import '../utils/toast_helper.dart';

/// Chat Conversation Page for buyer-seller communication
class ChatConversationPage extends StatefulWidget {
  final Conversation? conversation;
  final Product? product;
  final String? conversationId;
  final String? otherUserId;
  final String? otherUserName;

  const ChatConversationPage({
    super.key,
    this.conversation,
    this.product,
    this.conversationId,
    this.otherUserId,
    this.otherUserName,
  });

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSending = false;
  User? _currentUser;
  Conversation? _currentConversation;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _initializeConversation();

    // Mark conversation as read when opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentConversation != null) {
        _chatService.markAsRead(_currentConversation!.id);
      }
    });
  }

  void _initializeConversation() {
    // If we have a conversation object, use it
    if (widget.conversation != null) {
      _currentConversation = widget.conversation;
    } else if (widget.conversationId != null) {
      // Create a conversation object from the provided data
      _currentConversation = Conversation(
        id: widget.conversationId!,
        productId: widget.product?.id ?? '',
        productName: widget.product?.name ?? 'Product',
        buyerId: _currentUser?.uid ?? '',
        buyerName: _currentUser?.displayName ?? _currentUser?.email ?? 'Buyer',
        sellerId: widget.otherUserId ?? '',
        sellerName: widget.otherUserName ?? 'Seller',
        lastMessage: 'Starting conversation...',
        lastMessageTime: DateTime.now(),
        lastMessageSenderId: _currentUser?.uid ?? '',
        createdAt: DateTime.now(),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentConversation == null)
      return;

    final content = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      await _chatService.sendMessage(
        conversationId: _currentConversation!.id,
        content: content,
      );

      // Scroll to bottom after sending message
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      ToastHelper.showError(context, 'Failed to send message: $e');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentConversation == null) {
      return Scaffold(
        backgroundColor: AppTheme.getBackgroundColor(context),
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(
          child: Text('Unable to load conversation'),
        ),
      );
    }

    final otherUserName = _currentUser?.uid == _currentConversation!.buyerId
        ? _currentConversation!.sellerName
        : _currentConversation!.buyerName;

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getPrimaryAccent(context),
        foregroundColor: Colors.white,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              otherUserName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _currentConversation!.productName,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showProductDetails,
            icon: const Icon(Icons.info_outline),
            tooltip: 'Product Info',
          ),
        ],
      ),
      body: Column(
        children: [
          // Product Info Banner
          _buildProductBanner(),

          // Messages List
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessages(_currentConversation!.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}',
                        style:
                            TextStyle(color: AppTheme.getTextColor(context))),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: AppTheme.getSecondaryTextColor(context)
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet for ${_currentConversation!.productName}',
                          style: TextStyle(
                              color: AppTheme.getSecondaryTextColor(context)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUser?.uid;
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),

          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildProductBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.getPrimaryAccent(context).withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
              color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.shopping_cart, color: AppTheme.getPrimaryAccent(context)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Discussing: ${_currentConversation!.productName}',
              style: TextStyle(
                color: AppTheme.getPrimaryAccent(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: _showProductDetails,
            child: Text('View Product',
                style: TextStyle(color: AppTheme.getPrimaryAccent(context))),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? AppTheme.getPrimaryAccent(context)
              : AppTheme.getCardColor(context),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          border: !isMe
              ? Border.all(
                  color:
                      AppTheme.getBorderColor(context).withValues(alpha: 0.5))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : AppTheme.getTextColor(context),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: isMe
                    ? Colors.white70
                    : AppTheme.getSecondaryTextColor(context)
                        .withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Offer Button Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showMakeOfferDialog,
                    icon: const Icon(Icons.local_offer, size: 18),
                    label: const Text('Make Offer',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentOrange,
                      side: BorderSide(color: AppTheme.accentOrange),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Message Input Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.getBackgroundColor(context),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: AppTheme.getBorderColor(context)
                              .withValues(alpha: 0.5)),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: AppTheme.getTextColor(context)),
                      decoration: InputDecoration(
                        hintText:
                            'Type about ${_currentConversation!.productName}...',
                        hintStyle: TextStyle(
                            color: AppTheme.getSecondaryTextColor(context)
                                .withValues(alpha: 0.6)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.getPrimaryAccent(context),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetails() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.getCardColor(context),
          title: Text('Product Details',
              style: TextStyle(color: AppTheme.getTextColor(context))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentConversation!.productName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 12),
              if (widget.product != null) ...[
                _buildDetailItem('Price',
                    '₹${widget.product!.price}/${widget.product!.unit}'),
                _buildDetailItem('Category', widget.product!.category),
                _buildDetailItem('Location', widget.product!.location),
              ] else ...[
                Text('Product details not available',
                    style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context))),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (widget.product != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _messageController.text =
                      'I would like to make a bid offer for this product. ';
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.getPrimaryAccent(context),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Make Offer'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: ',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context))),
          Text(value,
              style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showMakeOfferDialog() {
    final bidAmountController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final messageController = TextEditingController();
    String selectedUnit = widget.product?.unit ?? 'kg';
    final units = ['kg', 'gram', 'ton', 'piece', 'dozen', 'liter', 'ml'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.getCardColor(context),
          title: Row(
            children: [
              Icon(Icons.local_offer, color: AppTheme.accentOrange),
              const SizedBox(width: 8),
              Expanded(
                  child: Text('Make an Offer',
                      style: TextStyle(color: AppTheme.getTextColor(context)))),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.getPrimaryAccent(context)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.shopping_bag,
                            color: AppTheme.getPrimaryAccent(context),
                            size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentConversation!.productName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.getPrimaryAccent(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bid amount
                  _buildDialogTextField(
                    controller: bidAmountController,
                    label: 'Bid Amount (₹)',
                    icon: Icons.currency_rupee,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() {}),
                  ),

                  const SizedBox(height: 12),

                  // Quantity and unit
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildDialogTextField(
                          controller: quantityController,
                          label: 'Quantity',
                          icon: Icons.inventory,
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedUnit,
                          dropdownColor: AppTheme.getCardColor(context),
                          style:
                              TextStyle(color: AppTheme.getTextColor(context)),
                          decoration: InputDecoration(
                            labelText: 'Unit',
                            labelStyle: TextStyle(
                                color: AppTheme.getSecondaryTextColor(context)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppTheme.getBorderColor(context))),
                          ),
                          items: units
                              .map((unit) => DropdownMenuItem(
                                    value: unit,
                                    child: Text(unit),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedUnit = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Optional message
                  _buildDialogTextField(
                    controller: messageController,
                    label: 'Message (Optional)',
                    icon: Icons.message,
                    maxLines: 3,
                    hintText: 'Add any special requirements...',
                  ),

                  const SizedBox(height: 16),

                  // Total calculation preview
                  if (bidAmountController.text.isNotEmpty &&
                      quantityController.text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Amount:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.getTextColor(context))),
                          Text(
                            '₹${((double.tryParse(bidAmountController.text) ?? 0) * (int.tryParse(quantityController.text) ?? 0)).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppTheme.accentOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final bidAmount = double.tryParse(bidAmountController.text);
                final quantity = int.tryParse(quantityController.text);

                if (bidAmount == null || bidAmount <= 0) {
                  ToastHelper.showError(
                      context, 'Please enter a valid bid amount');
                  return;
                }

                if (quantity == null || quantity <= 0) {
                  ToastHelper.showError(
                      context, 'Please enter a valid quantity');
                  return;
                }

                Navigator.pop(context);
                _sendBidOffer(
                    bidAmount, quantity, selectedUnit, messageController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.send),
              label: const Text('Send Offer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      style: TextStyle(color: AppTheme.getTextColor(context)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
        hintText: hintText,
        hintStyle: TextStyle(
            color:
                AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: AppTheme.getPrimaryAccent(context)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppTheme.getPrimaryAccent(context)),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _sendBidOffer(
    double bidAmount,
    int quantity,
    String unit,
    String message,
  ) async {
    try {
      final conversationService = ConversationService();
      await conversationService.sendBidOffer(
        conversationId: _currentConversation!.id,
        bidAmount: bidAmount,
        quantity: quantity,
        unit: unit,
        message: message.isNotEmpty ? message : null,
      );

      ToastHelper.showSuccess(context, 'Bid offer sent successfully!');
    } catch (e) {
      ToastHelper.showError(context, 'Failed to send offer: $e');
    }
  }
}
