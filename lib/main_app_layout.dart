import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'features/dashboard/dashboard_home.dart';
import 'features/marketplace/marketplace_home.dart';
import 'features/community/community_dashboard.dart';
import 'features/profile/profile_dashboard.dart';
import 'news_page.dart';
import 'settings_page.dart';
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Widget> _pages = [
    const DashboardHome(),
    const MarketplaceHome(),
    const CommunityDashboard(),
    const ProfileDashboard(),
    const NewsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      drawer: _buildDrawer(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
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
      unselectedItemColor: AppTheme.textGrey,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.storefront),
          label: 'Marketplace',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Community',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.article),
          label: 'News',
        ),
      ],
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
                accountName: Row(
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        userRole,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                accountEmail: Text(userEmail),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    roleIcon,
                    color: AppTheme.primaryGreen,
                    size: 40,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    _buildDrawerItem(
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToPage(0);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.storefront,
                      title: 'Marketplace',
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToPage(1);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.people,
                      title: 'Community',
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToPage(2);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.person,
                      title: 'Profile',
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToPage(3);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.article,
                      title: 'Agriculture News',
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToPage(4);
                      },
                    ),
                    
                    // Role-specific menu items
                    if (user?.role == UserRole.farmer) ...[
                      const Divider(),
                      _buildDrawerItem(
                        icon: Icons.landscape,
                        title: 'My Farm',
                        onTap: () {
                          Navigator.pop(context);
                          _showComingSoon('My Farm Management');
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.schedule,
                        title: 'Crop Calendar',
                        onTap: () {
                          Navigator.pop(context);
                          _showComingSoon('Crop Calendar');
                        },
                      ),
                    ] else if (user?.role == UserRole.addat) ...[
                      const Divider(),
                      _buildDrawerItem(
                        icon: Icons.inventory,
                        title: 'My Inventory',
                        onTap: () {
                          Navigator.pop(context);
                          _showComingSoon('Inventory Management');
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.verified,
                        title: 'License Status',
                        onTap: () {
                          Navigator.pop(context);
                          _showLicenseStatus(user);
                        },
                      ),
                    ],
                    
                    const Divider(),
                    _buildDrawerItem(
                      icon: Icons.settings,
                      title: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsPage()),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon('Help & Support');
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.info_outline,
                      title: 'About',
                      onTap: () {
                        Navigator.pop(context);
                        _showAboutDialog();
                      },
                    ),
                    const Divider(),
                    _buildDrawerItem(
                      icon: Icons.logout,
                      title: 'Logout',
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
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryGreen),
      title: Text(title),
      onTap: onTap,
      hoverColor: AppTheme.primaryGreen.withOpacity(0.1),
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
        content: Text('$feature is coming soon!'),
        backgroundColor: AppTheme.info,
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About FarmKarts'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FarmKarts - Smart Agriculture Platform'),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Connecting farmers with buyers directly, eliminating middlemen and ensuring fair prices for everyone.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLicenseStatus(UserModel? user) {
    if (user is AddatModel) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('License Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    user.isLicenseVerified ? Icons.verified : Icons.pending,
                    color: user.isLicenseVerified ? AppTheme.success : AppTheme.warning,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user.isLicenseVerified ? 'Verified' : 'Pending Verification',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: user.isLicenseVerified ? AppTheme.success : AppTheme.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Shop Name: ${user.dukanName}'),
              const SizedBox(height: 8),
              if (!user.isLicenseVerified)
                const Text(
                  'Your license is under review. You will be notified once it\'s verified.',
                  style: TextStyle(color: AppTheme.textGrey),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
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
            onPressed: () async {
              Navigator.pop(context);
              final userStateService = Provider.of<UserStateService>(context, listen: false);
              await userStateService.clearUser();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}