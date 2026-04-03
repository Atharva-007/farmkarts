import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/chat_model.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';
import 'chat_screen.dart';

/// Page showing all conversations for the current user
class ConversationsListPage extends StatefulWidget {
  const ConversationsListPage({super.key});

  @override
  State<ConversationsListPage> createState() => _ConversationsListPageState();
}

class _ConversationsListPageState extends State<ConversationsListPage> {
  final ChatService _chatService = ChatService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: _buildAppBar(),
      body: _currentUserId == null
          ? _buildLoginPrompt()
          : _buildConversationsList(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Messages',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.getAppBarTextColor(context),
        ),
      ),
      backgroundColor: AppTheme.getPrimaryAccent(context),
      foregroundColor: AppTheme.getAppBarTextColor(context),
      elevation: 1,
      actions: [
        StreamBuilder<int>(
          stream: _chatService.getUnreadCount(),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;
            if (unreadCount == 0) return const SizedBox.shrink();
            
            return Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.login,
            size: 64,
            color: AppTheme.getSecondaryTextColor(context).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Please login to view messages',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    return StreamBuilder<List<ChatConversation>>(
      stream: _chatService.getConversations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.getPrimaryAccent(context)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final conversations = snapshot.data!;
        
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          color: AppTheme.getPrimaryAccent(context),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: AppTheme.getDividerColor(context)),
            itemBuilder: (context, index) {
              return _buildConversationTile(conversations[index]);
            },
          ),
        );
      },
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
            color: AppTheme.getSecondaryTextColor(context).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.getSecondaryTextColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start chatting by contacting a seller',
            style: TextStyle(
              color: AppTheme.getSecondaryTextColor(context).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(ChatConversation conversation) {
    final isUserSeller = conversation.sellerId == _currentUserId;
    final otherUserName = isUserSeller ? conversation.buyerName : conversation.sellerName;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      tileColor: conversation.unreadCount > 0 
          ? AppTheme.getPrimaryAccent(context).withOpacity(isDark ? 0.1 : 0.05) 
          : null,
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.getPrimaryAccent(context).withOpacity(0.1),
            child: Text(
              otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : 'U',
              style: TextStyle(
                color: AppTheme.getPrimaryAccent(context),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          if (conversation.unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.getBackgroundColor(context), width: 2),
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  conversation.unreadCount > 9 ? '9+' : conversation.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
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
                fontWeight: conversation.unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                fontSize: 16,
                color: AppTheme.getTextColor(context),
              ),
            ),
          ),
          if (isUserSeller)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.getPrimaryAccent(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Seller',
                style: TextStyle(
                  color: AppTheme.getPrimaryAccent(context),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              if (conversation.productImageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: conversation.productImageUrl,
                    width: 20,
                    height: 20,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      width: 20,
                      height: 20,
                      color: AppTheme.getBorderColor(context).withOpacity(0.2),
                      child: Icon(Icons.image, size: 12, color: AppTheme.getSecondaryTextColor(context).withOpacity(0.5)),
                    ),
                  ),
                )
              else
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.getPrimaryAccent(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.agriculture,
                    size: 12,
                    color: AppTheme.getPrimaryAccent(context),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  conversation.productName,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.getSecondaryTextColor(context),
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
              color: conversation.unreadCount > 0 
                  ? AppTheme.getTextColor(context) 
                  : AppTheme.getSecondaryTextColor(context),
              fontWeight: conversation.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(conversation.lastMessageTime),
            style: TextStyle(
              fontSize: 12,
              color: conversation.unreadCount > 0 
                  ? AppTheme.getPrimaryAccent(context) 
                  : AppTheme.getSecondaryTextColor(context).withOpacity(0.7),
              fontWeight: conversation.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          if (conversation.status != ChatStatus.active)
            Icon(
              conversation.status == ChatStatus.blocked ? Icons.block : Icons.archive,
              size: 16,
              color: AppTheme.getSecondaryTextColor(context).withOpacity(0.5),
            ),
        ],
      ),
      onTap: () => _openConversation(conversation, isUserSeller ? conversation.buyerId : conversation.sellerId, otherUserName),
      onLongPress: () => _showConversationOptions(conversation),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${time.day}/${time.month}';
    }
  }

  void _openConversation(ChatConversation conversation, String otherUserId, String otherUserName) {
    // Mark as read when opening
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
            imageUrls: conversation.productImageUrl.isNotEmpty ? [conversation.productImageUrl] : [],
            sellerId: conversation.sellerId,
            sellerName: conversation.sellerName,
            location: '',
            timestamp: DateTime.now(),
          ),
        ),
      ),
    );
  }

  void _showConversationOptions(ChatConversation conversation) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mark_as_unread),
              title: const Text('Mark as Unread'),
              onTap: () {
                Navigator.pop(context);
                // Implementation for mark as unread
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archive'),
              onTap: () {
                Navigator.pop(context);
                _archiveConversation(conversation.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(conversation);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _archiveConversation(String conversationId) {
    _chatService.deleteConversation(conversationId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conversation archived'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _showDeleteConfirmation(ChatConversation conversation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text('Are you sure you want to delete this conversation with ${conversation.buyerName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _chatService.deleteConversation(conversation.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Conversation deleted'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}