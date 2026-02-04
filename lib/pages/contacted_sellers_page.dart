import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/conversation_model.dart';
import '../models/product_model.dart';
import '../services/enhanced_marketplace_service.dart';
import '../services/chat_service.dart';
import '../services/conversation_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';
import 'chat_conversation_page.dart';

class ContactedSellersPage extends StatefulWidget {
  const ContactedSellersPage({super.key});

  @override
  State<ContactedSellersPage> createState() => _ContactedSellersPageState();
}

class _ContactedSellersPageState extends State<ContactedSellersPage>
    with TickerProviderStateMixin {
  final EnhancedMarketplaceService _marketplaceService = EnhancedMarketplaceService();
  final ChatService _chatService = ChatService();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadConversations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get all conversations where user is participant (both buyer and seller)
        _chatService.getUserConversations().listen((conversations) {
          if (mounted) {
            setState(() {
              _conversations = conversations;
              _isLoading = false;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load conversations: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  List<Conversation> get _filteredConversations {
    var filtered = _conversations;
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((conversation) {
        return conversation.sellerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               conversation.productName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Apply status filter
    switch (_selectedFilter) {
      case 'recent':
        filtered = filtered.where((conversation) {
          final now = DateTime.now();
          final diff = now.difference(conversation.lastMessageTime);
          return diff.inDays <= 7;
        }).toList();
        break;
      case 'unread':
        filtered = filtered.where((conversation) => conversation.unreadCount > 0).toList();
        break;
      case 'active':
        filtered = filtered.where((conversation) => conversation.isActive).toList();
        break;
    }
    
    // Sort by most recent message
    filtered.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Contacted Sellers'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
            tooltip: 'Search Conversations',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Filter Tabs
              _buildFilterTabs(),
              
              // Search Bar (if searching)
              if (_searchQuery.isNotEmpty) _buildSearchBar(),
              
              // Conversations List
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _filteredConversations.isEmpty
                        ? _buildEmptyState()
                        : _buildConversationsList(isMobile),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToMarketplace(),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.shopping_cart),
        label: const Text('Browse Products'),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      {'key': 'all', 'label': 'All Chats', 'icon': Icons.chat_bubble_outline},
      {'key': 'unread', 'label': 'Unread', 'icon': Icons.mark_chat_unread},
      {'key': 'recent', 'label': 'Recent', 'icon': Icons.access_time},
      {'key': 'active', 'label': 'Active', 'icon': Icons.circle},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter['key'];
            final count = _getFilterCount(filter['key'] as String);
            
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        filter['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : AppTheme.primaryGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(filter['label'] as String),
                      if (count > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            count.toString(),
                            style: TextStyle(
                              color: isSelected ? AppTheme.primaryGreen : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter['key'] as String;
                    });
                  },
                  selectedColor: AppTheme.primaryGreen,
                  backgroundColor: Colors.grey[100],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search sellers or products...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primaryGreen),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryGreen),
          const SizedBox(height: 16),
          Text(
            'Loading conversations...',
            style: TextStyle(
              color: AppTheme.textGrey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No conversations found'
                : 'No contacted sellers yet',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try different search terms'
                : 'Start contacting sellers to see your conversations here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToMarketplace(),
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Browse Products'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConversationsList(bool isMobile) {
    return RefreshIndicator(
      onRefresh: _loadConversations,
      color: AppTheme.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredConversations.length,
        itemBuilder: (context, index) {
          final conversation = _filteredConversations[index];
          return AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: Curves.easeOutBack,
            child: _buildConversationCard(conversation, isMobile),
          );
        },
      ),
    );
  }

  Widget _buildConversationCard(Conversation conversation, bool isMobile) {
    final user = FirebaseAuth.instance.currentUser;
    final isUnread = conversation.unreadCount > 0;
    final isFromOtherUser = conversation.lastMessageSenderId != user?.uid;
    
    // Determine who we're chatting with
    final chatPartnerName = user?.uid == conversation.buyerId 
        ? conversation.sellerName 
        : conversation.buyerName;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isUnread && isFromOtherUser 
            ? BorderSide(color: AppTheme.primaryGreen, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openConversation(conversation),
        onLongPress: () => _showConversationOptions(conversation),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Enhanced Avatar with online status
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                        child: Text(
                          chatPartnerName.isNotEmpty 
                              ? chatPartnerName[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Online/Active indicator
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: conversation.isActive ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                  // Unread count badge
                  if (isUnread && isFromOtherUser)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          conversation.unreadCount > 99 
                              ? '99+' 
                              : conversation.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(width: 16),
              
              // Conversation Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chatPartnerName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        Text(
                          _formatTime(conversation.lastMessageTime),
                          style: TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: 13,
                            fontWeight: isUnread && isFromOtherUser 
                                ? FontWeight.w600 
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Product name with icon
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 14,
                          color: AppTheme.primaryGreen,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            conversation.productName,
                            style: TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Last message with read status
                    Row(
                      children: [
                        if (conversation.lastMessageSenderId == user?.uid) ...[
                          Icon(
                            isUnread ? Icons.done : Icons.done_all,
                            size: 16,
                            color: isUnread ? AppTheme.textGrey : AppTheme.primaryGreen,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            _getLastMessagePreview(conversation.lastMessage),
                            style: TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 15,
                              fontWeight: isUnread && isFromOtherUser 
                                  ? FontWeight.w600 
                                  : FontWeight.normal,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Chat Button and Offer Info
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Enhanced Chat Button with Offer Indication
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ElevatedButton.icon(
                      onPressed: () => _openConversation(conversation),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.chat_bubble, size: 16),
                      label: const Text('Open Chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  
                  // Offer info chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accentOrange.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_offer, size: 12, color: AppTheme.accentOrange),
                        const SizedBox(width: 4),
                        Text(
                          'Make offers in chat',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.accentOrange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // More options
                  IconButton(
                    onPressed: () => _showConversationOptions(conversation),
                    icon: Icon(
                      Icons.more_vert,
                      color: AppTheme.textGrey,
                      size: 20,
                    ),
                    tooltip: 'More Options',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getFilterCount(String filter) {
    switch (filter) {
      case 'unread':
        return _conversations.where((c) => c.unreadCount > 0).length;
      case 'recent':
        final now = DateTime.now();
        return _conversations.where((c) {
          final diff = now.difference(c.lastMessageTime);
          return diff.inDays <= 7;
        }).length;
      case 'active':
        return _conversations.where((c) => c.isActive).length;
      default:
        return 0;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) return 'Yesterday';
      if (difference.inDays <= 7) return '${difference.inDays}d ago';
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Conversations'),
        content: TextField(
          autofocus: true,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
            Navigator.pop(context);
          },
          decoration: const InputDecoration(
            hintText: 'Search sellers or products...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _openConversation(Conversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatConversationPage(
          conversation: conversation,
        ),
      ),
    );
  }

  void _showConversationOptions(Conversation conversation) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              conversation.sellerName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              conversation.productName,
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 20),
            
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Open Chat'),
              onTap: () {
                Navigator.pop(context);
                _openConversation(conversation);
              },
            ),

            ListTile(
              leading: Icon(Icons.local_offer, color: AppTheme.accentOrange),
              title: Text('Make Offer', style: TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _showMakeOfferDialog(conversation);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.mark_chat_read),
              title: const Text('Mark as Read'),
              onTap: () {
                Navigator.pop(context);
                _chatService.markAsRead(conversation.id);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Product'),
              onTap: () {
                Navigator.pop(context);
                _shareProduct(conversation);
              },
            ),
            
            ListTile(
              leading: Icon(Icons.block, color: AppTheme.error),
              title: Text('Block Seller', style: TextStyle(color: AppTheme.error)),
              onTap: () {
                Navigator.pop(context);
                _showBlockConfirmation(conversation);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareProduct(Conversation conversation) {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  void _showBlockConfirmation(Conversation conversation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block Seller'),
        content: Text('Are you sure you want to block ${conversation.sellerName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement block functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Block functionality coming soon')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  String _getLastMessagePreview(String lastMessage) {
    // Handle different message types
    if (lastMessage.startsWith('🏷️ **BID OFFER**')) {
      return '💰 Bid Offer';
    } else if (lastMessage.startsWith('📷')) {
      return '📷 Photo';
    } else if (lastMessage.startsWith('📎')) {
      return '📎 File';
    } else if (lastMessage.startsWith('📦')) {
      return '📦 Order Update';
    } else {
      return lastMessage;
    }
  }

  void _showMakeOfferDialog(Conversation conversation) {
    final bidAmountController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final messageController = TextEditingController();
    String selectedUnit = 'kg';
    final units = ['kg', 'gram', 'ton', 'piece', 'dozen', 'liter', 'ml'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.local_offer, color: AppTheme.accentOrange),
              const SizedBox(width: 8),
              const Expanded(child: Text('Make an Offer')),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shopping_bag, color: AppTheme.primaryGreen, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          conversation.productName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Bid amount
                TextField(
                  controller: bidAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Bid Amount (₹)',
                    prefixIcon: Icon(Icons.currency_rupee, color: AppTheme.primaryGreen),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primaryGreen),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Quantity and unit
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          prefixIcon: Icon(Icons.inventory, color: AppTheme.primaryGreen),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.primaryGreen),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedUnit,
                        decoration: InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.primaryGreen),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: units.map((unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit),
                        )).toList(),
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
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Message (Optional)',
                    prefixIcon: Icon(Icons.message, color: AppTheme.primaryGreen),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primaryGreen),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Add any special requirements or notes...',
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Total calculation preview
                if (bidAmountController.text.isNotEmpty && quantityController.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '₹${(double.tryParse(bidAmountController.text) ?? 0) * (int.tryParse(quantityController.text) ?? 0)}',
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid bid amount')),
                  );
                  return;
                }
                
                if (quantity == null || quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid quantity')),
                  );
                  return;
                }
                
                Navigator.pop(context);
                _sendBidOffer(conversation, bidAmount, quantity, selectedUnit, messageController.text);
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

  void _navigateToMarketplace() {
    // Navigate to main app layout with marketplace tab selected
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (route) => false,
      arguments: {'initialIndex': 1}, // Marketplace is at index 1
    );
  }

  Future<void> _sendBidOffer(
    Conversation conversation,
    double bidAmount,
    int quantity,
    String unit,
    String message,
  ) async {
    try {
      final conversationService = ConversationService();
      await conversationService.sendBidOffer(
        conversationId: conversation.id,
        bidAmount: bidAmount,
        quantity: quantity,
        unit: unit,
        message: message.isNotEmpty ? message : null,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bid offer sent successfully!'),
          backgroundColor: AppTheme.primaryGreen,
          action: SnackBarAction(
            label: 'View Chat',
            textColor: Colors.white,
            onPressed: () => _openConversation(conversation),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send offer: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
}