import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';
import '../services/user_state_service.dart';
import '../models/user_model.dart';
import '../settings_page.dart';

class BaseLayoutWrapper extends StatelessWidget {
  final Widget child;
  final String title;
  final bool showAppBar;
  final bool showBottomNavBar;
  final bool showDrawer;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final int currentIndex;
  final Function(int)? onNavItemTapped;

  const BaseLayoutWrapper({
    super.key,
    required this.child,
    this.title = 'FarmKarts',
    this.showAppBar = true,
    this.showBottomNavBar = true,
    this.showDrawer = true,
    this.actions,
    this.floatingActionButton,
    this.currentIndex = 0,
    this.onNavItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar ? _buildAppBar(context) : null,
      body: child,
      bottomNavigationBar: showBottomNavBar ? _buildBottomNavigationBar(context) : null,
      drawer: showDrawer ? _buildDrawer(context) : null,
      floatingActionButton: floatingActionButton,
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: ResponsiveHelper.autoSizeText(
        title,
        context: context,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: AppTheme.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      actions: actions,
      leading: showDrawer
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            )
          : null,
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onNavItemTapped ?? (index) => _handleNavigation(context, index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppTheme.primaryGreen,
      unselectedItemColor: AppTheme.textGrey,
      elevation: 8,
      selectedFontSize: ResponsiveHelper.getFontSize(context, 12),
      unselectedFontSize: ResponsiveHelper.getFontSize(context, 10),
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
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
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
                    Expanded(
                      child: ResponsiveHelper.autoSizeText(
                        userName,
                        context: context,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ResponsiveHelper.autoSizeText(
                        userRole,
                        context: context,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                accountEmail: ResponsiveHelper.autoSizeText(
                  userEmail,
                  context: context,
                  style: const TextStyle(color: Colors.white70),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    roleIcon,
                    color: AppTheme.primaryGreen,
                    size: ResponsiveHelper.isMobile(context) ? 35 : 40,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    _buildDrawerItem(
                      context,
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToPage(context, 0);
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.storefront,
                      title: 'Marketplace',
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToPage(context, 1);
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.people,
                      title: 'Community',
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToPage(context, 2);
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.person,
                      title: 'Profile',
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToPage(context, 3);
                      },
                    ),
                    
                    // Role-specific menu items
                    if (user?.role == UserRole.farmer) ...[
                      const Divider(),
                      _buildDrawerItem(
                        context,
                        icon: Icons.landscape,
                        title: 'My Farm',
                        onTap: () {
                          Navigator.pop(context);
                          _showComingSoon(context, 'My Farm Management');
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.schedule,
                        title: 'Crop Calendar',
                        onTap: () {
                          Navigator.pop(context);
                          _showComingSoon(context, 'Crop Calendar');
                        },
                      ),
                    ] else if (user?.role == UserRole.addat) ...[
                      const Divider(),
                      _buildDrawerItem(
                        context,
                        icon: Icons.inventory,
                        title: 'My Inventory',
                        onTap: () {
                          Navigator.pop(context);
                          _showComingSoon(context, 'Inventory Management');
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.verified,
                        title: 'License Status',
                        onTap: () {
                          Navigator.pop(context);
                          _showLicenseStatus(context, user);
                        },
                      ),
                    ],
                    
                    const Divider(),
                    _buildDrawerItem(
                      context,
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
                      context,
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon(context, 'Help & Support');
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.info_outline,
                      title: 'About',
                      onTap: () {
                        Navigator.pop(context);
                        _showAboutDialog(context);
                      },
                    ),
                    const Divider(),
                    _buildDrawerItem(
                      context,
                      icon: Icons.logout,
                      title: 'Logout',
                      onTap: () => _showLogoutDialog(context),
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

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon, 
        color: AppTheme.primaryGreen,
        size: ResponsiveHelper.isMobile(context) ? 20 : 24,
      ),
      title: ResponsiveHelper.autoSizeText(
        title,
        context: context,
        style: TextStyle(
          fontSize: ResponsiveHelper.getFontSize(context, 16),
        ),
      ),
      onTap: onTap,
      hoverColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    // Navigate back to main app layout with the selected index
    if (ModalRoute.of(context)?.settings.name == '/home') {
      // Already on main layout, let parent handle
      if (onNavItemTapped != null) {
        onNavItemTapped!(index);
      }
    } else {
      // Navigate to main layout
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  void _navigateToPage(BuildContext context, int index) {
    // Navigate back to main app layout with the selected index
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming soon!'),
        backgroundColor: AppTheme.info,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
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

  void _showLicenseStatus(BuildContext context, UserModel? user) {
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

  void _showLogoutDialog(BuildContext context) {
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
              if (context.mounted) {
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