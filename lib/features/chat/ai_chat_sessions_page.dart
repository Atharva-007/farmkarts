import 'package:flutter/material.dart';
import '../../models/ai_chat_model.dart';
import '../../services/ai_chat_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/universal_header.dart';
import '../../widgets/universal_drawer.dart';
import 'enhanced_ai_expert_chat_page.dart';
import '../../widgets/premium_fab.dart';

class AIChatSessionsPage extends StatefulWidget {
  const AIChatSessionsPage({super.key});

  @override
  State<AIChatSessionsPage> createState() => _AIChatSessionsPageState();
}

class _AIChatSessionsPageState extends State<AIChatSessionsPage> {
  final AIChatService _aiChatService = AIChatService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  bool _isSearching = false;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadStatistics() async {
    try {
      final stats = await _aiChatService.getSessionStatistics();
      if (mounted) setState(() => _stats = stats);
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      drawer: const UniversalDrawer(currentPage: 'ai-chat'),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          UniversalHeader(
            title: 'AI Expert',
            subtitle: 'Get instant farming advice',
            icon: Icons.psychology_rounded,
            showBackButton: false,
            showProfile: true,
            actions: [
              IconButton(
                icon: Icon(
                    _isSearching ? Icons.close_rounded : Icons.search_rounded,
                    color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchQuery = '';
                      _searchController.clear();
                    }
                  });
                },
              ),
            ],
          ),
          if (_isSearching)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildSearchField(),
              ),
            ),
          if (_stats != null && !_isSearching)
            SliverToBoxAdapter(
              child: _buildStatistics(),
            ),
          SliverPadding(
            padding: const EdgeInsets.only(top: 8),
            sliver: _buildSessionsList(),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: PremiumFAB(
        onPressed: _createNewChat,
        icon: Icons.add_rounded,
        bottomPadding: 90, // Positioned slightly higher
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.getBorderColor(context).withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: TextStyle(color: AppTheme.getTextColor(context)),
        decoration: InputDecoration(
          hintText: 'Search your chats...',
          hintStyle: TextStyle(
              color: AppTheme.getSecondaryTextColor(context)
                  .withValues(alpha: 0.5)),
          prefixIcon: Icon(Icons.search_rounded,
              color: AppTheme.getPrimaryAccent(context)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  Widget _buildStatistics() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          _buildStatCard(
            'Total Sessions',
            _stats!['totalSessions'].toString(),
            Icons.chat_bubble_outline_rounded,
            Colors.blue,
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            'Active Now',
            _stats!['activeSessions'].toString(),
            Icons.bolt_rounded,
            Colors.orange,
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            'Messages',
            _stats!['totalMessages'].toString(),
            Icons.message_outlined,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.getSecondaryTextColor(context),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList() {
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResults();
    }

    return StreamBuilder<List<AIChatSession>>(
      stream: _aiChatService.getUserChatSessions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
              child: _buildErrorState(snapshot.error.toString()));
        }

        List<AIChatSession> sessions = snapshot.data ?? [];

        if (sessions.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyState());
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final session = sessions[index];
                return _buildSessionCard(session);
              },
              childCount: sessions.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<AIChatSession>>(
      future: _aiChatService.searchChatSessions(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
              child: _buildErrorState('Search failed: ${snapshot.error}'));
        }

        final sessions = snapshot.data ?? [];

        if (sessions.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 64,
                      color: AppTheme.getSecondaryTextColor(context)
                          .withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No chats found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final session = sessions[index];
                return _buildSessionCard(session);
              },
              childCount: sessions.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionCard(AIChatSession session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = AIChatCategory.getCategoryColor(session.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.getBorderColor(context)
                .withValues(alpha: isDark ? 0.1 : 0.5)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: InkWell(
        onTap: () => _openChat(session),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      AIChatCategory.getCategoryIcon(session.category),
                      color: catColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getTextColor(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          session.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.getSecondaryTextColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildSessionActions(session),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                session.lastMessage,
                style: TextStyle(
                  color: AppTheme.getSecondaryTextColor(context)
                      .withValues(alpha: 0.8),
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.message_rounded,
                      size: 14,
                      color: AppTheme.getSecondaryTextColor(context)
                          .withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Text(
                    '${session.messageCount} messages',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.getSecondaryTextColor(context)
                          .withValues(alpha: 0.6),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatSessionTime(session.lastMessageTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.getSecondaryTextColor(context)
                          .withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionActions(AIChatSession session) {
    return PopupMenuButton<String>(
      onSelected: (action) => _handleSessionAction(action, session),
      icon: Icon(Icons.more_vert_rounded,
          color: AppTheme.getSecondaryTextColor(context)),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'rename',
          child: ListTile(
            leading: Icon(Icons.edit_rounded, size: 20),
            title: Text('Rename'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline_rounded,
                color: Colors.redAccent, size: 20),
            title: Text('Delete', style: TextStyle(color: Colors.redAccent)),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppTheme.getPrimaryAccent(context).withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.psychology_outlined,
              size: 80,
              color: AppTheme.getPrimaryAccent(context).withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No AI Chats Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start your first conversation with our AI farming expert.',
            style: TextStyle(
              color: AppTheme.getSecondaryTextColor(context),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: AppTheme.getErrorColor(context)),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: () => setState(() {}), child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  void _openChat(AIChatSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedAIExpertChatPage(session: session),
      ),
    );
  }

  void _createNewChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EnhancedAIExpertChatPage(),
      ),
    );
  }

  void _handleSessionAction(String action, AIChatSession session) {
    switch (action) {
      case 'rename':
        _showRenameDialog(session);
        break;
      case 'delete':
        _showDeleteDialog(session);
        break;
    }
  }

  void _showRenameDialog(AIChatSession session) {
    final controller = TextEditingController(text: session.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rename Chat'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: AppTheme.getTextColor(context)),
          decoration: const InputDecoration(
              labelText: 'Chat Title', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                await _aiChatService.updateSessionTitle(session.id, newTitle);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(AIChatSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Chat'),
        content: Text('Are you sure you want to delete "${session.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _aiChatService.deleteChatSession(session.id);
              if (mounted) Navigator.pop(context);
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  String _formatSessionTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }
}
