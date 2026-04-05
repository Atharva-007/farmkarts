import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/universal_drawer.dart';
import '../../widgets/universal_header.dart';
import '../../services/user_state_service.dart';
import '../../models/user_model.dart';
import 'role_based_community_service.dart';
import '../../services/ai_chat_service.dart';
import '../../services/trending_video_service.dart';
import '../../models/trending_video_model.dart';
import 'crop_chat_page.dart';
import 'community_group_chat_page.dart';
import 'video_player_page.dart';
import 'video_library_page.dart';
import '../../widgets/premium_fab.dart';

class CommunityDashboard extends StatefulWidget {
  const CommunityDashboard({super.key});

  @override
  State<CommunityDashboard> createState() => _CommunityDashboardState();
}

class _CommunityDashboardState extends State<CommunityDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final RoleBasedCommunityService _communityService =
      RoleBasedCommunityService();
  final AIChatService _aiChatService = AIChatService();
  final TrendingVideoService _videoService = TrendingVideoService();

  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();

    _videoService.updateEngine();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserStateService>(
      builder: (context, userState, _) {
        final currentUser = userState.currentUser;
        final userRole = currentUser?.role ?? UserRole.customer;
        final userName = currentUser?.fullName ?? 'User';

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          drawer: const UniversalDrawer(currentPage: 'community'),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(seconds: 1));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Community feed updated!'),
                      backgroundColor: AppTheme.getPrimaryAccent(context),
                    ),
                  );
                }
              },
              color: AppTheme.getPrimaryAccent(context),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  UniversalHeader(
                    title: _communityService.getCommunityName(userRole),
                    subtitle: 'Welcome back, $userName',
                    icon: Icons.people,
                    showBackButton: false,
                    expandedHeight:
                        ResponsiveHelper.isDesktop(context) ? 180 : 150,
                    actions: [
                      IconButton(
                        icon: Icon(
                            _isSearching
                                ? Icons.close_rounded
                                : Icons.search_rounded,
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
                        tooltip: 'Search Posts',
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
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: ResponsiveHelper.getScreenPadding(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (userRole == UserRole.farmer) ...[
                            _buildCropChatCard(context),
                            const SizedBox(height: 24),
                            _buildSectionHeader(
                              context,
                              'Crop Discussion Groups',
                              Icons.groups,
                              AppTheme.primaryGreen,
                              onViewAll: () => _showComing_soon('All Groups'),
                            ),
                            const SizedBox(height: 12),
                            _buildCropGroups(context),
                            const SizedBox(height: 24),
                            _buildSectionHeader(
                              context,
                              'Trending',
                              Icons.play_circle_filled,
                              AppTheme.accentOrange,
                              onViewAll: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const VideoLibraryPage()),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildTrendingRefreshment(context),
                            const SizedBox(height: 24),
                          ],
                          if (userRole == UserRole.vendor ||
                              userRole == UserRole.wholesaler) ...[
                            _buildMarketInsights(context),
                            const SizedBox(height: 24),
                          ],
                          _buildSectionHeader(
                            context,
                            'Recent Discussions',
                            Icons.forum,
                            AppTheme.skyBlue,
                          ),
                          const SizedBox(height: 12),
                          _buildRecentDiscussions(context, userRole),
                          const SizedBox(height: 24),
                          _buildSectionHeader(
                            context,
                            'Success Stories',
                            Icons.stars,
                            AppTheme.sunshine,
                          ),
                          const SizedBox(height: 12),
                          _buildSuccessStories(context),
                          const SizedBox(height: 24),
                          _buildSectionHeader(
                            context,
                            'Expert Advice',
                            Icons.verified_user,
                            AppTheme.primaryGreen,
                          ),
                          const SizedBox(height: 12),
                          _buildExpertAdvice(context),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: PremiumFAB(
            onPressed: () => _showCreatePostDialog(context, currentUser),
            icon: Icons.add_comment_rounded,
            bottomPadding: 70, // Lowered
          ),
        );
      },
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
          hintText: 'Search posts or topics...',
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

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon, Color color,
      {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
            ),
          ],
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: Text(
              'View All',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _buildCropChatCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen,
            AppTheme.primaryGreen.withValues(alpha: 0.8)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CropChatPage()),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Crop Expert AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload a photo or ask about pests, diseases, and crop care.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'ASK NOW',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Hero(
                  tag: 'ai_crop_icon',
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCropGroups(BuildContext context) {
    final groups = [
      {
        'name': 'Wheat Growers',
        'id': 'wheat_growers',
        'icon': Icons.grass,
        'color': Colors.amber
      },
      {
        'name': 'Tomato Expert',
        'id': 'tomato_expert',
        'icon': Icons.eco,
        'color': Colors.red
      },
      {
        'name': 'Organic Farming',
        'id': 'organic_farming',
        'icon': Icons.nature_people,
        'color': Colors.green
      },
    ];

    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color:
                      AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommunityGroupChatPage(
                        groupId: group['id'] as String,
                        groupName: group['name'] as String,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              (group['color'] as Color).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(group['icon'] as IconData,
                            color: group['color'] as Color, size: 24),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        group['name'] as String,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Active Group',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.getSecondaryTextColor(context)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendingRefreshment(BuildContext context) {
    return StreamBuilder<List<TrendingVideo>>(
        stream: _videoService.getTrendingVideos(),
        builder: (context, snapshot) {
          final videos = snapshot.data ?? [];
          if (videos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoPlayerPage(video: video),
                      ),
                    );
                  },
                  child: Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(video.thumbnail),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8)
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.play_circle_fill,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  video.title,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_fire_department,
                                    color: AppTheme.accentOrange, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  video.category,
                                  style: TextStyle(
                                    color: video.category == 'Feed'
                                        ? AppTheme.accentOrange
                                        : AppTheme.getPrimaryAccent(context),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        });
  }

  Widget _buildRecentDiscussions(BuildContext context, UserRole role) {
    return StreamBuilder<QuerySnapshot>(
        stream: _communityService.getCommunityFeed(role),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          final isDark = Theme.of(context).brightness == Brightness.dark;

          var displayDocs = docs;
          if (_searchQuery.isNotEmpty) {
            displayDocs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final content = (data['content'] ?? '').toString().toLowerCase();
              final userName =
                  (data['userName'] ?? '').toString().toLowerCase();
              return content.contains(_searchQuery.toLowerCase()) ||
                  userName.contains(_searchQuery.toLowerCase());
            }).toList();
          }

          if (displayDocs.isEmpty) {
            return _buildEmptySection(_searchQuery.isEmpty
                ? 'No discussions yet. Be the first to start one!'
                : 'No matches found for "$_searchQuery"');
          }

          return Column(
            children: displayDocs.take(5).map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.getBorderColor(context)
                          .withValues(alpha: 0.5)),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.getPrimaryAccent(context)
                              .withValues(alpha: 0.1),
                          child: Icon(Icons.person,
                              size: 18,
                              color: AppTheme.getPrimaryAccent(context)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['userName'] ?? 'Anonymous',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.getTextColor(context),
                                ),
                              ),
                              Text(
                                'Posted recently',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.getSecondaryTextColor(
                                        context)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.getPrimaryAccent(context)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${data['commentsCount'] ?? 0} replies',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getPrimaryAccent(context)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data['content'] ?? 'No content',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppTheme.getTextColor(context)
                            .withValues(alpha: 0.9),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        });
  }

  Widget _buildExpertAdvice(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: _communityService.getExpertAdvice(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _buildAdviceItem(
              context,
              'Dr. Agricultural Expert',
              'Agriculture Specialist',
              'Tip: Apply nitrogen fertilizer during the early morning or late evening for better absorption.',
            );
          }

          return Column(
            children: docs.take(2).map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildAdviceItem(
                  context,
                  data['expertName'] ?? 'Expert',
                  data['specialization'] ?? 'Specialist',
                  data['tip'] ?? 'Loading expert tip...',
                ),
              );
            }).toList(),
          );
        });
  }

  Widget _buildAdviceItem(
      BuildContext context, String name, String specialization, String tip) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.success,
                radius: 20,
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    Text(
                      specialization,
                      style: TextStyle(
                          color: AppTheme.getSecondaryTextColor(context),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.format_quote, color: AppTheme.success, size: 30),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            tip,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              fontStyle: FontStyle.italic,
              color: AppTheme.getTextColor(context).withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStories(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: _communityService.getSuccessStories(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Column(
              children: [
                _buildSuccessStoryItem(
                  context,
                  '40% Increase in Yield with Organic Methods',
                  'Farmer from Punjab shares how switching to organic farming increased crop yield.',
                  Icons.trending_up,
                  AppTheme.success,
                ),
                const SizedBox(height: 12),
                _buildSuccessStoryItem(
                  context,
                  'Water Conservation Success Story',
                  'Drip irrigation system helped save 60% water while maintaining high crop quality.',
                  Icons.water_drop,
                  AppTheme.skyBlue,
                ),
              ],
            );
          }

          return Column(
            children: docs.take(3).map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildSuccessStoryItem(
                  context,
                  data['title'] ?? 'Success Story',
                  data['description'] ?? '',
                  Icons.star,
                  AppTheme.accentOrange,
                ),
              );
            }).toList(),
          );
        });
  }

  Widget _buildSuccessStoryItem(BuildContext context, String title,
      String description, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: color.withValues(alpha: 0.3)),
        ],
      ),
    );
  }

  Widget _buildMarketInsights(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.skyBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.skyBlue.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.skyBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics, color: AppTheme.skyBlue),
              ),
              const SizedBox(width: 12),
              Text(
                'Market Intelligence',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.textDark,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInsightItem(
            context,
            'Current demand for organic wheat is up 15% this week.',
            Icons.trending_up,
            AppTheme.success,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            context,
            'New transport regulations in Maharashtra effective from April.',
            Icons.info_outline,
            AppTheme.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(
      BuildContext context, String text, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context, UserModel? user) {
    if (user == null) {
      _showComing_soon('Please login to create a post');
      return;
    }

    final TextEditingController postController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedCategory = 'General';
    final List<String> categories = [
      'General',
      'Question',
      'Experience',
      'Market',
      'Tips'
    ];
    bool hasImage = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkBackground : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: isDark
                              ? AppTheme.darkBorder
                              : Colors.grey[200]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    Text(
                      'Create Post',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final content = postController.text.trim();
                        if (content.isNotEmpty) {
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2)),
                                  SizedBox(width: 16),
                                  Text('Verifying and sharing your post...'),
                                ],
                              ),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );

                          _handleAsyncPostCreation(
                              content, user, selectedCategory);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('Post',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          AppTheme.primaryGreen.withValues(alpha: 0.1),
                      child: Text(
                        user.fullName.isNotEmpty
                            ? user.fullName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.textDark,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            user.role.toString().split('.').last.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: postController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: TextStyle(
                      fontSize: 18,
                      color: isDark ? Colors.white : AppTheme.textDark,
                    ),
                    decoration: InputDecoration(
                      hintText: 'What do you want to ask or share?',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                    ),
                    onChanged: (text) => setModalState(() {}),
                  ),
                ),
              ),
              if (hasImage)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Stack(
                    children: [
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          image: const DecorationImage(
                            image: NetworkImage(
                                'https://images.unsplash.com/photo-1592982537447-6f2b6e1666e1?w=800'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setModalState(() => hasImage = false),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : Colors.grey[50],
                  border: Border(
                      top: BorderSide(
                          color: isDark
                              ? AppTheme.darkBorder
                              : Colors.grey[200]!)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Category:',
                        style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 12)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((cat) {
                          final isSelected = selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected)
                                  setModalState(() => selectedCategory = cat);
                              },
                              selectedColor:
                                  AppTheme.primaryGreen.withValues(alpha: 0.2),
                              checkmarkColor: AppTheme.primaryGreen,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppTheme.primaryGreen
                                    : (isDark ? Colors.white : Colors.black87),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setModalState(() => hasImage = true);
                          },
                          icon: const Icon(Icons.image_outlined,
                              color: AppTheme.primaryGreen),
                          tooltip: 'Add Photo',
                        ),
                        IconButton(
                          onPressed: () {
                            _showComing_soon('Camera');
                          },
                          icon: const Icon(Icons.camera_alt_outlined,
                              color: AppTheme.primaryGreen),
                          tooltip: 'Take Photo',
                        ),
                        IconButton(
                          onPressed: () {
                            _showComing_soon('Location tag');
                          },
                          icon: const Icon(Icons.location_on_outlined,
                              color: AppTheme.primaryGreen),
                          tooltip: 'Add Location',
                        ),
                        const Spacer(),
                        Text(
                          '${postController.text.length}/500',
                          style: TextStyle(
                            color: postController.text.length > 500
                                ? AppTheme.error
                                : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAsyncPostCreation(
      String content, UserModel user, String selectedCategory) async {
    try {
      final validation = await _aiChatService.validateCommunityPost(content);

      if (!validation['isValid']) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validation['reason']),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      await _communityService.createPost(
        userId: user.uid,
        userName: user.fullName,
        userRole: user.role,
        content: content,
        category: selectedCategory.toLowerCase(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post verified and shared with community!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share post: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildEmptySection(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          const Icon(Icons.forum_outlined, size: 40, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
                color: Colors.grey, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showComing_soon(String feature) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$feature feature coming soon!'),
          backgroundColor: AppTheme.getPrimaryAccent(context),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}
