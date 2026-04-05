import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/conversation_model.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import '../widgets/universal_header.dart';
import '../widgets/universal_drawer.dart';
import 'chat_conversation_page.dart';

class ContactedSellersPage extends StatefulWidget {
  const ContactedSellersPage({super.key});

  @override
  State<ContactedSellersPage> createState() => _ContactedSellersPageState();
}

class _ContactedSellersPageState extends State<ContactedSellersPage>
    with TickerProviderStateMixin {
  final ChatService _chatService = ChatService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Conversation> _conversations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
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
            backgroundColor: AppTheme.getErrorColor(context),
          ),
        );
      }
    }
  }

  List<Conversation> get _filteredConversations {
    return _conversations.where((conv) {
      final matchesSearch = conv.productName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          conv.sellerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          conv.buyerName.toLowerCase().contains(_searchQuery.toLowerCase());

      if (_selectedFilter == 'unread') {
        return matchesSearch && conv.unreadCount > 0;
      }
      return matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      drawer: const UniversalDrawer(currentPage: 'messages'),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          UniversalHeader(
            title: 'Messages',
            subtitle: 'Manage your inquiries',
            icon: Icons.chat_bubble_rounded,
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
                padding: const EdgeInsets.all(16),
                child: _buildSearchField(),
              ),
            ),
          SliverToBoxAdapter(
            child: _buildFilters(),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filteredConversations.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final conversation = _filteredConversations[index];
                    return SlideTransition(
                      position: _slideAnimation,
                      child: _buildConversationCard(conversation),
                    );
                  },
                  childCount: _filteredConversations.length,
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
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
        boxShadow: AppTheme.getPremiumShadow(context),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: TextStyle(color: AppTheme.getTextColor(context)),
        decoration: InputDecoration(
          hintText: 'Search inquiries...',
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

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildFilterChip('all', 'All Messages'),
          _buildFilterChip('unread', 'Unread'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String id, String label) {
    final isSelected = _selectedFilter == id;
    final accentColor = AppTheme.getPrimaryAccent(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedFilter = id);
        },
        backgroundColor: AppTheme.getCardColor(context),
        selectedColor: accentColor.withValues(alpha: 0.15),
        checkmarkColor: accentColor,
        labelStyle: TextStyle(
          color: isSelected
              ? accentColor
              : AppTheme.getSecondaryTextColor(context),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isSelected
                ? accentColor
                : AppTheme.getBorderColor(context).withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
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
                    AppTheme.getPrimaryAccent(context).withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No inquiries found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your chat conversations will appear here.',
              style: TextStyle(
                color: AppTheme.getSecondaryTextColor(context),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationCard(Conversation conversation) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = AppTheme.getPrimaryAccent(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: conversation.unreadCount > 0
              ? accentColor.withValues(alpha: 0.3)
              : AppTheme.getBorderColor(context)
                  .withValues(alpha: isDark ? 0.1 : 0.5),
          width: conversation.unreadCount > 0 ? 1.5 : 1,
        ),
        boxShadow: AppTheme.getPremiumShadow(context),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ChatConversationPage(conversation: conversation),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  color: accentColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.productName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.getTextColor(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${conversation.unreadCount}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Seller: ${conversation.sellerName}',
                      style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      conversation.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context)
                            .withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppTheme.getSecondaryTextColor(context)
                      .withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
