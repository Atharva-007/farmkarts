import 'package:flutter/material.dart';
import 'colors.dart';

// Import your separate page files here:
import 'buy_page.dart';
import 'sell_page.dart';
import 'news_page.dart';
import 'settings_page.dart';
import 'APMCpage.dart';
import 'MAHABEJpage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
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
      _QuickAccessData(Icons.shopping_cart, 'Buy', Colors.teal, Colors.orange, const BuyPage()),
      _QuickAccessData(Icons.sell, 'Sell', Colors.teal, Colors.orange, const SellPage()),
      _QuickAccessData(Icons.article, 'News', Colors.teal, Colors.orange, NewsPage()),
      _QuickAccessData(Icons.settings, 'Settings', Colors.teal, Colors.orange, const SettingsPage()),
      _QuickAccessData(Icons.store, 'APMC', AppColors.deepBlue, AppColors.lightBlue, const APMCPage()),
      _QuickAccessData(Icons.grass, 'Mahabej', AppColors.darkGreen, AppColors.lightGreen, const MahabejPage()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmkart Home'),
        backgroundColor: AppColors.deepBlue,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedBanner(),
            const SizedBox(height: 40),
            _buildQuickAccessGrid(quickAccessButtons, theme),
            const SizedBox(height: 40),
            _buildFeaturedProducts(),
            const SizedBox(height: 40),
            _buildLatestNews(),
            const SizedBox(height: 40),
            _buildTipsAndInsights(),
            const SizedBox(height: 40),
            _buildTestimonials(),
            const SizedBox(height: 40),
            _buildPopularCategories(),
            const SizedBox(height: 40),
            _buildWeatherWidget(),
            const SizedBox(height: 40),
            _buildCallToActionBanner(),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBanner() {
    return FadeTransition(
      opacity: _bannerFadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.deepBlue,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.agriculture, color: Colors.white, size: 48),
            SizedBox(width: 16),
            Text(
              "Welcome to Farmer's Market App!",
              style: TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessGrid(List<_QuickAccessData> buttons, ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        if (constraints.maxWidth < 600) crossAxisCount = 2;
        if (constraints.maxWidth < 400) crossAxisCount = 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: 1,
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
                          ? button.secondaryColor.withOpacity(0.3)
                          : button.primaryColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isHover
                              ? button.secondaryColor.withOpacity(0.6)
                              : Colors.black.withOpacity(0.1),
                          blurRadius: isHover ? 15 : 6,
                          offset: Offset(0, isHover ? 6 : 3),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(button.icon, size: 36, color: button.secondaryColor),
                        const SizedBox(height: 12),
                        Text(
                          button.label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: button.secondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }

  Widget _buildFeaturedProducts() {
    return FadeTransition(
      opacity: _bannerFadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Featured Products', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFeaturedProductCard('Fresh Tomatoes', 40, 'assets/tomatoes.jpg'),
                _buildFeaturedProductCard('Organic Wheat', 30, 'assets/wheat.jpg'),
                _buildFeaturedProductCard('Green Capsicum', 50, 'assets/capsicum.jpg'),
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
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, spreadRadius: 2)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.asset(imagePath, height: 80, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('₹$price/kg', style: const TextStyle(fontSize: 16, color: Colors.grey)),
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
          const Text('Latest News', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildNewsTile('Govt announces subsidies for organic farming', 'New scheme to support organic farmers was unveiled.'),
          _buildNewsTile('APMC prices hit record high', 'Wheat prices see a significant rise due to increased demand.'),
          _buildNewsTile('New irrigation techniques improve yield', 'Farmers benefit from drip irrigation technology.'),
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
              color: Colors.green.withOpacity(0.2),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What Our Farmers Say', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.person, size: 48, color: Colors.green),
              title: const Text('Ramesh Kumar'),
              subtitle: const Text('"This app helped me sell my crops directly to buyers, no middlemen! Highly recommended."'),
            ),
          ),
          Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.person, size: 48, color: Colors.green),
              title: const Text('Sunita Devi'),
              subtitle: const Text('"The weather updates and crop tips have been invaluable for my farming."'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularCategories() {
    final categories = ['Vegetables', 'Fruits', 'Grains', 'Seeds', 'Fertilizers'];
    return FadeTransition(
      opacity: _bannerFadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Popular Categories', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: categories.map((cat) {
              return Chip(
                label: Text(cat),
                backgroundColor: Colors.lightGreen.shade200,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherWidget() {
    return FadeTransition(
      opacity: _bannerFadeAnimation,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Icon(Icons.wb_sunny, size: 48, color: Colors.orange),
            Text(
              'Weather Today: 32°C, Sunny',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            Icon(Icons.cloud_queue, size: 48, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildCallToActionBanner() {
    return FadeTransition(
        opacity: _bannerFadeAnimation,
        child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
    color: Colors.orange.shade300,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
    BoxShadow(
    color: Colors.orange.withOpacity(0.4),
    blurRadius: 12,
    offset: const Offset(0, 4),
    ),
    ],
    ),
    child: Column(
    children: const [
    Text(
    'Join the Farming Revolution!',
    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors
        .white),
    ),
      SizedBox(height: 12),
      Text(
        'Download our app now and connect directly with buyers.',
        style: TextStyle(fontSize: 20, color: Colors.white70),
        textAlign: TextAlign.center,
      ),
    ],
    ),
        ),
    );
  }
}

class _QuickAccessData {
  final IconData icon;
  final String label;
  final Color primaryColor;
  final Color secondaryColor;
  final Widget page;

  _QuickAccessData(this.icon, this.label, this.primaryColor, this.secondaryColor, this.page);
}


