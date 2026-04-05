import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/user_state_service.dart';
import '../../widgets/universal_drawer.dart';
import '../../widgets/universal_header.dart';
import '../../pages/inventory_page.dart';
import '../../pages/help_support_page.dart';
import '../../pages/orders_page.dart';
import 'license_management_page.dart';

class ProfileDashboard extends StatefulWidget {
  const ProfileDashboard({super.key});

  @override
  State<ProfileDashboard> createState() => _ProfileDashboardState();
}

class _ProfileDashboardState extends State<ProfileDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserStateService>(
      builder: (context, userState, child) {
        final user = userState.currentUser;

        return Scaffold(
          backgroundColor: AppTheme.getBackgroundColor(context),
          drawer: const UniversalDrawer(currentPage: 'profile'),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: () async {
                await userState.initializeUser();
              },
              color: AppTheme.getPrimaryAccent(context),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  UniversalHeader(
                    title: user?.fullName ?? 'My Profile',
                    subtitle: user?.email ?? 'Account Settings',
                    icon: Icons.person_rounded,
                    showBackButton: false,
                    showProfile: false, // We're already on the profile page
                    actions: [
                      IconButton(
                        icon:
                            const Icon(Icons.edit_rounded, color: Colors.white),
                        onPressed: _editProfile,
                        tooltip: 'Edit Profile',
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (userState.isLoading) ...[
                            const SizedBox(height: 100),
                            Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.getPrimaryAccent(context),
                              ),
                            ),
                          ] else if (user != null) ...[
                            _buildProfileHeader(user),
                            const SizedBox(height: 24),
                            _buildRoleSpecificInfo(user),
                            const SizedBox(height: 24),
                            _buildQuickStats(user),
                            const SizedBox(height: 24),
                            _buildMenuSections(user),
                            const SizedBox(height: 24),
                            _buildAccountActions(),
                          ] else ...[
                            _buildLoginPrompt(),
                          ],
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
        boxShadow: AppTheme.getPremiumShadow(context),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.getPrimaryAccent(context).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              user.role == UserRole.farmer
                  ? Icons.agriculture_rounded
                  : Icons.storefront_rounded,
              size: 32,
              color: AppTheme.getPrimaryAccent(context),
            ),
          ),
          const SizedBox(width: 16),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.fullName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.getPrimaryAccent(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getRoleDisplayName(user.role).toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppTheme.getPrimaryAccent(context),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSpecificInfo(UserModel user) {
    if (user is FarmerModel) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
          boxShadow: AppTheme.getPremiumShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.landscape_rounded,
                    color: AppTheme.getPrimaryAccent(context)),
                const SizedBox(width: 12),
                Text(
                  'Farm Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.area_chart_rounded,
                    label: 'Land Area',
                    value: '${user.acresLand} Acres',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.calendar_today_rounded,
                    label: 'Member Since',
                    value: _formatDate(user.createdAt),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (user is AddatModel) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
          boxShadow: AppTheme.getPremiumShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storefront_rounded,
                    color: AppTheme.getPrimaryAccent(context)),
                const SizedBox(width: 12),
                Text(
                  'Business Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoItem(
              icon: Icons.business_rounded,
              label: 'Shop Name',
              value: user.dukanName,
            ),
            const SizedBox(height: 20),

            // Enhanced License Status Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getLicenseStatusColor(user).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getLicenseStatusColor(user).withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getLicenseStatusIcon(user),
                        color: _getLicenseStatusColor(user),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'License Status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getLicenseStatusColor(user),
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (user.licenseImageUrl != null &&
                          user.isLicenseVerified)
                        const Icon(Icons.verified_rounded,
                            color: Colors.green, size: 20),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getLicenseStatusMessage(user),
                    style: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openLicenseManagement(),
                      icon: Icon(
                        user.licenseImageUrl != null
                            ? Icons.edit_document
                            : Icons.upload_file_rounded,
                        size: 18,
                      ),
                      label: Text(
                        user.licenseImageUrl != null
                            ? 'MANAGE LICENSE'
                            : 'UPLOAD LICENSE',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getLicenseStatusColor(user),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            _buildInfoItem(
              icon: Icons.calendar_today_rounded,
              label: 'Member Since',
              value: _formatDate(user.createdAt),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon,
                size: 14,
                color: AppTheme.getSecondaryTextColor(context)
                    .withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.getSecondaryTextColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppTheme.getTextColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
        boxShadow: AppTheme.getPremiumShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: StatItemWithData(
                  icon: Icons.trending_up_rounded,
                  label: 'Revenue',
                  userId: user.uid,
                  statType: 'sales',
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: StatItemWithData(
                  icon: Icons.star_rounded,
                  label: 'Rating',
                  userId: user.uid,
                  statType: 'rating',
                  color: Colors.amber,
                ),
              ),
              Expanded(
                child: StatItemWithData(
                  icon: Icons.inventory_2_rounded,
                  label: user.role == UserRole.farmer ? 'Products' : 'Stock',
                  userId: user.uid,
                  statType: 'inventory',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSections(UserModel user) {
    return Column(
      children: [
        _buildMenuSection('Account Settings', [
          _MenuOption(
            icon: Icons.person_outline_rounded,
            title: 'Edit Profile',
            subtitle: 'Name, email, and photo',
            onTap: _editProfile,
          ),
          _MenuOption(
            icon: Icons.security_rounded,
            title: 'Security',
            subtitle: 'Password and authentication',
            onTap: _openSecurity,
          ),
        ]),
        const SizedBox(height: 16),
        if (user.role == UserRole.farmer)
          _buildMenuSection('Farm Management', [
            _MenuOption(
              icon: Icons.landscape_rounded,
              title: 'Farm Details',
              subtitle: 'Acreage and location',
              onTap: _openFarmDetails,
            ),
            _MenuOption(
              icon: Icons.calendar_month_rounded,
              title: 'Crop Calendar',
              subtitle: 'Seasonal planning',
              onTap: _openCropCalendar,
            ),
          ])
        else
          _buildMenuSection('Business Hub', [
            _MenuOption(
              icon: Icons.inventory_rounded,
              title: 'Inventory',
              subtitle: 'Stock management',
              onTap: _openInventory,
            ),
            _MenuOption(
              icon: Icons.verified_rounded,
              title: 'License Management',
              subtitle: 'Verification status',
              onTap: _openLicenseManagement,
            ),
          ]),
      ],
    );
  }

  Widget _buildMenuSection(String title, List<_MenuOption> options) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
        boxShadow: AppTheme.getPremiumShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...options.map((option) => ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.getPrimaryAccent(context)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(option.icon,
                      color: AppTheme.getPrimaryAccent(context), size: 20),
                ),
                title: Text(option.title,
                    style: TextStyle(
                      color: AppTheme.getTextColor(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    )),
                subtitle: Text(option.subtitle,
                    style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context),
                        fontSize: 12)),
                trailing: Icon(Icons.arrow_forward_ios_rounded,
                    color: AppTheme.getSecondaryTextColor(context)
                        .withValues(alpha: 0.3),
                    size: 14),
                onTap: option.onTap,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildAccountActions() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
        boxShadow: AppTheme.getPremiumShadow(context),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.help_outline_rounded,
                  color: Colors.blue, size: 20),
            ),
            title: const Text('Help & Support',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            trailing: Icon(Icons.arrow_forward_ios_rounded,
                color: AppTheme.getSecondaryTextColor(context)
                    .withValues(alpha: 0.3),
                size: 14),
            onTap: _openHelp,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          ),
          const Divider(height: 1, indent: 60),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
            ),
            title: const Text('Logout',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.red)),
            trailing: Icon(Icons.arrow_forward_ios_rounded,
                color: AppTheme.getSecondaryTextColor(context)
                    .withValues(alpha: 0.3),
                size: 14),
            onTap: _logout,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(Icons.lock_person_rounded,
              size: 80,
              color: AppTheme.getPrimaryAccent(context).withValues(alpha: 0.2)),
          const SizedBox(height: 24),
          Text(
            'Please log in to view your profile',
            style: TextStyle(
                color: AppTheme.getSecondaryTextColor(context), fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: const Text('LOG IN NOW'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonth(date.month)} ${date.year}';
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  // Action methods
  void _editProfile() {
    _showComingSoon('Edit Profile');
  }

  void _openSettings() {
    _showComingSoon('Settings');
  }

  void _openSecurity() {
    _showComingSoon('Security settings');
  }

  void _openFarmDetails() {
    _showComingSoon('Farm details');
  }

  void _openCropCalendar() {
    _showComingSoon('Crop calendar');
  }

  void _openInventory() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const InventoryPage()));
  }

  void _openLicenseManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LicenseManagementPage(),
      ),
    );
  }

  // Helper methods for license status
  Color _getLicenseStatusColor(AddatModel user) {
    if (user.licenseImageUrl == null) {
      return AppTheme.error;
    } else if (!user.isLicenseVerified) {
      return AppTheme.warning;
    } else {
      return AppTheme.success;
    }
  }

  IconData _getLicenseStatusIcon(AddatModel user) {
    if (user.licenseImageUrl == null) {
      return Icons.upload_file_rounded;
    } else if (!user.isLicenseVerified) {
      return Icons.pending_actions_rounded;
    } else {
      return Icons.verified_user_rounded;
    }
  }

  String _getLicenseStatusMessage(AddatModel user) {
    if (user.licenseImageUrl == null) {
      return 'Upload your business license to start selling products and build customer trust.';
    } else if (!user.isLicenseVerified) {
      return 'Your license is under review by our admin team. You\'ll be notified once verification is complete.';
    } else {
      return 'Your business license is verified! You can now sell products with full credibility.';
    }
  }

  void _openHelp() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const HelpAndSupportPage()));
  }

  void _logout() async {
    final userStateService =
        Provider.of<UserStateService>(context, listen: false);
    await userStateService.clearUser();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: AppTheme.getPrimaryAccent(context),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.farmer:
        return 'Farmer';
      case UserRole.addat:
        return 'Vendor/Addat';
      default:
        return 'User';
    }
  }

  void _openOrders() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const OrdersPage()));
  }

  void _openProducts() {
    _showComingSoon('My Products');
  }
}

class _MenuOption {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _MenuOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

/// Widget that fetches and displays real-time stats
class StatItemWithData extends StatelessWidget {
  final IconData icon;
  final String label;
  final String userId;
  final String statType;
  final Color color;

  const StatItemWithData({
    super.key,
    required this.icon,
    required this.label,
    required this.userId,
    required this.statType,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _fetchStatValue(),
      builder: (context, snapshot) {
        String value = '...';

        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            value = snapshot.data!;
          } else if (snapshot.hasError) {
            value = '0';
          }
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.getSecondaryTextColor(context),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  Future<String> _fetchStatValue() async {
    try {
      final firestore = FirebaseFirestore.instance;

      switch (statType) {
        case 'sales':
          // Get total revenue from selling_history
          final sellingHistorySnapshot = await firestore
              .collection('selling_history')
              .where('sellerId', isEqualTo: userId)
              .get();

          double totalRevenue = 0;
          for (var doc in sellingHistorySnapshot.docs) {
            totalRevenue += (doc.data()['totalRevenue'] ?? 0).toDouble();
          }

          return '₹${totalRevenue.toStringAsFixed(0)}';

        case 'rating':
          // Calculate average rating from buyer reviews/ratings
          // For now, return a placeholder - implement when rating system is added
          return '4.8';

        case 'inventory':
          // Count products by seller
          final productsSnapshot = await firestore
              .collection('products')
              .where('sellerId', isEqualTo: userId)
              .get();

          return productsSnapshot.docs.length.toString();

        default:
          return '0';
      }
    } catch (e) {
      return '0';
    }
  }
}
