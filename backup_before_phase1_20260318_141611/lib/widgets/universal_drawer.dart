import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../main_app_layout.dart';
import '../pages/buying_list_page.dart';
import '../pages/contacted_sellers_page.dart';
import '../features/chat/ai_chat_sessions_page.dart';
import '../features/weather/weather_dashboard.dart';
import '../pages/settings_page.dart';
import '../pages/wishlist_page.dart';
import '../pages/cart_page.dart';
import '../services/user_state_service.dart';

class UniversalDrawer extends StatelessWidget {
  final String currentPage;

  const UniversalDrawer({
    super.key,
    this.currentPage = '',
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userState = Provider.of<UserStateService>(context);

    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerHeader(user, userState),
            _buildMainNavigationSection(context),
            const Divider(height: 1, thickness: 1),
            _buildSecondaryNavigationSection(context),
            const Divider(height: 1, thickness: 1),
            _buildBottomSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(User? user, UserStateService userState) {
    final userName = userState.currentUser?.fullName ?? user?.displayName ?? 'Guest User';
    
    return DrawerHeader(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: user?.photoURL != null
                ? ClipOval(child: Image.network(user!.photoURL!, fit: BoxFit.cover))
                : Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? 'Guest User',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMainNavigationSection(BuildContext context) {
    return Column(
      children: [
        _buildSectionTitle('Main Menu'),
        _buildDrawerItem(
          context,
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          title: 'Dashboard',
          page: 'dashboard',
          route: '/home',
        ),
        _buildDrawerItem(
          context,
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          title: 'Community',
          page: 'community',
          route: '/community',
        ),
        _buildDrawerItem(
          context,
          icon: Icons.agriculture_outlined,
          selectedIcon: Icons.agriculture,
          title: 'Crops',
          page: 'crops',
          route: '/crops',
        ),
        _buildDrawerItem(
          context,
          icon: Icons.wb_sunny_outlined,
          selectedIcon: Icons.wb_sunny,
          title: 'Weather',
          page: 'weather',
          route: '/weather',
        ),
        _buildDrawerItem(
          context,
          icon: Icons.psychology_outlined,
          selectedIcon: Icons.psychology,
          title: 'AI Expert',
          page: 'ai-chat',
          route: '/ai-chat',
        ),
      ],
    );
  }

  Widget _buildSecondaryNavigationSection(BuildContext context) {
    return Column(
      children: [
        _buildSectionTitle('My Account'),
        _buildDrawerItem(
          context,
          icon: Icons.favorite_outline,
          selectedIcon: Icons.favorite,
          title: 'Wishlist',
          page: 'wishlist',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WishlistPage()),
            );
          },
        ),
        _buildDrawerItem(
          context,
          icon: Icons.shopping_cart_outlined,
          selectedIcon: Icons.shopping_cart,
          title: 'Shopping Cart',
          page: 'cart',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartPage()),
            );
          },
        ),
        _buildDrawerItem(
          context,
          icon: Icons.shopping_bag_outlined,
          selectedIcon: Icons.shopping_bag,
          title: 'My Orders',
          page: 'orders',
          route: '/orders',
        ),
        _buildDrawerItem(
          context,
          icon: Icons.chat_bubble_outline,
          selectedIcon: Icons.chat_bubble,
          title: 'Messages',
          page: 'messages',
          route: '/contacted-sellers',
        ),
      ],
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return Column(
      children: [
        _buildSectionTitle('More'),
        _buildDrawerItem(
          context,
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          title: 'Profile',
          page: 'profile',
          route: '/profile',
        ),
        _buildDrawerItem(
          context,
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          title: 'Settings',
          page: 'settings',
          route: '/settings',
        ),
        _buildDrawerItem(
          context,
          icon: Icons.info_outline,
          selectedIcon: Icons.info,
          title: 'About',
          page: 'about',
          onTap: () => _showAboutDialog(context),
        ),
        const SizedBox(height: 8),
        _buildLogoutButton(context),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textGrey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String title,
    required String page,
    String? route,
    VoidCallback? onTap,
  }) {
    final isSelected = currentPage.toLowerCase() == page.toLowerCase();

    return Material(
      color: isSelected ? AppTheme.primaryGreen.withOpacity(0.08) : Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => _navigateToPage(context, route),
        splashColor: AppTheme.primaryGreen.withOpacity(0.1),
        highlightColor: AppTheme.primaryGreen.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? AppTheme.primaryGreen : AppTheme.textDark.withOpacity(0.7),
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppTheme.primaryGreen : AppTheme.textDark,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showLogoutDialog(context),
          icon: const Icon(Icons.logout, size: 20),
          label: const Text('Logout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.error,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  void _navigateToPage(BuildContext context, String? route) {
    if (route == null) return;

    // Close drawer immediately for faster response
    Navigator.pop(context);

    // Map routes to their proper implementations
    switch (route) {
      case '/home':
      case '/dashboard':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainAppLayout(initialIndex: 0)),
        );
        break;
      
      case '/marketplace':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainAppLayout(initialIndex: 1)),
        );
        break;
      
      case '/community':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainAppLayout(initialIndex: 2)),
        );
        break;
      
      case '/crops':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainAppLayout(initialIndex: 3)),
        );
        break;
      
      case '/weather':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WeatherDashboard()),
        );
        break;
      
      case '/apmc':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainAppLayout(initialIndex: 3)),
        );
        break;
      
      case '/profile':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainAppLayout(initialIndex: 4)),
        );
        break;
      
      case '/orders':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BuyingListPage()),
        );
        break;
      
      case '/contacted-sellers':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ContactedSellersPage()),
        );
        break;
      
      case '/ai-chat':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AIChatSessionsPage()),
        );
        break;
      
      case '/settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
        break;
      
      default:
        // Unknown route, go to home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainAppLayout(initialIndex: 0)),
        );
    }
  }

  void _showAboutDialog(BuildContext context) {
    // Close drawer immediately
    Navigator.pop(context);

    // Show dialog immediately for faster response
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Image.asset('assets/icons/app_icon.png', width: 40, height: 40, errorBuilder: (_, __, ___) => const Icon(Icons.agriculture, size: 40, color: AppTheme.primaryGreen)),
            const SizedBox(width: 12),
            const Text('FarmKarts'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0'),
            SizedBox(height: 8),
            Text('Your trusted agricultural marketplace and farming companion.'),
            SizedBox(height: 12),
            Text('© 2024 FarmKarts. All rights reserved.'),
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

  void _showLogoutDialog(BuildContext context) {
    // Close drawer immediately
    Navigator.pop(context);

    // Show dialog immediately for faster response
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
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
