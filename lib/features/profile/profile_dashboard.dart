import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../models/product_model.dart';
// import '../profile/edit_profile_page.dart';
// import '../profile/farm_details_page.dart';
// import '../profile/transaction_history_page.dart';
// import '../profile/settings_page.dart';

class ProfileDashboard extends StatefulWidget {
  const ProfileDashboard({super.key});

  @override
  State<ProfileDashboard> createState() => _ProfileDashboardState();
}

class _ProfileDashboardState extends State<ProfileDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  UserProfile? _userProfile;
  bool _isLoading = true;

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
    
    _loadUserProfile();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await _usersRef.child(user.uid).once();
      if (snapshot.snapshot.value != null) {
        setState(() {
          _userProfile = UserProfile.fromMap(
            user.uid,
            snapshot.snapshot.value as Map<dynamic, dynamic>,
          );
          _isLoading = false;
        });
      } else {
        // Create default profile if doesn't exist
        _userProfile = UserProfile(
          id: user.uid,
          name: user.displayName ?? user.email?.split('@')[0] ?? 'Farmer',
          email: user.email ?? '',
          joinDate: DateTime.now(),
        );
        await _usersRef.child(user.uid).set(_userProfile!.toMap());
        setState(() => _isLoading = false);
      }
    } catch (e) {
      // Create fallback profile
      final user = FirebaseAuth.instance.currentUser!;
      setState(() {
        _userProfile = UserProfile(
          id: user.uid,
          name: user.displayName ?? user.email?.split('@')[0] ?? 'Farmer',
          email: user.email ?? '',
          joinDate: DateTime.now(),
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: _loadUserProfile,
            color: AppTheme.primaryGreen,
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: AppConstants.defaultPadding,
                    child: Column(
                      children: [
                        if (_isLoading) ...[
                          const SizedBox(height: 100),
                          const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ] else if (_userProfile != null) ...[
                          _buildProfileHeader(),
                          const SizedBox(height: 24),
                          _buildQuickStats(),
                          const SizedBox(height: 24),
                          _buildFarmingAchievements(),
                          const SizedBox(height: 24),
                          _buildMenuSections(),
                          const SizedBox(height: 24),
                          _buildAccountActions(),
                        ] else ...[
                          _buildLoginPrompt(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: AppConstants.defaultPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Profile',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: _editProfile,
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: _openSettings,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: AppConstants.largePadding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              AppTheme.surfaceWhite,
              AppTheme.lightGreen.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryGreen,
                  child: _userProfile!.profileImageUrl.isNotEmpty
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: _userProfile!.profileImageUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                ),
                if (_userProfile!.isVerified)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _userProfile!.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _userProfile!.email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textGrey,
              ),
            ),
            if (_userProfile!.farmName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.agriculture,
                      size: 16,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _userProfile!.farmName,
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildProfileStat(
                  'Rating',
                  '${_userProfile!.rating.toStringAsFixed(1)} ⭐',
                  AppTheme.sunshine,
                ),
                _buildProfileStat(
                  'Sales',
                  '${_userProfile!.totalSales}',
                  AppTheme.success,
                ),
                _buildProfileStat(
                  'Member Since',
                  _formatJoinDate(_userProfile!.joinDate),
                  AppTheme.skyBlue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Stats',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Revenue',
                    '₹2,45,000',
                    Icons.account_balance_wallet,
                    AppTheme.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Active Listings',
                    '8',
                    Icons.list,
                    AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Orders',
                    '23',
                    Icons.shopping_bag,
                    AppTheme.accentOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Farm Size',
                    '${_userProfile!.farmSize} acres',
                    Icons.landscape,
                    AppTheme.earthBrown,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFarmingAchievements() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Farming Achievements',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildAchievement(
              'Top Seller',
              'Achieved highest sales this month',
              Icons.star,
              AppTheme.sunshine,
            ),
            const SizedBox(height: 8),
            _buildAchievement(
              'Quality Producer',
              'Maintained 4.8+ rating for 6 months',
              Icons.verified,
              AppTheme.success,
            ),
            const SizedBox(height: 8),
            _buildAchievement(
              'Organic Certified',
              'Certified organic farm practices',
              Icons.eco,
              AppTheme.lightGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievement(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSections() {
    return Column(
      children: [
        _buildMenuSection(
          'Account Management',
          [
            _MenuItem('Edit Profile', Icons.edit, _editProfile),
            _MenuItem('Farm Details', Icons.landscape, _viewFarmDetails),
            _MenuItem('Transaction History', Icons.history, _viewTransactions),
            _MenuItem('Security Settings', Icons.security, _securitySettings),
          ],
        ),
        const SizedBox(height: 16),
        _buildMenuSection(
          'Business',
          [
            _MenuItem('My Products', Icons.inventory, _viewMyProducts),
            _MenuItem('Sales Analytics', Icons.analytics, _viewAnalytics),
            _MenuItem('Customer Reviews', Icons.rate_review, _viewReviews),
            _MenuItem('Subscription', Icons.card_membership, _viewSubscription),
          ],
        ),
        const SizedBox(height: 16),
        _buildMenuSection(
          'Support & Information',
          [
            _MenuItem('Help Center', Icons.help, _helpCenter),
            _MenuItem('Contact Support', Icons.support_agent, _contactSupport),
            _MenuItem('Privacy Policy', Icons.privacy_tip, _privacyPolicy),
            _MenuItem('Terms of Service', Icons.description, _termsOfService),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuSection(String title, List<_MenuItem> items) {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => _buildMenuItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(_MenuItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(item.icon, color: AppTheme.primaryGreen, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textGrey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _shareProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.skyBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.share, color: Colors.white),
            label: const Text(
              'Share Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_outline,
            size: 80,
            color: AppTheme.textGrey,
          ),
          const SizedBox(height: 16),
          Text(
            'Please Login',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Login to access your profile and manage your account',
            style: TextStyle(color: AppTheme.textGrey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  String _formatJoinDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).round()}m ago';
    } else {
      return '${(difference.inDays / 365).round()}y ago';
    }
  }

  // Navigation methods
  void _editProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit profile feature coming soon!')),
    );
  }

  void _openSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings feature coming soon!')),
    );
  }

  void _viewFarmDetails() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Farm details feature coming soon!')),
    );
  }

  void _viewTransactions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction history feature coming soon!')),
    );
  }

  void _securitySettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Security settings feature coming soon!')),
    );
  }

  void _viewMyProducts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('My products feature coming soon!')),
    );
  }

  void _viewAnalytics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analytics feature coming soon!')),
    );
  }

  void _viewReviews() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reviews feature coming soon!')),
    );
  }

  void _viewSubscription() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscription feature coming soon!')),
    );
  }

  void _helpCenter() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Help center feature coming soon!')),
    );
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Support contact feature coming soon!')),
    );
  }

  void _privacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy policy feature coming soon!')),
    );
  }

  void _termsOfService() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Terms of service feature coming soon!')),
    );
  }

  void _shareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile shared successfully!')),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  _MenuItem(this.title, this.icon, this.onTap);
}