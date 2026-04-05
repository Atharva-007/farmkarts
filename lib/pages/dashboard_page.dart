import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';
import '../widgets/responsive_cards.dart';
import '../widgets/weather_widget.dart';
import '../widgets/universal_header.dart';
import 'complete_marketplace_page.dart';
import 'news_page.dart';
import 'selling_history_page.dart';
import 'inventory_page.dart';
import '../features/profile/profile_dashboard.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
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
      curve: Curves.easeInOut,
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
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          color: AppTheme.getPrimaryAccent(context),
          onRefresh: _handleRefresh,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const UniversalHeader(
                title: 'FarmKarts Dashboard',
                subtitle: 'Manage your farm business',
                icon: Icons.agriculture_rounded,
                showProfile: true,
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildWelcomeBanner(),
                    _buildQuickActions(),
                    _buildStatistics(),
                    _buildWeatherSection(),
                    _buildRecentActivity(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 16 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: isDesktop ? 40 : 32,
            ),
          ),
          SizedBox(width: isDesktop ? 20 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Connect',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isDesktop ? 24 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Access your marketplace instantly',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: isDesktop ? 16 : 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(
      context,
      mobile: 2,
      tablet: 3,
      desktop: 4,
    );

    final actions = [
      _QuickAction(
        icon: Icons.storefront_rounded,
        title: 'Marketplace',
        subtitle: 'Buy & Sell',
        color: AppTheme.primaryGreen,
        onTap: () => _navigateToPage(const CompleteMarketplacePage()),
      ),
      _QuickAction(
        icon: Icons.analytics_rounded,
        title: 'Analytics',
        subtitle: 'Sales Reports',
        color: Colors.purple,
        onTap: () => _navigateToPage(const SellingHistoryPage()),
      ),
      _QuickAction(
        icon: Icons.inventory_2_rounded,
        title: 'Inventory',
        subtitle: 'Manage Stock',
        color: Colors.brown,
        onTap: () => _navigateToPage(const InventoryPage()),
      ),
      _QuickAction(
        icon: Icons.newspaper_rounded,
        title: 'News',
        subtitle: 'Daily Updates',
        color: Colors.cyan,
        onTap: () => _navigateToPage(const NewsPage()),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isDesktop ? 20 : 18,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppTheme.getSecondaryTextColor(context)),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1.4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              return _buildQuickActionCard(actions[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(_QuickAction action) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                action.icon,
                color: action.color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              action.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppTheme.getTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(
      context,
      mobile: 2,
      tablet: 2,
      desktop: 4,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isDesktop ? 20 : 18,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 12),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 2.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            children: [
              ResponsiveGridCard(
                title: 'Total Sales',
                value: '₹12,450',
                icon: Icons.trending_up,
                color: Colors.green,
                subtitle: '+15%',
              ),
              ResponsiveGridCard(
                title: 'Products',
                value: '8',
                icon: Icons.inventory_2,
                color: Colors.blue,
                subtitle: 'Active',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherSection() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: WeatherWidget(),
    );
  }

  Widget _buildRecentActivity() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.getCardColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppTheme.getBorderColor(context)
                      .withValues(alpha: isDark ? 0.1 : 0.5)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color:
                      AppTheme.getDividerColor(context).withValues(alpha: 0.5)),
              itemBuilder: (context, index) {
                return _buildActivityItem(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(int index) {
    final activities = [
      {
        'icon': Icons.shopping_bag_rounded,
        'title': 'New order received',
        'time': '2h ago',
        'color': Colors.green,
      },
      {
        'icon': Icons.person_rounded,
        'title': 'Customer inquiry',
        'time': '4h ago',
        'color': Colors.blue,
      },
      {
        'icon': Icons.star_rounded,
        'title': 'New review',
        'time': '1d ago',
        'color': Colors.amber,
      },
    ];

    final activity = activities[index];

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (activity['color'] as Color).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(activity['icon'] as IconData,
            color: activity['color'] as Color, size: 18),
      ),
      title: Text(activity['title'] as String,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: Text(activity['time'] as String,
          style: TextStyle(
              color: AppTheme.getSecondaryTextColor(context), fontSize: 12)),
    );
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  void _navigateToPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  void _showProfile() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const ProfileDashboard()));
  }
}

class _QuickAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}
