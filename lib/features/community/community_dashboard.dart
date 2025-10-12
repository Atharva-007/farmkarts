import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/app_constants.dart';

class CommunityDashboard extends StatefulWidget {
  const CommunityDashboard({super.key});

  @override
  State<CommunityDashboard> createState() => _CommunityDashboardState();
}

class _CommunityDashboardState extends State<CommunityDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundLight,
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveHelper.getMaxWidth(context),
            ),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context),
                SliverPadding(
                  padding: ResponsiveHelper.getScreenPadding(context),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildCommunityStats(context),
                      SizedBox(height: AppConstants.getResponsiveSpacing(context)),
                      _buildQuickActions(context),
                      SizedBox(height: AppConstants.getResponsiveSpacing(context)),
                      _buildRecentDiscussions(context),
                      SizedBox(height: AppConstants.getResponsiveSpacing(context)),
                      _buildExpertAdvice(context),
                      SizedBox(height: AppConstants.getResponsiveSpacing(context)),
                      _buildSuccessStories(context),
                      SizedBox(height: AppConstants.getResponsiveSpacing(context)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: ResponsiveHelper.isDesktop(context) ? 140 : 120,
      floating: false,
      pinned: true,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.accentOrange, AppTheme.harvest],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: ResponsiveHelper.getScreenPadding(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        color: Colors.white,
                        size: ResponsiveHelper.isDesktop(context) ? 32 : 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Farmer Community',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!ResponsiveHelper.isMobile(context)) ...[
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: () {
                            // Create new post
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications, color: Colors.white),
                          onPressed: () {
                            // Notifications
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect, share experiences, and get expert advice',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityStats(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: AppConstants.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.getResponsiveSpacing(context)),
            LayoutBuilder(
              builder: (context, constraints) {
                if (ResponsiveHelper.isMobile(context)) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildStatCard(context, 'Members', '12,543', Icons.group, AppTheme.primaryGreen)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatCard(context, 'Active Today', '847', Icons.people_alt, AppTheme.accentOrange)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildStatCard(context, 'Discussions', '2,156', Icons.chat, AppTheme.skyBlue)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatCard(context, 'Experts', '156', Icons.verified, AppTheme.success)),
                        ],
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(child: _buildStatCard(context, 'Members', '12,543', Icons.group, AppTheme.primaryGreen)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(context, 'Active Today', '847', Icons.people_alt, AppTheme.accentOrange)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(context, 'Discussions', '2,156', Icons.chat, AppTheme.skyBlue)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(context, 'Experts', '156', Icons.verified, AppTheme.success)),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.isDesktop(context) ? 16 : 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: ResponsiveHelper.isDesktop(context) ? 28 : 24,
          ),
          SizedBox(height: ResponsiveHelper.isDesktop(context) ? 12 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(context, 18),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(context, 12),
              color: AppTheme.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'title': 'Ask Question', 'icon': Icons.help_outline, 'color': AppTheme.skyBlue},
      {'title': 'Share Experience', 'icon': Icons.share, 'color': AppTheme.primaryGreen},
      {'title': 'Find Experts', 'icon': Icons.search, 'color': AppTheme.accentOrange},
      {'title': 'Join Groups', 'icon': Icons.group_add, 'color': AppTheme.success},
    ];

    return Card(
      elevation: 2,
      child: Padding(
        padding: AppConstants.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.getResponsiveSpacing(context)),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(
                  context,
                  mobile: 2,
                  tablet: 4,
                  desktop: 4,
                ),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: ResponsiveHelper.getCardAspectRatio(context),
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return _buildActionCard(
                  context,
                  action['title'] as String,
                  action['icon'] as IconData,
                  action['color'] as Color,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title feature coming soon!')),
          );
        },
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: ResponsiveHelper.isDesktop(context) ? 28 : 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentDiscussions(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: AppConstants.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Discussions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            SizedBox(height: AppConstants.getResponsiveSpacing(context)),
            _buildDiscussionItem(
              context,
              'Best practices for organic farming?',
              'Rajesh Kumar',
              '23 replies',
              '2 hours ago',
              AppTheme.primaryGreen,
            ),
            const SizedBox(height: 12),
            _buildDiscussionItem(
              context,
              'Dealing with pest issues in monsoon',
              'Priya Sharma',
              '15 replies',
              '4 hours ago',
              AppTheme.warning,
            ),
            const SizedBox(height: 12),
            _buildDiscussionItem(
              context,
              'Crop insurance claim process help',
              'Mukesh Singh',
              '8 replies',
              '6 hours ago',
              AppTheme.info,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscussionItem(BuildContext context, String title, String author, String replies, String time, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: AppTheme.textGrey),
              const SizedBox(width: 4),
              Text(
                author,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textGrey,
                ),
              ),
              const Spacer(),
              Icon(Icons.chat_bubble_outline, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                replies,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpertAdvice(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: AppConstants.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified, color: AppTheme.success),
                const SizedBox(width: 8),
                Text(
                  'Expert Advice',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppConstants.getResponsiveSpacing(context)),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppTheme.success,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dr. Agricultural Expert',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Agriculture Specialist',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tip: Apply nitrogen fertilizer during the early morning or late evening for better absorption and to minimize nutrient loss.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessStories(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: AppConstants.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Success Stories',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            SizedBox(height: AppConstants.getResponsiveSpacing(context)),
            _buildSuccessStoryItem(
              context,
              '40% Increase in Yield with Organic Methods',
              'Farmer from Punjab shares how switching to organic farming increased crop yield and reduced costs.',
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
        ),
      ),
    );
  }

  Widget _buildSuccessStoryItem(BuildContext context, String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textGrey),
        ],
      ),
    );
  }
}
