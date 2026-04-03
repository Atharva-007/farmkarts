import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/conversation_model.dart';
import '../models/product_model.dart';
import '../services/chat_service.dart';
import '../services/conversation_service.dart';
import '../theme/app_theme.dart';
import '../utils/toast_helper.dart';

/// Enhanced Contact Seller Page with Glass Morphism Bid Card and Improved Chat
class EnhancedContactSellerPage extends StatefulWidget {
  final Conversation? conversation;
  final Product? product;
  final String? conversationId;
  final String? otherUserId;
  final String? otherUserName;

  const EnhancedContactSellerPage({
    super.key,
    this.conversation,
    this.product,
    this.conversationId,
    this.otherUserId,
    this.otherUserName,
  });

  @override
  State<EnhancedContactSellerPage> createState() => _EnhancedContactSellerPageState();
}

class _EnhancedContactSellerPageState extends State<EnhancedContactSellerPage>
    with TickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late AnimationController _animationController;
  late AnimationController _bidCardController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bidCardAnimation;
  
  bool _isSending = false;
  User? _currentUser;
  Conversation? _currentConversation;
  
  // Bid-related variables
  double _currentHighestBid = 0.0;
  double _myLatestBid = 0.0;
  int _totalBids = 0;
  bool _showBidCard = true;
  
  // Glass morphism bid card position
  bool _isCardExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _initializeConversation();
    _setupAnimations();
    _loadBidInformation();
    
    // Mark conversation as read when opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentConversation != null) {
        _chatService.markAsRead(_currentConversation!.id);
      }
    });
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
  }

  void _initializeConversation() {
    if (widget.conversation != null) {
      _currentConversation = widget.conversation;
    } else if (widget.conversationId != null) {
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

  Future<void> _loadBidInformation() async {
    // Simulate loading bid information - replace with actual Firebase queries
    setState(() {
      _currentHighestBid = widget.product?.price ?? 0.0;
      _myLatestBid = 0.0;
      _totalBids = 5; // Example
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bidCardController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendQuickInterest() {
    _messageController.text = 'I\'m interested in this product. Can we discuss the details?';
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '//';
    } else if (difference.inHours > 0) {
      return 'h ago';
    } else if (difference.inMinutes > 0) {
      return 'm ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        title: const Text('Contact Seller'),
      ),
      body: const Center(
        child: Text(
          'Enhanced Contact Seller Page\nWith Glass Morphism Bid Card',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
