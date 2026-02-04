import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'utils/responsive_helper.dart';
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
import 'services/user_state_service.dart';
import 'services/conversation_service.dart';
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
    _currentIndex = widget.initialIndex ?? 0;
    _pageController = PageController(initialPage: _currentIndex);
    _initializePages();
  }

  void _initializePages() {
    _pages = [
      DashboardHome(onNavigate: _navigateToPage),
      const CompleteFunctionalMarketplace(),
      const CommunityDashboard(),
      const CropsDashboard(),
      const WeatherDashboard(), 
      const EnhancedAPMCMarketLiveFixed(),
      const ProfileDashboard(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<String> _pageTitles = [
    'Dashboard',
    'Marketplace',
    'Community',
    'Crops',
    'Weather',
    'APMC Market',
    'Profile',
  ];

  Widget? _getFloatingActionButton() {
    return null;
  }

  void _showAddProductDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add Product feature coming soon!'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  children: _pages,
                ),
              ),
            ],
          ),
          
          // Floating menu button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: _buildFloatingMenuButton(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      drawer: _buildDrawer(),
      floatingActionButton: _getFloatingActionButton(),
    );
  }

  Widget _buildFloatingMenuButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.defaultShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.menu,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 80 + MediaQuery.of(context).padding.top,
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Space for floating menu button
              const SizedBox(width: 48),
              
              Expanded(
                child: Text(
                  _pageTitles[_currentIndex],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.notifications_outlined, color: Colors.white),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: AppTheme.error,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: const Text(
                              '3',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onPressed: () => _showNotifications(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () => _showSearchDialog(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryGreen,
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 11,
        unselectedFontSize: 9,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'Marketplace',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.agriculture_outlined),
            activeIcon: Icon(Icons.agriculture),
            label: 'Crops',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wb_sunny_outlined),
            activeIcon: Icon(Icons.wb_sunny),
            label: 'Weather',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business_outlined),
            activeIcon: Icon(Icons.business),
            label: 'APMC',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
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
                      onTap: () => _showComingSoon('Settings'),
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppTheme.primaryGreen : (textColor ?? Colors.grey[700]),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryGreen : (textColor ?? Colors.grey[800]),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
      ),
    );
  }

  void _navigateToPage(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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