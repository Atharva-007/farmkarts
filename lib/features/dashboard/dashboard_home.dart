import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/weather_widget.dart';
import '../../widgets/crop_status_card.dart';
import '../../widgets/market_price_ticker.dart';
import '../../widgets/quick_action_grid.dart';
import '../../widgets/analytics_summary.dart';
import '../../widgets/news_carousel.dart';

class DashboardHome extends StatefulWidget {
  final Function(int)? onNavigate;
  
  const DashboardHome({super.key, this.onNavigate});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final PageController _bannerPageController = PageController();
  int _currentBannerIndex = 0;

  final List<String> _bannerImages = [
    'https://images.unsplash.com/photo-1500595046743-cd271d694d30?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1374&q=80',
    'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1374&q=80',
    'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80',
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppAnimations.slow,
      vsync: this,
    );
    _slideController = AnimationController(
      duration: AppAnimations.normal,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
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

    return Container(
      color: AppTheme.backgroundLight,
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: AppTheme.primaryGreen,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildAppBar(userName),
                  SliverPadding(
                    padding: EdgeInsets.only(
                      bottom: ResponsiveHelper.isMobile(context) ? 100 : 120
                    ), // Bottom navigation padding
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildHeroBanner(),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.75),
                        _buildQuickActions(),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.75),
                        _buildMarketPriceTicker(),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.75),
                        _buildCropStatusOverview(),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.75),
                        _buildAnalyticsSummary(),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.75),
                        _buildLatestNews(),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.75),
                        _buildEducationalContent(),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.75),
                        _buildCommunityHighlights(),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 1.5),
                      ]),
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

  Widget _buildAppBar(String userName) {
    return SliverAppBar(
      expandedHeight: ResponsiveHelper.isMobile(context) ? 100 : 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.primaryGreen,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: ResponsiveHelper.getResponsivePadding(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: ResponsiveHelper.isMobile(context) ? 20 : 25,
                        child: Icon(
                          Icons.person,
                          color: AppTheme.primaryGreen,
                          size: ResponsiveHelper.isMobile(context) ? 24 : 30,
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context) * 0.75),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ResponsiveHelper.autoSizeText(
                              'Good Morning,',
                              context: context,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                                fontSize: ResponsiveHelper.getFontSize(context, 14),
                              ),
                            ),
                            ResponsiveHelper.autoSizeText(
                              userName,
                              context: context,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: ResponsiveHelper.getFontSize(context, 20),
                              ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.notifications_outlined, 
                          color: Colors.white,
                          size: ResponsiveHelper.isMobile(context) ? 22 : 24,
                        ),
                        onPressed: () {
                          // Navigate to notifications
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      margin: ResponsiveHelper.getResponsiveHorizontalPadding(context),
      child: Column(
        children: [
          SizedBox(
            height: ResponsiveHelper.isMobile(context) ? 160 : 180,
            child: PageView.builder(
              controller: _bannerPageController,
              onPageChanged: (index) {
                setState(() {
                  _currentBannerIndex = index;
                });
              },
              itemCount: _bannerImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getResponsiveSpacing(context) * 0.25,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: ResponsiveHelper.getResponsiveBorderRadius(context),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: ResponsiveHelper.getResponsiveBorderRadius(context),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          _bannerImages[index],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: AppTheme.cardGrey,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppTheme.cardGrey,
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: AppTheme.textGrey,
                              ),
                            );
                          },
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: ResponsiveHelper.getResponsiveSpacing(context) * 0.75,
                          left: ResponsiveHelper.getResponsiveSpacing(context) * 0.75,
                          right: ResponsiveHelper.getResponsiveSpacing(context) * 0.75,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ResponsiveHelper.autoSizeText(
                                'Smart Farming Solutions',
                                context: context,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: ResponsiveHelper.getFontSize(context, 18),
                                ),
                                maxLines: 1,
                              ),
                              const SizedBox(height: 2),
                              ResponsiveHelper.autoSizeText(
                                'Grow better with technology',
                                context: context,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                  fontSize: ResponsiveHelper.getFontSize(context, 14),
                                ),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.5),
          AnimatedSmoothIndicator(
            activeIndex: _currentBannerIndex,
            count: _bannerImages.length,
            effect: WormEffect(
              dotColor: AppTheme.borderGrey,
              activeDotColor: AppTheme.primaryGreen,
              dotHeight: ResponsiveHelper.isMobile(context) ? 5 : 6,
              dotWidth: ResponsiveHelper.isMobile(context) ? 5 : 6,
              spacing: ResponsiveHelper.isMobile(context) ? 6 : 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherAndAlerts() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: const WeatherWidget(),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: ResponsiveHelper.getResponsiveHorizontalPadding(context),
      child: QuickActionGrid(onNavigate: widget.onNavigate),
    );
  }

  Widget _buildMarketPriceTicker() {
    return const MarketPriceTicker();
  }

  Widget _buildCropStatusOverview() {
    return Container(
      margin: ResponsiveHelper.getResponsiveHorizontalPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveHelper.autoSizeText(
            'Crop Status Overview',
            context: context,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: ResponsiveHelper.getFontSize(context, 20),
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.5),
          const CropStatusCard(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSummary() {
    return Container(
      margin: ResponsiveHelper.getResponsiveHorizontalPadding(context),
      child: const AnalyticsSummary(),
    );
  }

  Widget _buildLatestNews() {
    return Container(
      margin: ResponsiveHelper.getResponsiveHorizontalPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ResponsiveHelper.autoSizeText(
                  'Latest Agriculture News',
                  context: context,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveHelper.getFontSize(context, 20),
                  ),
                  maxLines: 1,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to news page
                },
                child: ResponsiveHelper.autoSizeText(
                  'See All',
                  context: context,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getFontSize(context, 14),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.5),
          const NewsCarousel(),
        ],
      ),
    );
  }

  Widget _buildEducationalContent() {
    return ResponsiveHelper.responsiveCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school,
                color: AppTheme.primaryGreen,
                size: ResponsiveHelper.isMobile(context) ? 20 : 24,
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context) * 0.5),
              ResponsiveHelper.autoSizeText(
                'Today\'s Learning',
                context: context,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveHelper.getFontSize(context, 18),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.75),
          Container(
            padding: ResponsiveHelper.getResponsivePadding(context).copyWith(
              top: 12,
              bottom: 12,
            ),
            decoration: BoxDecoration(
              color: AppTheme.lightGreen.withValues(alpha: 0.1),
              borderRadius: ResponsiveHelper.getResponsiveBorderRadius(context).copyWith(
                topLeft: const Radius.circular(8),
                topRight: const Radius.circular(8),
                bottomLeft: const Radius.circular(8),
                bottomRight: const Radius.circular(8),
              ),
              border: Border.all(
                color: AppTheme.lightGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: AppTheme.sunshine,
                  size: ResponsiveHelper.isMobile(context) ? 18 : 20,
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context) * 0.5),
                Expanded(
                  child: ResponsiveHelper.autoSizeText(
                    'Tip: Apply nitrogen fertilizer when corn plants are 6-8 inches tall for optimal growth.',
                    context: context,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: ResponsiveHelper.getFontSize(context, 14),
                    ),
                    maxLines: ResponsiveHelper.isMobile(context) ? 2 : 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityHighlights() {
    return ResponsiveHelper.responsiveCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ResponsiveHelper.autoSizeText(
                  'Community Highlights',
                  context: context,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveHelper.getFontSize(context, 18),
                  ),
                  maxLines: 1,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to community
                },
                child: ResponsiveHelper.autoSizeText(
                  'Join Discussion',
                  context: context,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getFontSize(context, 14),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.75),
          _buildCommunityItem(
            'Success Story: 40% yield increase with organic farming',
            '2 hours ago',
            Icons.trending_up,
            AppTheme.success,
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.5),
          _buildCommunityItem(
            'Q&A: Best practices for monsoon crop protection',
            '5 hours ago',
            Icons.help_outline,
            AppTheme.info,
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityItem(String title, String time, IconData icon, Color color) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context).copyWith(
        top: 12,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: ResponsiveHelper.getResponsiveBorderRadius(context).copyWith(
          topLeft: const Radius.circular(8),
          topRight: const Radius.circular(8),
          bottomLeft: const Radius.circular(8),
          bottomRight: const Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon, 
            color: color, 
            size: ResponsiveHelper.isMobile(context) ? 18 : 20
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context) * 0.75),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveHelper.autoSizeText(
                  title,
                  context: context,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveHelper.getFontSize(context, 14),
                  ),
                  maxLines: ResponsiveHelper.isMobile(context) ? 2 : 1,
                ),
                const SizedBox(height: 2),
                ResponsiveHelper.autoSizeText(
                  time,
                  context: context,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textGrey,
                    fontSize: ResponsiveHelper.getFontSize(context, 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}