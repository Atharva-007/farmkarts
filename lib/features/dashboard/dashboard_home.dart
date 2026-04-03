import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/app_constants.dart';
import '../../widgets/quick_action_grid.dart';
import '../../widgets/weather_widget.dart';
import '../../widgets/live_market_rates_widget.dart';
import '../../widgets/news_carousel.dart';
import '../../widgets/universal_drawer.dart';
import '../../widgets/universal_header.dart';

class DashboardHome extends StatefulWidget {
  final Function(int)? onNavigate;
  
  const DashboardHome({super.key, this.onNavigate});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _bannerImages = [
    'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=800',
    'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=800',
    'https://images.unsplash.com/photo-1605000797499-95a51c5269ae?w=800',
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _animationController.forward();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Dashboard refreshed!'),
          backgroundColor: AppTheme.getSuccessColor(context),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'Farmer';
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      drawer: const UniversalDrawer(currentPage: 'dashboard'),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: AppTheme.getPrimaryAccent(context),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildAppBar(userName, isMobile),
              _buildMainContent(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(String userName, bool isMobile) {
    return UniversalHeader(
      title: _getGreeting(),
      subtitle: userName,
      icon: Icons.dashboard,
      expandedHeight: ResponsiveHelper.isDesktop(context) ? 180 : 150,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () => _showNotifications(),
          tooltip: 'Notifications',
        ),
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () => widget.onNavigate?.call(1),
          tooltip: 'Search',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildMainContent(bool isMobile) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          // Market Rates - Compact (Now at the top)
          _buildCompactMarketRates(),

          // Quick Actions Section - Compact
          Container(
            padding: ResponsiveHelper.getResponsivePadding(context),
            child: QuickActionGrid(onNavigate: widget.onNavigate),
          ),

          // Compact Dashboard Stats
          _buildCompactStats(),

          // Footer padding
          SizedBox(height: AppConstants.getResponsiveSpacing(context) * 2),
        ],
      ),
    );
  }

  Widget _buildCompactStats() {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactStatCard('12', 'Crops', Icons.agriculture, AppTheme.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCompactStatCard('8', 'Sales', Icons.storefront, AppTheme.accentOrange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCompactStatCard('₹45K', 'Revenue', Icons.account_balance_wallet, AppTheme.success),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatCard(String value, String label, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: AppTheme.getBorderColor(context)) : null,
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: isDark ? AppTheme.getPrimaryAccent(context) : color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMarketRates() {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: const LiveMarketRatesWidget(),
    );
  }

  Widget _buildDashboardCards() {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.dashboard_outlined,
                color: AppTheme.getPrimaryAccent(context),
                size: ResponsiveHelper.isDesktop(context) ? 28 : 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Farm Overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.getResponsiveSpacing(context)),
          ResponsiveHelper.isMobile(context)
              ? _buildMobileCards()
              : _buildDesktopCards(),
        ],
      ),
    );
  }

  Widget _buildMobileCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Total Crops', '12', Icons.agriculture, AppTheme.primaryGreen)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Active Sales', '8', Icons.storefront, AppTheme.accentOrange)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Revenue', '₹45,230', Icons.account_balance_wallet, AppTheme.success)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Weather Alert', '3', Icons.warning, AppTheme.warning)),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopCards() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Total Crops', '12', Icons.agriculture, AppTheme.primaryGreen)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Active Sales', '8', Icons.storefront, AppTheme.accentOrange)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Revenue', '₹45,230', Icons.account_balance_wallet, AppTheme.success)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Weather Alert', '3', Icons.warning, AppTheme.warning)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.isDesktop(context) ? 20 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: AppTheme.getBorderColor(context)) : null,
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDark ? AppTheme.getPrimaryAccent(context) : color,
                  size: ResponsiveHelper.isDesktop(context) ? 28 : 24,
                ),
              ),
              Icon(
                Icons.trending_up,
                color: AppTheme.success,
                size: ResponsiveHelper.isDesktop(context) ? 20 : 18,
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.isDesktop(context) ? 16 : 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
              fontSize: ResponsiveHelper.isDesktop(context) ? 24 : 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.getSecondaryTextColor(context),
              fontSize: ResponsiveHelper.isDesktop(context) ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionalBanner() {
    return Container(
      margin: ResponsiveHelper.getResponsivePadding(context),
      height: ResponsiveHelper.isDesktop(context) ? 200 : 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
        ),
      ),
      child: PageView.builder(
        itemCount: _bannerImages.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage(_bannerImages[index]),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  AppTheme.primaryGreen.withOpacity(0.3),
                  BlendMode.overlay,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Transform Your Farming',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join thousands of farmers using smart agriculture',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.getDividerColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                itemBuilder: (context, index) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.getIconBackgroundColor(context),
                    child: Icon(
                      Icons.notifications,
                      color: AppTheme.getPrimaryAccent(context),
                    ),
                  ),
                  title: Text(
                    'Notification ${index + 1}',
                    style: TextStyle(color: AppTheme.getTextColor(context)),
                  ),
                  subtitle: Text(
                    'This is a sample notification message',
                    style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                  ),
                  trailing: Text(
                    '${index + 1}h ago',
                    style: TextStyle(color: AppTheme.getSecondaryTextColor(context), fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}