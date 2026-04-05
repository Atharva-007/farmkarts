import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../pages/main_app_layout.dart';
import '../pages/contacted_sellers_page.dart';
import '../features/crops/ai_crop_page.dart';
import '../features/community/community_dashboard.dart';
import '../pages/settings_page.dart';
import '../pages/wishlist_page.dart';
import '../pages/inventory_page.dart';
import '../pages/orders_page.dart';
import '../pages/help_support_page.dart';
import '../services/user_state_service.dart';
import '../models/user_model.dart';

class UniversalDrawer extends StatelessWidget {
  final String currentPage;
  final Function(int)? onNavigate;

  const UniversalDrawer({
    super.key,
    this.currentPage = '',
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userState = Provider.of<UserStateService>(context);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.9),
        border: Border(
          right: BorderSide(
            color: AppTheme.getBorderColor(context).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Drawer(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Column(
              children: [
                _buildDrawerHeader(user, userState, context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildSectionHeader('GENERAL'),
                      _buildDrawerItem(
                        context,
                        icon: Icons.dashboard_rounded,
                        title: 'Home',
                        page: 'dashboard',
                        index: 0,
                        route: '/dashboard',
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.storefront_rounded,
                        title: 'Marketplace',
                        page: 'marketplace',
                        index: 1,
                        route: '/marketplace',
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.business_center_rounded,
                        title: 'APMC Market',
                        page: 'apmc',
                        index: 3,
                        route: '/apmc',
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.people_alt_rounded,
                        title: 'Community',
                        page: 'community',
                        route: '/community',
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.auto_awesome_rounded,
                        title: 'AI Crop',
                        page: 'crops',
                        route: '/crops',
                      ),

                      _buildSectionHeader('MY ACTIVITY'),
                      _buildDrawerItem(
                        context,
                        icon: Icons.shopping_bag_rounded,
                        title: 'My Orders',
                        page: 'orders',
                        route: '/orders',
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.favorite_rounded,
                        title: 'Wishlist',
                        page: 'wishlist',
                        onTap: () {
                          if (Scaffold.of(context).isDrawerOpen) {
                            Navigator.pop(context);
                          }
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const WishlistPage()));
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.chat_rounded,
                        title: 'Messages',
                        page: 'messages',
                        route: '/contacted-sellers',
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.inventory_2_rounded,
                        title: 'Farm Inventory',
                        page: 'inventory',
                        route: '/inventory',
                      ),

                      _buildSectionHeader('SUPPORT & ACCOUNT'),
                      _buildDrawerItem(
                        context,
                        icon: Icons.settings_rounded,
                        title: 'Settings',
                        page: 'settings',
                        route: '/settings',
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.help_center_rounded,
                        title: 'Help & Support',
                        page: 'help',
                        route: '/help',
                      ),

                      // SIGN OUT INTEGRATED INTO SECTION
                      _buildDrawerItem(
                        context,
                        icon: Icons.logout_rounded,
                        title: 'Sign Out',
                        page: 'logout',
                        onTap: () => _showLogoutDialog(context),
                        iconColor: AppTheme.error,
                        textColor: AppTheme.error,
                      ),

                      // CRITICAL: Bottom Padding to clear Floating Nav Bar
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: AppTheme.primaryGreen.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(
      User? user, UserStateService userState, BuildContext context) {
    final userName =
        userState.currentUser?.fullName ?? user?.displayName ?? 'Guest User';

    String userRoleLabel = 'Guest';
    if (userState.currentUser != null) {
      switch (userState.currentUser!.role) {
        case UserRole.farmer:
          userRoleLabel = 'Farmer';
          break;
        case UserRole.addat:
          userRoleLabel = 'Addat';
          break;
        case UserRole.vendor:
          userRoleLabel = 'Vendor';
          break;
        case UserRole.wholesaler:
          userRoleLabel = 'Wholesaler';
          break;
        case UserRole.admin:
          userRoleLabel = 'Admin';
          break;
        case UserRole.customer:
          userRoleLabel = 'Customer';
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.getBorderColor(context).withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: user?.photoURL != null
                      ? ClipOval(
                          child: Image.network(user!.photoURL!,
                              width: 52, height: 52, fit: BoxFit.cover))
                      : Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        color: AppTheme.getTextColor(context),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.getPrimaryAccent(context)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        userRoleLabel.toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.getPrimaryAccent(context),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String page,
    int? index,
    String? route,
    VoidCallback? onTap,
    Widget? trailing,
    Color? iconColor,
    Color? textColor,
  }) {
    final isSelected = currentPage.toLowerCase() == page.toLowerCase();
    final accentColor = AppTheme.getPrimaryAccent(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected
            ? accentColor.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (onTap != null) {
              onTap();
            } else if (index != null && onNavigate != null) {
              onNavigate!(index);
            } else {
              _navigateToPage(context, route);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? accentColor
                      : (iconColor ??
                          AppTheme.getSecondaryTextColor(context)
                              .withValues(alpha: 0.7)),
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? accentColor
                          : (textColor ??
                              AppTheme.getTextColor(context)
                                  .withValues(alpha: 0.8)),
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToPage(BuildContext context, String? route) {
    if (route == null) return;

    final isDrawer = Scaffold.maybeOf(context)?.isDrawerOpen ?? false;
    if (isDrawer) {
      Navigator.pop(context);
    }

    if (currentPage == route.replaceFirst('/', '')) return;

    switch (route) {
      case '/dashboard':
      case '/home':
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const MainAppLayout(initialIndex: 0)));
        break;
      case '/marketplace':
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const MainAppLayout(initialIndex: 1)));
        break;
      case '/ai-chat':
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const MainAppLayout(initialIndex: 2)));
        break;
      case '/apmc':
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const MainAppLayout(initialIndex: 3)));
        break;
      case '/profile':
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const MainAppLayout(initialIndex: 4)));
        break;
      case '/crops':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const AICropPage()));
        break;
      case '/community':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const CommunityDashboard()));
        break;
      case '/orders':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const OrdersPage()));
        break;
      case '/contacted-sellers':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ContactedSellersPage()));
        break;
      case '/inventory':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const InventoryPage()));
        break;
      case '/settings':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const SettingsPage()));
        break;
      case '/help':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const HelpAndSupportPage()));
        break;
      default:
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const MainAppLayout(initialIndex: 0)));
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Sign Out',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content:
            const Text('Are you sure you want to sign out from FarmKarts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style:
                    TextStyle(color: AppTheme.getSecondaryTextColor(context))),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
