import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../features/marketplace/marketplace_home.dart';
import '../features/community/community_dashboard.dart';
import '../features/profile/profile_dashboard.dart';
import '../sell_page.dart';
import '../news_page.dart';
import '../settings_page.dart';

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.storefront,
        title: 'Marketplace',
        subtitle: 'Buy & sell products',
        color: AppTheme.primaryGreen,
        onTap: () => _navigateToMarketplace(context),
      ),
      _QuickAction(
        icon: Icons.sell,
        title: 'Sell Crops',
        subtitle: 'List your produce',
        color: AppTheme.accentOrange,
        onTap: () => _navigateToSell(context),
      ),
      _QuickAction(
        icon: Icons.people,
        title: 'Community',
        subtitle: 'Connect with farmers',
        color: AppTheme.skyBlue,
        onTap: () => _navigateToCommunity(context),
      ),
      _QuickAction(
        icon: Icons.person,
        title: 'Profile',
        subtitle: 'Manage account',
        color: AppTheme.freshMint,
        onTap: () => _navigateToProfile(context),
      ),
      _QuickAction(
        icon: Icons.article,
        title: 'News',
        subtitle: 'Latest updates',
        color: AppTheme.harvest,
        onTap: () => _navigateToNews(context),
      ),
      _QuickAction(
        icon: Icons.settings,
        title: 'Settings',
        subtitle: 'App preferences',
        color: AppTheme.earthBrown,
        onTap: () => _navigateToSettings(context),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            // Responsive grid based on screen width
            int crossAxisCount = 2;
            double childAspectRatio = 1.1;
            
            if (constraints.maxWidth > 600) {
              crossAxisCount = 3;
              childAspectRatio = 1.0;
            }
            
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return _buildActionCard(context, action);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, _QuickAction action) {
    return Material(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(
              color: AppTheme.borderGrey.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  action.icon,
                  color: action.color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                action.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                action.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textGrey,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToMarketplace(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MarketplaceHome()),
    );
  }

  void _navigateToSell(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SellPage()),
    );
  }

  void _navigateToCommunity(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CommunityDashboard()),
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileDashboard()),
    );
  }

  void _navigateToNews(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewsPage()),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

}

class _QuickAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}