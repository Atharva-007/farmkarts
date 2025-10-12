import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'utils/responsive_helper.dart';
import 'features/dashboard/dashboard_home.dart';
import 'features/marketplace/marketplace_home.dart';
import 'features/community/community_dashboard.dart';
import 'features/crops/crops_dashboard.dart';
import 'features/weather/weather_dashboard.dart';
import 'features/apmc/apmc_market_page.dart';
import 'features/profile/profile_dashboard.dart';
import 'services/user_state_service.dart';
import 'models/user_model.dart';

class MainAppLayout extends StatefulWidget {
  const MainAppLayout({super.key});

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
    _pageController = PageController();
    _pages = [
      DashboardHome(onNavigate: _navigateToPage),
      const MarketplaceHome(),
      const CommunityDashboard(),
      const CropsDashboard(),
      const WeatherDashboard(),
      const APMCMarketPage(),
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
    if (_currentIndex == 1) { // Marketplace page
      return FloatingActionButton.extended(
        onPressed: () {
          // Navigate to add product page or show add product dialog
          _showAddProductDialog();
        },
        backgroundColor: AppTheme.accentOrange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white)),
      );
    }
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.menu,
              color: AppTheme.primaryGreen,
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
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () => _showComingSoon('Notifications'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () => _showComingSoon('Search'),
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
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                accountName: Text(
                  userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                accountEmail: Text(userEmail),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
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
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      userRole,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
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