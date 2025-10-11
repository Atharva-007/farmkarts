  import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/responsive_cards.dart';
import '../../widgets/weather_widget.dart';
import '../marketplace/enhanced_marketplace_home.dart';

class EnhancedDashboardHome extends StatefulWidget {
  const EnhancedDashboardHome({super.key});

  @override
  State<EnhancedDashboardHome> createState() => _EnhancedDashboardHomeState();
}

class _EnhancedDashboardHomeState extends State<EnhancedDashboardHome>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: _refreshDashboard,
            color: AppTheme.primaryGreen,
            child: SingleChildScrollView(
              padding: ResponsiveHelper.getScreenPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildQuickActions(),
                  const SizedBox(height: 20),
                  _buildOverviewCards(),
                  const SizedBox(height: 20),
                  _buildWeatherSection(),
                  const SizedBox(height: 20),
                  _buildRecentActivities(),
                  const SizedBox(height: 20),
                  _buildMarketInsights(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final user = FirebaseAuth.instance.currentUser;
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.defaultShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: isDesktop ? 30 : 25,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: isDesktop ? 32 : 28,
                ),
              ),
              SizedBox(width: isDesktop ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isDesktop ? 16 : 14,
                      ),
                    ),
                    Text(
                      user?.displayName ?? user?.email?.split('@')[0] ?? 'Farmer',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isDesktop ? 24 : 20,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile) ...[
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  tooltip: 'Notifications',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.settings, color: Colors.white),
                  tooltip: 'Settings',
                ),
              ],
            ],
          ),
          
          if (!isMobile) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _buildHeaderStat('Farm Area', '12.5 acres'),
                const SizedBox(width: 20),
                _buildHeaderStat('Active Crops', '5 varieties'),
                const SizedBox(width: 20),
                _buildHeaderStat('This Month', '₹45,230'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    
    final actions = [
      {'title': 'Marketplace', 'icon': Icons.storefront, 'color': AppTheme.primaryGreen, 'onTap': _navigateToMarketplace},
      {'title': 'Weather', 'icon': Icons.cloud, 'color': AppTheme.skyBlue, 'onTap': _navigateToWeather},
      {'title': 'Crops', 'icon': Icons.agriculture, 'color': AppTheme.lightGreen, 'onTap': _navigateToCrops},
      {'title': 'Analytics', 'icon': Icons.analytics, 'color': AppTheme.accentOrange, 'onTap': _navigateToAnalytics},
    ];

    return ResponsiveSection(
      title: 'Quick Actions',
      subtitle: 'Access your most used features',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isMobile ? 2 : (isDesktop ? 4 : 3),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isDesktop ? 1.2 : 1.0,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return ResponsiveGridCard(
            title: action['title'] as String,
            value: '',
            icon: action['icon'] as IconData,
            color: action['color'] as Color,
            onTap: action['onTap'] as VoidCallback,
          );
        },
      ),
    );
  }

  Widget _buildOverviewCards() {
    final overviewData = [
      {'title': 'Total Revenue', 'value': '₹1,25,430', 'icon': Icons.trending_up, 'color': AppTheme.success, 'subtitle': '+12% from last month'},
      {'title': 'Active Listings', 'value': '8', 'icon': Icons.inventory, 'color': AppTheme.primaryGreen, 'subtitle': '3 sold this week'},
      {'title': 'Harvest Ready', 'value': '3', 'icon': Icons.agriculture, 'color': AppTheme.accentOrange, 'subtitle': 'Tomatoes, Wheat, Rice'},
      {'title': 'Weather Alert', 'value': 'Good', 'icon': Icons.wb_sunny, 'color': AppTheme.sunshine, 'subtitle': 'Perfect for farming'},
    ];

    return ResponsiveSection(
      title: 'Farm Overview',
      subtitle: 'Your farm metrics at a glance',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(context, mobile: 2, tablet: 2, desktop: 4),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: ResponsiveHelper.isDesktop(context) ? 1.0 : 1.1,
        ),
        itemCount: overviewData.length,
        itemBuilder: (context, index) {
          final data = overviewData[index];
          return ResponsiveGridCard(
            title: data['title'] as String,
            value: data['value'] as String,
            icon: data['icon'] as IconData,
            color: data['color'] as Color,
            subtitle: data['subtitle'] as String,
          );
        },
      ),
    );
  }

  Widget _buildWeatherSection() {
    return ResponsiveSection(
      title: 'Weather Forecast',
      subtitle: 'Plan your farming activities',
      onSeeAll: _navigateToWeather,
      child: const WeatherWidget(),
    );
  }

  Widget _buildRecentActivities() {
    final activities = [
      {'title': 'Product Listed', 'subtitle': 'Fresh Tomatoes - ₹40/kg', 'time': '2 hours ago', 'icon': Icons.add_circle, 'color': AppTheme.success},
      {'title': 'Order Received', 'subtitle': 'Organic Wheat - 50kg', 'time': '5 hours ago', 'icon': Icons.shopping_bag, 'color': AppTheme.primaryGreen},
      {'title': 'Payment Received', 'subtitle': '₹2,000 from Raj Kumar', 'time': '1 day ago', 'icon': Icons.payment, 'color': AppTheme.accentOrange},
      {'title': 'Crop Harvested', 'subtitle': 'Rice - 2 acres completed', 'time': '2 days ago', 'icon': Icons.agriculture, 'color': AppTheme.lightGreen},
    ];

    return ResponsiveSection(
      title: 'Recent Activities',
      subtitle: 'Your latest farm activities',
      child: Column(
        children: activities.map((activity) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: EnhancedDashboardCard(
              title: activity['title'] as String,
              subtitle: '${activity['subtitle']} • ${activity['time']}',
              icon: activity['icon'] as IconData,
              iconColor: activity['color'] as Color,
              height: ResponsiveHelper.isDesktop(context) ? 80 : 70,
            ),
          ),
        ).toList(),
      ),
    );
  }

  Widget _buildMarketInsights() {
    final insights = [
      {'title': 'Tomato Prices', 'value': '₹42/kg', 'change': '+5%', 'color': AppTheme.success},
      {'title': 'Wheat Demand', 'value': 'High', 'change': 'Trending', 'color': AppTheme.primaryGreen},
      {'title': 'Rice Market', 'value': '₹58/kg', 'change': '-2%', 'color': AppTheme.error},
    ];

    return ResponsiveSection(
      title: 'Market Insights',
      subtitle: 'Current market trends and prices',
      onSeeAll: _navigateToMarketplace,
      child: Column(
        children: insights.map((insight) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (insight['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: insight['color'] as Color,
                    size: 20,
                  ),
                ),
                title: Text(
                  insight['title'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(insight['change'] as String),
                trailing: Text(
                  insight['value'] as String,
                  style: TextStyle(
                    color: insight['color'] as Color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ).toList(),
      ),
    );
  }

  Future<void> _refreshDashboard() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dashboard refreshed!'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  void _navigateToMarketplace() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EnhancedMarketplaceHome(),
      ),
    );
  }

  void _navigateToWeather() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Weather section coming soon!')),
    );
  }

  void _navigateToCrops() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Crops management coming soon!')),
    );
  }

  void _navigateToAnalytics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analytics section coming soon!')),
    );
  }
}