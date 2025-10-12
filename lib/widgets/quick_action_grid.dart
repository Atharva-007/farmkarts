import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';

class QuickActionGrid extends StatelessWidget {
  final Function(int)? onNavigate;
  
  const QuickActionGrid({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.storefront,
        title: 'Marketplace',
        subtitle: 'Buy & sell products',
        color: AppTheme.primaryGreen,
        onTap: () => onNavigate?.call(1),
      ),
      _QuickAction(
        icon: Icons.agriculture,
        title: 'Crops',
        subtitle: 'Manage your crops',
        color: AppTheme.lightGreen,
        onTap: () => onNavigate?.call(3),
      ),
      _QuickAction(
        icon: Icons.people,
        title: 'Community',
        subtitle: 'Connect with farmers',
        color: AppTheme.skyBlue,
        onTap: () => onNavigate?.call(2),
      ),
      _QuickAction(
        icon: Icons.wb_sunny,
        title: 'Weather',
        subtitle: 'Weather forecast',
        color: AppTheme.sunshine,
        onTap: () => onNavigate?.call(4),
      ),
      _QuickAction(
        icon: Icons.analytics,
        title: 'Analytics',
        subtitle: 'Farm insights',
        color: AppTheme.accentOrange,
        onTap: () => _showComingSoon(context, 'Analytics'),
      ),
      _QuickAction(
        icon: Icons.inventory,
        title: 'Inventory',
        subtitle: 'Track stock',
        color: AppTheme.freshMint,
        onTap: () => _showComingSoon(context, 'Inventory'),
      ),
      _QuickAction(
        icon: Icons.schedule,
        title: 'Calendar',
        subtitle: 'Crop calendar',
        color: AppTheme.earthBrown,
        onTap: () => _showComingSoon(context, 'Crop Calendar'),
      ),
      _QuickAction(
        icon: Icons.help_outline,
        title: 'Support',
        subtitle: 'Get help',
        color: AppTheme.info,
        onTap: () => _showComingSoon(context, 'Support'),
      ),
    ];

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on,
                color: AppTheme.accentOrange,
                size: ResponsiveHelper.isDesktop(context) ? 28 : 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveHelper.getGridColumns(context, maxColumns: 4),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              return _buildActionCard(context, actions[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, _QuickAction action) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                action.color.withValues(alpha: 0.1),
                action.color.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: action.color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: action.color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  action.icon,
                  color: Colors.white,
                  size: ResponsiveHelper.isDesktop(context) ? 24 : 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                action.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                action.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textGrey,
                  fontSize: ResponsiveHelper.isDesktop(context) ? 11 : 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
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