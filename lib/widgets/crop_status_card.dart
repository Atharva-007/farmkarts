import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CropStatusCard extends StatelessWidget {
  const CropStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Crops',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '3 Active',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCropItem(
              context,
              'Wheat (Field A)',
              'Day 45 - Flowering stage',
              Icons.grass,
              AppTheme.lightGreen,
              85,
            ),
            const SizedBox(height: 12),
            _buildCropItem(
              context,
              'Corn (Field B)',
              'Day 30 - Vegetative growth',
              Icons.agriculture,
              AppTheme.sunshine,
              65,
            ),
            const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Health: ',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '$healthPercentage%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getHealthColor(healthPercentage),
                      ),
                    ),
                    const SizedBox(width: 8),
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