import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';

class CropStatusCard extends StatelessWidget {
  const CropStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: ResponsiveHelper.getResponsiveBorderRadius(context),
      ),
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ResponsiveHelper.autoSizeText(
                    'Active Crops',
                    context: context,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveHelper.getFontSize(context, 18),
                    ),
                    maxLines: 1,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getResponsiveSpacing(context) * 0.5,
                    vertical: ResponsiveHelper.getResponsiveSpacing(context) * 0.25,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: ResponsiveHelper.getResponsiveBorderRadius(context).copyWith(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: const Radius.circular(12),
                      bottomRight: const Radius.circular(12),
                    ),
                  ),
                  child: ResponsiveHelper.autoSizeText(
                    '3 Active',
                    context: context,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.success,
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveHelper.getFontSize(context, 12),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.75),
            _buildCropItem(
              context,
              'Wheat (Field A)',
              'Day 45 - Flowering stage',
              Icons.grass,
              AppTheme.lightGreen,
              85,
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.5),
            _buildCropItem(
              context,
              'Corn (Field B)',
              'Day 30 - Vegetative growth',
              Icons.agriculture,
              AppTheme.sunshine,
              65,
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.5),
            _buildCropItem(
              context,
              'Tomatoes (Greenhouse)',
              'Day 60 - Fruit development',
              Icons.local_florist,
              AppTheme.error,
              92,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropItem(
    BuildContext context,
    String name,
    String stage,
    IconData icon,
    Color color,
    int healthPercentage,
  ) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context).copyWith(
        top: 12,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: ResponsiveHelper.getResponsiveBorderRadius(context).copyWith(
          topLeft: const Radius.circular(8),
          topRight: const Radius.circular(8),
          bottomLeft: const Radius.circular(8),
          bottomRight: const Radius.circular(8),
        ),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context) * 0.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: ResponsiveHelper.isMobile(context) ? 18 : 20,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context) * 0.75),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveHelper.autoSizeText(
                  name,
                  context: context,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveHelper.getFontSize(context, 16),
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                ResponsiveHelper.autoSizeText(
                  stage,
                  context: context,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textGrey,
                    fontSize: ResponsiveHelper.getFontSize(context, 12),
                  ),
                  maxLines: ResponsiveHelper.isMobile(context) ? 2 : 1,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ResponsiveHelper.autoSizeText(
                      'Health: ',
                      context: context,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: ResponsiveHelper.getFontSize(context, 12),
                      ),
                    ),
                    ResponsiveHelper.autoSizeText(
                      '$healthPercentage%',
                      context: context,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getHealthColor(healthPercentage),
                        fontSize: ResponsiveHelper.getFontSize(context, 12),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context) * 0.5),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: healthPercentage / 100,
                        backgroundColor: AppTheme.borderGrey,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getHealthColor(healthPercentage),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getHealthColor(int percentage) {
    if (percentage >= 80) return AppTheme.success;
    if (percentage >= 60) return AppTheme.warning;
    return AppTheme.error;
  }
}