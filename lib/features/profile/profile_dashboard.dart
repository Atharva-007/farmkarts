import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/user_state_service.dart';

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
          backgroundColor: AppTheme.backgroundLight,
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: () async {
                  await userState.initializeUser();
                },
                color: AppTheme.primaryGreen,
                child: CustomScrollView(
                  slivers: [
                    _buildAppBar(user),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: AppConstants.defaultPadding,
                        child: Column(
                          children: [
                            if (userState.isLoading) ...[
                              const SizedBox(height: 100),
                              const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primaryGreen,
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
      },
    );
  }

  Widget _buildAppBar(UserModel? user) {
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
                      Icon(
                        user?.role == UserRole.farmer ? Icons.agriculture : Icons.store,
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

  Widget _buildProfileHeader(UserModel user) {
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
              Colors.white,
              AppTheme.primaryGreen.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Profile Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                  child: Icon(
                    user.role == UserRole.farmer ? Icons.agriculture : Icons.store,
                    size: 60,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: user.role == UserRole.farmer ? AppTheme.success : AppTheme.info,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      user.role == UserRole.farmer ? Icons.verified : Icons.business,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // User Details
            Text(
              user.fullName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: user.role == UserRole.farmer 
                    ? AppTheme.success.withOpacity(0.1)
                    : AppTheme.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                user.role == UserRole.farmer ? 'Farmer' : 'Vendor/Addat',
                style: TextStyle(
                  color: user.role == UserRole.farmer ? AppTheme.success : AppTheme.info,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textGrey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.mobileNo,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSpecificInfo(UserModel user) {
    if (user is FarmerModel) {
      return Card(
        child: Padding(
          padding: AppConstants.defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.landscape, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Text(
                    'Farm Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.area_chart,
                      label: 'Land Area',
                      value: '${user.acresLand} acres',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.calendar_today,
                      label: 'Member Since',
                      value: _formatDate(user.createdAt),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else if (user is AddatModel) {
      return Card(
        child: Padding(
          padding: AppConstants.defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.store, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Text(
                    'Business Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoItem(
                icon: Icons.business,
                label: 'Shop Name',
                value: user.dukanName,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: user.isLicenseVerified ? Icons.verified : Icons.pending,
                      label: 'License Status',
                      value: user.isLicenseVerified ? 'Verified' : 'Pending',
                      valueColor: user.isLicenseVerified ? AppTheme.success : AppTheme.warning,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.calendar_today,
                      label: 'Member Since',
                      value: _formatDate(user.createdAt),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
            Icon(icon, size: 16, color: AppTheme.textGrey),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textGrey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(UserModel user) {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Stats',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.trending_up,
                    label: 'Total Sales',
                    value: '0', // TODO: Implement actual stats
                    color: AppTheme.success,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.star,
                    label: 'Rating',
                    value: '0.0', // TODO: Implement actual rating
                    color: AppTheme.warning,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.inventory,
                    label: user.role == UserRole.farmer ? 'Products' : 'Inventory',
                    value: '0', // TODO: Implement actual count
                    color: AppTheme.info,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textGrey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMenuSections(UserModel user) {
    return Column(
      children: [
        _buildMenuSection('Account', [
          _MenuOption(
            icon: Icons.edit,
            title: 'Edit Profile',
            subtitle: 'Update your personal information',
            onTap: _editProfile,
          ),
          _MenuOption(
            icon: Icons.security,
            title: 'Security',
            subtitle: 'Change password and security settings',
            onTap: _openSecurity,
          ),
        ]),
        const SizedBox(height: 16),
        if (user.role == UserRole.farmer)
          _buildMenuSection('Farm Management', [
            _MenuOption(
              icon: Icons.landscape,
              title: 'Farm Details',
              subtitle: 'Manage your farm information',
              onTap: _openFarmDetails,
            ),
            _MenuOption(
              icon: Icons.schedule,
              title: 'Crop Calendar',
              subtitle: 'Plan your farming activities',
              onTap: _openCropCalendar,
            ),
          ])
        else
          _buildMenuSection('Business Management', [
            _MenuOption(
              icon: Icons.inventory,
              title: 'Inventory',
              subtitle: 'Manage your product inventory',
              onTap: _openInventory,
            ),
            _MenuOption(
              icon: Icons.verified,
              title: 'License Management',
              subtitle: 'View and update your license',
              onTap: _openLicenseManagement,
            ),
          ]),
      ],
    );
  }

  Widget _buildMenuSection(String title, List<_MenuOption> options) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...options.map((option) => ListTile(
            leading: Icon(option.icon, color: AppTheme.primaryGreen),
            title: Text(option.title),
            subtitle: Text(option.subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: option.onTap,
          )),
        ],
      ),
    );
  }

  Widget _buildAccountActions() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.help_outline, color: AppTheme.info),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openHelp,
          ),
          ListTile(
            leading: Icon(Icons.logout, color: AppTheme.error),
            title: const Text('Logout'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return const Center(
      child: Text('Please log in to view your profile'),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Action methods
  void _editProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit Profile coming soon!')),
    );
  }

  void _openSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings coming soon!')),
    );
  }

  void _openSecurity() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Security settings coming soon!')),
    );
  }

  void _openFarmDetails() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Farm details coming soon!')),
    );
  }

  void _openCropCalendar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Crop calendar coming soon!')),
    );
  }

  void _openInventory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Inventory management coming soon!')),
    );
  }

  void _openLicenseManagement() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('License management coming soon!')),
    );
  }

  void _openHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Help & Support coming soon!')),
    );
  }

  void _logout() async {
    final userStateService = Provider.of<UserStateService>(context, listen: false);
    await userStateService.clearUser();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
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