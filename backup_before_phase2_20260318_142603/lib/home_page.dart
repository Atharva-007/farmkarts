



import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'utils/responsive_helper.dart';

// Import your separate page files here:
import 'buy_page.dart';
import 'sell_page.dart';
import 'news_page.dart';
import 'settings_page.dart';
import 'APMCpage.dart';
import 'MAHABEJpage.dart';
import 'mandi_page.dart';
import 'features/marketplace/marketplace_home.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bannerFadeAnimation;
  late Animation<double> _buttonScaleAnimation;

  final Map<String, bool> _hovering = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _bannerFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _buttonScaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quickAccessButtons = [
      const _QuickAccessData(
        Icons.shopping_cart, 
        'Buy', 
        AppTheme.primaryGreen,
        AppTheme.lightGreen, 
        BuyPage()
      ),
      const _QuickAccessData(
        Icons.sell, 
        'Sell', 
        AppTheme.accentOrange,
        AppTheme.lightOrange, 
        SellPage()
      ),
      const _QuickAccessData(
        Icons.storefront, 
        'Marketplace', 
        AppTheme.primaryGreen,
        AppTheme.lightGreen, 
        MarketplaceHome()
      ),
      const _QuickAccessData(
        Icons.article, 
        'News', 
        AppTheme.skyBlue,
        AppTheme.info, 
        NewsPage()
      ),
      const _QuickAccessData(
        Icons.store, 
        'APMC', 
        AppTheme.earthBrown,
        AppTheme.textGrey, 
        APMCPage()
      ),
      const _QuickAccessData(
        Icons.grass, 
        'Mahabej', 
        AppTheme.freshMint,
        AppTheme.success, 
        MahabejPage()
      ),
      const _QuickAccessData(
        Icons.currency_rupee, 
        'Mandi', 
        AppTheme.harvest,
        AppTheme.warning, 
        MandiPricesPage()
      ),
      const _QuickAccessData(
        Icons.settings, 
        'Settings', 
        AppTheme.textGrey,
        AppTheme.borderGrey, 
        SettingsPage()
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('FarmKarts Home'),
        backgroundColor: AppTheme.primaryGreen,
        elevation: 2,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 80), // Prevent overlap with navigation
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnimatedBanner(),
              const SizedBox(height: 24),
              _buildQuickAccessGrid(quickAccessButtons, theme),
              const SizedBox(height: 24),
              _buildFeaturedProducts(),
              const SizedBox(height: 24),
              _buildLatestNews(),
              const SizedBox(height: 24),
              _buildTipsAndInsights(),
              const SizedBox(height: 24),
              _buildTestimonials(),
              const SizedBox(height: 24),
              _buildPopularCategories(),
              const SizedBox(height: 24),
              _buildWeatherWidget(),
              const SizedBox(height: 24),
              _buildCallToActionBanner(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBanner() {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return FadeTransition(
      opacity: _bannerFadeAnimation,
      child: Container(
        margin: ResponsiveHelper.getScreenPadding(context).copyWith(top: 0, bottom: 0),
        padding: EdgeInsets.all(isDesktop ? 24 : 20),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.defaultShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.agriculture, 
              color: Colors.white, 
              size: isDesktop ? 48 : 40,
            ),
            SizedBox(width: isMobile ? 8 : 12),
            Expanded(
              child: Text(
                "Welcome to FarmKarts!",
                style: TextStyle(
                  fontSize: isDesktop ? 26 : 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessGrid(
      List<_QuickAccessData> buttons, ThemeData theme) {
    return Container(
      margin: ResponsiveHelper.getScreenPadding(context).copyWith(top: 0, bottom: 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = ResponsiveHelper.isDesktop(context);
          final isTablet = ResponsiveHelper.isTablet(context);
          
          int crossAxisCount = 2;
          double childAspectRatio = 1.1;
          
          if (isDesktop) {
            crossAxisCount = 4;
            childAspectRatio = 0.95;
          } else if (isTablet) {
            crossAxisCount = 3;
            childAspectRatio = 1.0;
          } else {
            crossAxisCount = 2;
            childAspectRatio = 1.1;
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: isDesktop ? 16 : 12,
              mainAxisSpacing: isDesktop ? 16 : 12,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: buttons.length,
            itemBuilder: (context, index) {
              final button = buttons[index];
              final isHover = _hovering[button.label] ?? false;

              return MouseRegion(
                onEnter: (_) => setState(() => _hovering[button.label] = true),
                onExit: (_) => setState(() => _hovering[button.label] = false),
                child: ScaleTransition(
                  scale: _buttonScaleAnimation,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => button.page),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: isHover
                            ? button.secondaryColor.withOpacity(0.1)
                            : button.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: isHover
                                ? button.secondaryColor.withOpacity(0.3)
                                : Colors.black.withOpacity(0.1),
                            blurRadius: isHover ? 8 : 4,
                            offset: Offset(0, isHover ? 4 : 2),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            button.icon,
                            size: 28,
                            color: button.secondaryColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            button.label,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: button.secondaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFeaturedProducts() {
    return FadeTransition(
      opacity: _bannerFadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Featured Products',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFeaturedProductCard(
                    'Fresh Tomatoes', 40, 'assets/tomatoes.jpg'),
                _buildFeaturedProductCard(
                    'Organic Wheat', 30, 'assets/wheat.jpg'),
                _buildFeaturedProductCard(
                    'Green Capsicum', 50, 'assets/capsicum.jpg'),
                _buildFeaturedProductCard('Mangoes', 100, 'assets/mangoes.jpg'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedProductCard(String name, int price, String imagePath) {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, spreadRadius: 2)
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.asset(imagePath, height: 80, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          Text(name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('₹$price/kg',
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildLatestNews() {
    return FadeTransition(
      opacity: _bannerFadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Latest News',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildNewsTile(
              'Govt announces subsidies for organic farming',
              'New scheme to support organic farmers was unveiled.'),
          _buildNewsTile('APMC prices hit record high',
              'Wheat prices see a significant rise due to increased demand.'),
          _buildNewsTile('New irrigation techniques improve yield',
              'Farmers benefit from drip irrigation technology.'),
        ],
      ),
    );
  }

  Widget _buildNewsTile(String title, String subtitle) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.fiber_new, color: Colors.redAccent),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: () {},
        hoverColor: Colors.red.shade50,
      ),
    );
  }

  Widget _buildTipsAndInsights() {
    return FadeTransition(
      opacity: _bannerFadeAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.lightGreen.shade100,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withAlpha(51),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text(
          'Did you know? Proper irrigation and timely use of organic fertilizers can increase crop yield by up to 30%!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  Widget _buildTestimonials() {
    return FadeTransition(
      opacity: _bannerFadeAnimation,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What Our Farmers Say',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Card(
            elevation: 4,
            margin: EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Icon(Icons.person, size: 48, color: Colors.green),
              title: Text('Ramesh Kumar'),
              subtitle: Text(
                  '"This app helped me sell my crops directly to buyers, no middlemen! Highly recommended."'),
            ),
          ),
          Card(
            elevation: 4,
            margin: EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Icon(Icons.person, size: 48, color: Colors.green),
              title: Text('Sunita Devi'),
              subtitle: Text(
                  '"The weather updates and crop tips have been invaluable for my farming."'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularCategories() {
    return FadeTransition(
      opacity: _bannerFadeAnimation,
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          _buildCategoryChip('Vegetables', Icons.grass),
          _buildCategoryChip('Fruits', Icons.local_florist),
          _buildCategoryChip('Grains', Icons.agriculture),
          _buildCategoryChip('Dairy', Icons.egg),
          _buildCategoryChip('Pulses', Icons.eco),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 20),
      label: Text(label),
      backgroundColor: AppTheme.primaryGreen,
      labelStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildWeatherWidget() {
// Placeholder for weather info; you can expand with actual API integration
    return FadeTransition(
      opacity: _bannerFadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withAlpha(51),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.cloud, size: 48, color: Colors.blue),
            SizedBox(width: 16),
            Text(
              'Current Weather: Sunny, 32°C',
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallToActionBanner() {
    return FadeTransition(
      opacity: _bannerFadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.orangeAccent, Colors.deepOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withAlpha(102),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Join the community of farmers and buyers today! Get started now!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
// For example, navigate to signup or sell page
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const SellPage()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepOrange,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Get Started',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper data class for quick access buttons
class _QuickAccessData {
  final IconData icon;
  final String label;
  final Color primaryColor;
  final Color secondaryColor;
  final Widget page;

  const _QuickAccessData(
      this.icon, this.label, this.primaryColor, this.secondaryColor, this.page);
}