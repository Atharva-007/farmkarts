import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PremiumFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final String? label;
  final IconData icon;
  final Color? backgroundColor;
  final double bottomPadding;

  const PremiumFAB({
    super.key,
    required this.onPressed,
    this.label,
    required this.icon,
    this.backgroundColor,
    this.bottomPadding = 80, // Default for floating nav bar clearance
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: label != null ? 20 : 16,
              vertical: label != null ? 14 : 16),
          decoration: BoxDecoration(
            color: backgroundColor ?? AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: (backgroundColor ?? AppTheme.primaryGreen)
                    .withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              if (label != null) ...[
                const SizedBox(width: 10),
                Text(
                  label!.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
