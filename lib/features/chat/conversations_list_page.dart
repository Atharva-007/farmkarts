import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/conversation_model.dart';
import '../../models/product_model.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/universal_header.dart';
import 'chat_screen.dart';

/// Page showing all conversations for the current user with optimized performance
class ConversationsListPage extends StatefulWidget {
  const ConversationsListPage({super.key});

  @override
  State<ConversationsListPage> createState() => _ConversationsListPageState();
}

class _ConversationsListPageState extends State<ConversationsListPage>
    with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  String? _currentUserId;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: _currentUserId == null
          ? _buildLoginPrompt()
          : _buildConversationsListContent(),
    );
  }

  Widget _buildLoginPrompt() {
    return CustomScrollView(
      slivers: [
        const UniversalHeader(
          title: 'Messages',
          subtitle: 'Connect with farmers',
          icon: Icons.chat_rounded,
          showProfile: true,
        ),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.login_rounded,
                  size: 80,
                  color: AppTheme.getSecondaryTextColor(context)
                      .withValues(alpha: 0.2),
                ),
                const SizedBox(height: 24),
                Text(
                  'Login to view your messages',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConversationsListContent() {
    return StreamBuilder<List<Conversation>>(
      stream: _chatService.getConversations(),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;
        final conversations = snapshot.data ?? [];

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            UniversalHeader(
              title: 'Messages',
              subtitle: '${conversations.length} active chats',
              icon: Icons.forum_rounded,
              showProfile: true,
              actions: [
                StreamBuilder<int>(
                  stream: _chatService.getUnreadCount(),
                  builder: (context, unreadSnap) {
                    final unreadCount = unreadSnap.data ?? 0;
                    if (unreadCount == 0) return const SizedBox.shrink();
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12)),
                        child: Text('$unreadCount',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isLoading
                    ? Padding(
                        padding: const EdgeInsets.only(top: 100),
                        child: Center(
                            key: const ValueKey('loading'),
                            child: CircularProgressIndicator(
                                color: AppTheme.getPrimaryAccent(context))),
                      )
                    : conversations.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            key: const ValueKey('list'),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            itemCount: conversations.length,
                            itemBuilder: (context, index) {
                              return _buildConversationTile(
                                  conversations[index], index);
                            },
                          ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color:
                    AppTheme.getPrimaryAccent(context).withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 80,
                color:
                    AppTheme.getPrimaryAccent(context).withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Contact sellers to start a conversation',
              style: TextStyle(
                color: AppTheme.getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation, int index) {
    final isUserSeller = conversation.sellerId == _currentUserId;
    final otherUserName =
        isUserSeller ? conversation.buyerName : conversation.sellerName;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasUnread = conversation.unreadCount > 0;

    return FadeTransition(
      opacity: _animationController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.05, 1.0, curve: Curves.easeOut),
        )),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
            border: Border.all(
              color: hasUnread
                  ? AppTheme.getPrimaryAccent(context).withValues(alpha: 0.3)
                  : AppTheme.getBorderColor(context).withValues(alpha: 0.5),
              width: hasUnread ? 1.5 : 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            leading: Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.getPrimaryAccent(context)
                            .withValues(alpha: 0.2),
                        AppTheme.getPrimaryAccent(context)
                            .withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      otherUserName.isNotEmpty
                          ? otherUserName[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        color: AppTheme.getPrimaryAccent(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppTheme.getCardColor(context), width: 2.5),
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    otherUserName,
                    style: TextStyle(
                      fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                      fontSize: 16,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                ),
                Text(
                  _formatTime(conversation.lastMessageTime),
                  style: TextStyle(
                    fontSize: 11,
                    color: hasUnread
                        ? AppTheme.getPrimaryAccent(context)
                        : AppTheme.getSecondaryTextColor(context)
                            .withValues(alpha: 0.6),
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined,
                        size: 14,
                        color: AppTheme.getPrimaryAccent(context)
                            .withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        conversation.productName,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.getPrimaryAccent(context)
                              .withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  conversation.lastMessage,
                  style: TextStyle(
                    color: hasUnread
                        ? AppTheme.getTextColor(context).withValues(alpha: 0.9)
                        : AppTheme.getSecondaryTextColor(context),
                    fontSize: 14,
                    fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            onTap: () => _openConversation(
                conversation,
                isUserSeller ? conversation.buyerId : conversation.sellerId,
                otherUserName),
            onLongPress: () => _showConversationOptions(conversation),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${time.day}/${time.month}';
  }

  void _openConversation(
      Conversation conversation, String otherUserId, String otherUserName) {
    _chatService.markAsRead(conversation.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          conversationId: conversation.id,
          otherUserId: otherUserId,
          otherUserName: otherUserName,
          product: Product(
            id: conversation.productId,
            name: conversation.productName,
            description: '',
            category: '',
            price: 0,
            unit: '',
            imageUrls: conversation.productImageUrl.isNotEmpty
                ? [conversation.productImageUrl]
                : [],
            sellerId: conversation.sellerId,
            sellerName: conversation.sellerName,
            location: '',
            timestamp: DateTime.now(),
          ),
        ),
      ),
    );
  }

  void _showConversationOptions(Conversation conversation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.getDividerColor(context),
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.mark_chat_read_rounded,
                    color: AppTheme.getPrimaryAccent(context)),
                title: const Text('Mark as read'),
                onTap: () {
                  Navigator.pop(context);
                  _chatService.markAsRead(conversation.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent),
                title: const Text('Delete conversation',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(conversation);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Conversation conversation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Conversation'),
        content: Text(
            'Are you sure you want to delete the chat for ${conversation.productName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _chatService.deleteConversation(conversation.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: const Text('Conversation deleted'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppTheme.getPrimaryAccent(context)),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
