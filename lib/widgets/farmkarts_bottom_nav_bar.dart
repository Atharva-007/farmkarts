import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FarmKartsBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FarmKartsBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 65, // Reduced height
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12), // Reduced bottom margin
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(24), // Slightly smaller radius
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
        border: Border.all(
          color: AppTheme.getBorderColor(context)
              .withValues(alpha: isDark ? 0.1 : 0.4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
              context, 0, Icons.dashboard_outlined, Icons.dashboard, 'Home'),
          _buildNavItem(context, 1, Icons.storefront_outlined, Icons.storefront,
              'Market'),
          _buildNavItem(context, 2, Icons.auto_awesome_outlined,
              Icons.auto_awesome, 'AI'),
          _buildNavItem(
              context, 3, Icons.business_outlined, Icons.business, 'APMC'),
          _buildNavItem(
              context, 4, Icons.person_outline, Icons.person, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon,
      IconData activeIcon, String label) {
    final isSelected = currentIndex == index;
    final color = isSelected
        ? AppTheme.getPrimaryAccent(context)
        : AppTheme.getSecondaryTextColor(context);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 6), // Reduced padding
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.getPrimaryAccent(context).withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isSelected ? activeIcon : icon,
              color: color,
              size: 22, // Slightly smaller icon
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9, // Smaller font
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
