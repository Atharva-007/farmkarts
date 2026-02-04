import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/app_constants.dart';
import '../../widgets/quick_action_grid.dart';
import '../../widgets/market_price_ticker.dart';
import '../../widgets/weather_widget.dart';
import '../../widgets/news_carousel.dart';

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
        const SnackBar(
          content: Text('Dashboard refreshed!'),
          backgroundColor: AppTheme.primaryGreen,
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
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) => FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: AppTheme.primaryGreen,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(userName, isMobile),
                _buildLiveMarketRates(),
                _buildMainContent(isMobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(String userName, bool isMobile) {
    return SliverAppBar(
      expandedHeight: ResponsiveHelper.isDesktop(context) ? 180 : 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.primaryGreen,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGreen,
                AppTheme.lightGreen,
                AppTheme.darkGreen,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: ResponsiveHelper.getScreenPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          Icons.wb_sunny,
                          color: Colors.white,
                          size: ResponsiveHelper.isDesktop(context) ? 32 : 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: ResponsiveHelper.isDesktop(context) ? 28 : 24,
                              ),
                            ),
                            Text(
                              userName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (!ResponsiveHelper.isMobile(context)) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Welcome back to your smart farming dashboard',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () => _showNotifications(),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          onPressed: () => widget.onNavigate?.call(6),
        ),
      ],
    );
  }

  Widget _buildLiveMarketRates() {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: ResponsiveHelper.getResponsivePadding(context),
          padding: AppConstants.getResponsivePadding(context),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
                  Icon(
                    Icons.trending_up,
                    color: AppTheme.primaryGreen,
                    size: ResponsiveHelper.isDesktop(context) ? 28 : 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Live Market Rates',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: AppTheme.success,
                            fontSize: ResponsiveHelper.isDesktop(context) ? 12 : 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppConstants.getResponsiveSpacing(context)),
              const MarketPriceTicker(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isMobile) {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            // Quick Actions Section
            Container(
              padding: ResponsiveHelper.getResponsivePadding(context),
              child: QuickActionGrid(onNavigate: widget.onNavigate),
            ),

            // Dashboard Cards Section
            _buildDashboardCards(),

            // News Section
            Container(
              padding: ResponsiveHelper.getResponsivePadding(context),
              child: const NewsCarousel(),
            ),

            // Banner Section
            _buildPromotionalBanner(),

            // Footer padding
            SizedBox(height: AppConstants.getResponsiveSpacing(context) * 2),
          ],
        ),
      ),
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
                color: AppTheme.primaryGreen,
                size: ResponsiveHelper.isDesktop(context) ? 28 : 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Farm Overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
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
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.isDesktop(context) ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1)),
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
                  color: color,
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
              color: AppTheme.textDark,
              fontSize: ResponsiveHelper.isDesktop(context) ? 24 : 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textGrey,
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                itemBuilder: (context, index) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                    child: Icon(
                      Icons.notifications,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  title: Text('Notification ${index + 1}'),
                  subtitle: Text('This is a sample notification message'),
                  trailing: Text('${index + 1}h ago'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}