import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';
import '../widgets/responsive_cards.dart';
import '../widgets/weather_widget.dart';
import '../features/marketplace/marketplace_home.dart';
import 'buy_page.dart';
import 'sell_page.dart';
import 'news_page.dart';
import 'settings_page.dart';

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
      backgroundColor: AppTheme.backgroundLight,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: CustomScrollView(
            slivers: [
              // Welcome Banner
              SliverToBoxAdapter(
                child: _buildWelcomeBanner(),
              ),
              
              // Quick Actions Grid
              SliverToBoxAdapter(
                child: _buildQuickActions(),
              ),
              
              // Statistics Cards
              SliverToBoxAdapter(
                child: _buildStatistics(),
              ),
              
              // Weather Widget
              SliverToBoxAdapter(
                child: _buildWeatherSection(),
              ),
              
              // Recent Activity
              SliverToBoxAdapter(
                child: _buildRecentActivity(),
              ),
              
              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('FarmKarts Dashboard'),
      backgroundColor: AppTheme.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => _showNotifications(),
        ),
        IconButton(
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: () => _showProfile(),
        ),
      ],
    );
  }

  Widget _buildWelcomeBanner() {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    
    return Container(
      margin: ResponsiveHelper.getScreenPadding(context),
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.defaultShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 16 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.agriculture,
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
                  'Welcome to FarmKarts!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isDesktop ? 24 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your farm business efficiently',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
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
        icon: Icons.storefront,
        title: 'Marketplace',
        subtitle: 'Buy & Sell Products',
        color: AppTheme.primaryGreen,
        onTap: () => _navigateToPage(const MarketplaceHome()),
      ),
      _QuickAction(
        icon: Icons.shopping_cart,
        title: 'Buy',
        subtitle: 'Purchase Products',
        color: AppTheme.skyBlue,
        onTap: () => _navigateToPage(const BuyPage()),
      ),
      _QuickAction(
        icon: Icons.sell,
        title: 'Sell',
        subtitle: 'List Your Products',
        color: AppTheme.accentOrange,
        onTap: () => _navigateToPage(const SellPage()),
      ),
      _QuickAction(
        icon: Icons.article,
        title: 'News',
        subtitle: 'Agricultural News',
        color: AppTheme.info,
        onTap: () => _navigateToPage(const NewsPage()),
      ),
      _QuickAction(
        icon: Icons.analytics,
        title: 'Analytics',
        subtitle: 'View Reports',
        color: AppTheme.harvest,
        onTap: () => _showComingSoon('Analytics'),
      ),
      _QuickAction(
        icon: Icons.inventory,
        title: 'Inventory',
        subtitle: 'Manage Stock',
        color: AppTheme.earthBrown,
        onTap: () => _showComingSoon('Inventory'),
      ),
      _QuickAction(
        icon: Icons.person_outline,
        title: 'Profile',
        subtitle: 'Account Settings',
        color: AppTheme.textGrey,
        onTap: () => _showProfile(),
      ),
      _QuickAction(
        icon: Icons.settings,
        title: 'Settings',
        subtitle: 'App Preferences',
        color: AppTheme.textGrey,
        onTap: () => _navigateToPage(const SettingsPage()),
      ),
    ];

    return Padding(
      padding: ResponsiveHelper.getScreenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isDesktop ? 20 : 18,
            ),
          ),
          SizedBox(height: isDesktop ? 16 : 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1.3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return _buildQuickActionCard(action);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(_QuickAction action) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 16 : 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 12 : 10),
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  action.icon,
                  color: action.color,
                  size: isDesktop ? 28 : 24,
                ),
              ),
              SizedBox(height: isDesktop ? 12 : 8),
              Text(
                action.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isDesktop ? 14 : 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                action.subtitle,
                style: TextStyle(
                  color: AppTheme.textGrey,
                  fontSize: isDesktop ? 12 : 11,
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

  Widget _buildStatistics() {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(
      context,
      mobile: 2,
      tablet: 2,
      desktop: 4,
    );

    return Padding(
      padding: ResponsiveHelper.getScreenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isDesktop ? 18 : 16,
            ),
          ),
          SizedBox(height: isDesktop ? 12 : 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - (crossAxisCount - 1) * 12) / crossAxisCount;
              final cardHeight = isMobile ? 80 : 90;
              
              return GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: cardWidth / cardHeight,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                children: [
                  ResponsiveGridCard(
                    title: 'Total Sales',
                    value: '₹12,450',
                    icon: Icons.trending_up,
                    color: AppTheme.success,
                    subtitle: '+15% this month',
                  ),
                  ResponsiveGridCard(
                    title: 'Products Listed',
                    value: '8',
                    icon: Icons.inventory_2,
                    color: AppTheme.primaryGreen,
                    subtitle: '3 sold this week',
                  ),
                  ResponsiveGridCard(
                    title: 'Total Orders',
                    value: '23',
                    icon: Icons.shopping_bag,
                    color: AppTheme.accentOrange,
                    subtitle: '5 pending',
                  ),
                  ResponsiveGridCard(
                    title: 'Rating',
                    value: '4.8',
                    icon: Icons.star,
                    color: AppTheme.sunshine,
                    subtitle: 'From 15 reviews',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherSection() {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    
    return Padding(
      padding: ResponsiveHelper.getScreenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weather Forecast',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isDesktop ? 20 : 18,
            ),
          ),
          SizedBox(height: isDesktop ? 16 : 12),
          const WeatherWidget(),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    
    return Padding(
      padding: ResponsiveHelper.getScreenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isDesktop ? 20 : 18,
                ),
              ),
              TextButton(
                onPressed: () => _showAllActivity(),
                child: const Text('View All'),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 16 : 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _buildActivityItem(index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(int index) {
    final activities = [
      {
        'icon': Icons.shopping_bag,
        'title': 'New order received',
        'subtitle': 'Order #1234 for tomatoes',
        'time': '2 hours ago',
        'color': AppTheme.success,
      },
      {
        'icon': Icons.person_add,
        'title': 'New customer inquiry',
        'subtitle': 'Someone is interested in your wheat',
        'time': '4 hours ago',
        'color': AppTheme.info,
      },
      {
        'icon': Icons.star,
        'title': 'New review received',
        'subtitle': 'Rated 5 stars for quality produce',
        'time': '1 day ago',
        'color': AppTheme.sunshine,
      },
      {
        'icon': Icons.inventory,
        'title': 'Product updated',
        'subtitle': 'Rice inventory updated',
        'time': '2 days ago',
        'color': AppTheme.textGrey,
      },
    ];

    final activity = activities[index];
    
    return Card(
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (activity['color'] as Color).withOpacity(0.1),
          child: Icon(
            activity['icon'] as IconData,
            color: activity['color'] as Color,
            size: 20,
          ),
        ),
        title: Text(
          activity['title'] as String,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(activity['subtitle'] as String),
        trailing: Text(
          activity['time'] as String,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    // Simulate refresh
    await Future.delayed(const Duration(seconds: 1));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dashboard refreshed!'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  void _navigateToPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: AppTheme.info,
      ),
    );
  }

  void _showNotifications() {
    _showComingSoon('Notifications');
  }

  void _showProfile() {
    _showComingSoon('Profile');
  }

  void _showAllActivity() {
    _showComingSoon('Activity History');
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