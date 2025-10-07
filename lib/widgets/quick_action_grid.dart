import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.shopping_cart,
        title: 'Buy Products',
        subtitle: 'Browse marketplace',
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
        icon: Icons.analytics,
        title: 'Farm Analytics',
        subtitle: 'View insights',
        color: AppTheme.skyBlue,
        onTap: () => _navigateToAnalytics(context),
      ),
      _QuickAction(
        icon: Icons.school,
        title: 'Learn',
        subtitle: 'Educational content',
        color: AppTheme.harvest,
        onTap: () => _navigateToEducation(context),
      ),
      _QuickAction(
        icon: Icons.chat,
        title: 'Expert Chat',
        subtitle: 'Get advice',
        color: AppTheme.freshMint,
        onTap: () => _navigateToExpertChat(context),
      ),
      _QuickAction(
        icon: Icons.camera_alt,
        title: 'Crop Doctor',
        subtitle: 'Diagnose diseases',
        color: AppTheme.earthBrown,
        onTap: () => _navigateToCropDoctor(context),
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
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionCard(context, action);
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
            border: Border.all(color: AppTheme.borderGrey),
            boxShadow: AppTheme.defaultShadow,
          ),
          padding: AppConstants.defaultPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  action.icon,
                  color: action.color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                action.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                action.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToMarketplace(BuildContext context) {
    // Navigate to marketplace
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigating to Marketplace...')),
    );
  }

  void _navigateToSell(BuildContext context) {
    // Navigate to sell page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigating to Sell Products...')),
    );
  }

  void _navigateToAnalytics(BuildContext context) {
    // Navigate to analytics
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigating to Analytics...')),
    );
  }

  void _navigateToEducation(BuildContext context) {
    // Navigate to education
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigating to Learning Center...')),
    );
  }

  void _navigateToExpertChat(BuildContext context) {
    // Navigate to expert chat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connecting to Expert Chat...')),
    );
  }

  void _navigateToCropDoctor(BuildContext context) {
    // Navigate to crop doctor
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening Crop Doctor...')),
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