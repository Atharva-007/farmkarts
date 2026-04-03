import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'features/dashboard/dashboard_home.dart';
import 'features/marketplace/complete_functional_marketplace.dart';
import 'features/community/community_dashboard.dart';
import 'features/crops/crops_dashboard.dart';
import 'features/weather/weather_dashboard.dart';
import 'features/apmc/enhanced_apmc_market_live_fixed.dart';
import 'features/profile/profile_dashboard.dart';
import 'features/chat/enhanced_ai_expert_chat_page.dart';
import 'pages/orders_page.dart';
import 'pages/contacted_sellers_page.dart';
import 'pages/settings_page.dart';
import 'services/user_state_service.dart';
import 'models/user_model.dart';

class MainAppLayout extends StatefulWidget {
  final int? initialIndex;
  
  const MainAppLayout({super.key, this.initialIndex});

  @override
  State<MainAppLayout> createState() => _MainAppLayoutState();
}

class _MainAppLayoutState extends State<MainAppLayout> {
  int _currentIndex = 0;
  late PageController _pageController;
  late List<Widget> _pages;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initializePages();
    _currentIndex = widget.initialIndex ?? 0;
    // Ensure index is within valid range
    if (_currentIndex >= _pages.length) {
      _currentIndex = 0;
    }
    _pageController = PageController(initialPage: _currentIndex);
  }

  void _initializePages() {
    _pages = [
      DashboardHome(onNavigate: _navigateToPage),
      const CompleteFunctionalMarketplace(),
      const CropsDashboard(),
      const EnhancedAPMCMarketLiveFixed(),
      const ProfileDashboard(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppTheme.darkBackground : null,
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _pages.length,
        itemBuilder: (context, index) {
          return _pages[index];
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      drawer: _buildDrawer(),
      extendBody: true, // Allow content to extend behind bottom nav
    );
  }



  Widget _buildBottomNavigationBar() {
    final safeIndex = _currentIndex.clamp(0, _pages.length - 1);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: isDark 
            ? Border.all(color: const Color(0xFF1F1F1F), width: 1.5)
            : Border.all(color: AppTheme.primaryGreen.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.8) 
                : AppTheme.primaryGreen.withOpacity(0.15),
            blurRadius: isDark ? 30 : 24,
            spreadRadius: 0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Container(
          height: 65,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.dashboard_rounded, Icons.dashboard_outlined, 'Home'),
              _buildNavItem(1, Icons.storefront, Icons.storefront_outlined, 'Market'),
              _buildNavItem(2, Icons.agriculture, Icons.agriculture_outlined, 'Crops'),
              _buildNavItem(3, Icons.business, Icons.business_outlined, 'APMC'),
              _buildNavItem(4, Icons.person, Icons.person_outline, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (index != _currentIndex && index < _pages.length) {
            setState(() => _currentIndex = index);
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        },
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 60,
            maxWidth: 70,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: EdgeInsets.all(isSelected ? 4 : 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryGreen.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  size: isSelected ? 24 : 22,
                  color: isSelected
                      ? AppTheme.primaryGreen
                      : Theme.of(context).iconTheme.color?.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                style: TextStyle(
                  fontSize: isSelected ? 10 : 9,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppTheme.primaryGreen
                      : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                  height: 1.2,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Consumer<UserStateService>(
      builder: (context, userState, child) {
        final user = userState.currentUser;
        final userName = user?.fullName ?? 'User';
        final userEmail = user?.email ?? 'No email';
        final userRole = user?.role == UserRole.farmer ? 'Farmer' : 'Vendor/Addat';
        final roleIcon = user?.role == UserRole.farmer ? Icons.agriculture : Icons.store;

        return Drawer(
          backgroundColor: Colors.white,
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey, width: 0.5),
                  ),
                ),
                accountName: Text(
                  userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                accountEmail: Text(
                  userEmail,
                  style: const TextStyle(color: Colors.black54),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                  child: Icon(
                    roleIcon,
                    color: AppTheme.primaryGreen,
                    size: 35,
                  ),
                ),
                otherAccountsPictures: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      userRole,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  children: [
                    _buildDrawerItem(
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      isSelected: _currentIndex == 0,
                      onTap: () => _navigateToPage(0),
                    ),
                    _buildDrawerItem(
                      icon: Icons.storefront,
                      title: 'Marketplace',
                      isSelected: _currentIndex == 1,
                      onTap: () => _navigateToPage(1),
                    ),
                    _buildDrawerItem(
                      icon: Icons.people,
                      title: 'Community',
                      isSelected: _currentIndex == 2,
                      onTap: () => _navigateToPage(2),
                    ),
                    _buildDrawerItem(
                      icon: Icons.agriculture,
                      title: 'Crops',
                      isSelected: _currentIndex == 3,
                      onTap: () => _navigateToPage(3),
                    ),
                    _buildDrawerItem(
                      icon: Icons.wb_sunny,
                      title: 'Weather',
                      isSelected: _currentIndex == 4,
                      onTap: () => _navigateToPage(4),
                    ),
                    _buildDrawerItem(
                      icon: Icons.business,
                      title: 'APMC Market',
                      isSelected: _currentIndex == 5,
                      onTap: () => _navigateToPage(5),
                    ),
                    _buildDrawerItem(
                      icon: Icons.person,
                      title: 'Profile',
                      isSelected: _currentIndex == 6,
                      onTap: () => _navigateToPage(6),
                    ),
                    
                    const Divider(),
                    
                    // Orders and Contacted Sellers in sidebar
                    _buildDrawerItem(
                      icon: Icons.shopping_bag,
                      title: 'My Orders',
                      onTap: () => _navigateToOrders(),
                    ),
                    _buildDrawerItem(
                      icon: Icons.chat_bubble,
                      title: 'Contacted Sellers',
                      onTap: () => _navigateToContactedSellers(),
                    ),
                    
                    const Divider(),
                    
                    // AI Chat Feature
                    _buildDrawerItem(
                      icon: Icons.psychology,
                      title: 'AI Expert Chat',
                      onTap: () => _navigateToAIChat(),
                    ),
                    
                    // Additional features
                    _buildDrawerItem(
                      icon: Icons.analytics,
                      title: 'Analytics',
                      onTap: () => _showComingSoon('Analytics Dashboard'),
                    ),
                    _buildDrawerItem(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      onTap: () => _showComingSoon('Help & Support'),
                    ),
                    _buildDrawerItem(
                      icon: Icons.settings,
                      title: 'Settings',
                      onTap: () => _navigateToSettings(),
                    ),
                    
                    const Divider(),
                    
                    _buildDrawerItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      textColor: AppTheme.error,
                      onTap: () => _showLogoutDialog(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryGreen.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pop(context);
            Future.delayed(const Duration(milliseconds: 200), onTap);
          },
          child: ListTile(
            dense: true,
            visualDensity: VisualDensity.comfortable,
            leading: Icon(
              icon,
              color: isSelected ? AppTheme.primaryGreen : (textColor ?? Colors.grey[700]),
              size: 24,
            ),
            title: Text(
              title,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryGreen : (textColor ?? Colors.grey[800]),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToPage(int index) {
    if (index != _currentIndex && index >= 0 && index < _pages.length) {
      setState(() {
        _currentIndex = index;
      });
      _pageController.jumpToPage(index);
    }
  }

  void _navigateToAIChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EnhancedAIExpertChatPage(),
      ),
    );
  }

  void _navigateToOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OrdersPage(),
      ),
    );
  }

  void _navigateToContactedSellers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ContactedSellersPage(),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildNotificationsSheet(),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Search products, farmers, or markets...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            if (value.isNotEmpty) {
              _performSearch(value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSheet() {
    final notifications = [
      _NotificationItem(
        title: 'New Market Rate Update',
        subtitle: 'Wheat prices increased by 2.5% in Mumbai APMC',
        time: '5 min ago',
        icon: Icons.trending_up,
        color: AppTheme.success,
      ),
      _NotificationItem(
        title: 'Weather Alert',
        subtitle: 'Heavy rainfall expected in your area tomorrow',
        time: '1 hour ago',
        icon: Icons.cloud,
        color: AppTheme.warning,
      ),
      _NotificationItem(
        title: 'Community Post',
        subtitle: 'Ram Sharma shared farming tips in your community',
        time: '2 hours ago',
        icon: Icons.people,
        color: AppTheme.info,
      ),
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Mark all as read
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All notifications marked as read'),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                },
                child: const Text('Mark all read'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationCard(notification);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(_NotificationItem notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: notification.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            notification.icon,
            color: notification.color,
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.subtitle,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              notification.time,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textGrey,
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.pop(context);
          // Handle notification tap
        },
      ),
    );
  }

  void _performSearch(String query) {
    // Navigate to search results or filter current page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Searching for: $query'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement logout logic
              _performLogout();
            },
            child: const Text('Logout', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _performLogout() {
    // Implement logout logic here
    Navigator.pushReplacementNamed(context, '/login');
  }
}

class _NotificationItem {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;

  _NotificationItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });
}