import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';
import '../features/chat/enhanced_ai_expert_chat_page.dart';

class QuickActionGrid extends StatelessWidget {
  final Function(int)? onNavigate;

  const QuickActionGrid({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.psychology,
        title: 'AI Expert',
        subtitle: 'Get farming advice',
        color: const Color(0xFF6C5CE7), // Purple for AI
        onTap: () => _navigateToAIChat(context),
      ),
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
        color: AppTheme.deepGreen,
        onTap: () => onNavigate?.call(2),
      ),
      _QuickAction(
        icon: Icons.trending_up,
        title: 'APMC Market',
        subtitle: 'Live market rates',
        color: AppTheme.earthBrown,
        onTap: () => onNavigate?.call(4),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);
        final childAspectRatio = ResponsiveHelper.getCardAspectRatio(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: ResponsiveHelper.getResponsiveSpacing(context),
                mainAxisSpacing: ResponsiveHelper.getResponsiveSpacing(context),
                childAspectRatio: childAspectRatio,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return _buildActionCard(context, action);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionCard(BuildContext context, _QuickAction action) {
    return Card(
      elevation: ResponsiveHelper.isDesktop(context) ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(ResponsiveHelper.isDesktop(context) ? 16 : 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                action.color.withOpacity(0.1),
                action.color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveHelper.isDesktop(context) ? 16 : 12),
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: action.color, size: ResponsiveHelper.isDesktop(context) ? 28 : 24),
              ),
              const SizedBox(height: 12),
              Text(
                action.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: action.color,
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

  static void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  static void _navigateToAIChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EnhancedAIExpertChatPage(),
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