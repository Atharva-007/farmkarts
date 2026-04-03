import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';

class AnalyticsSummary extends StatelessWidget {
  const AnalyticsSummary({super.key});

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
                    'Farm Analytics',
                    context: context,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveHelper.getFontSize(context, 18),
                    ),
                    maxLines: 1,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to detailed analytics
                  },
                  child: ResponsiveHelper.autoSizeText(
                    'View Details',
                    context: context,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getFontSize(context, 14),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.75),
            // Responsive layout - column on mobile, rows on larger screens
            if (ResponsiveHelper.isMobile(context)) ...[
              _buildMetricCard(
                context,
                'Total Revenue',
                '₹2,45,000',
                Icons.trending_up,
                AppTheme.success,
                '+12.5%',
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.5),
              _buildMetricCard(
                context,
                'Expenses',
                '₹1,85,000',
                Icons.trending_down,
                AppTheme.warning,
                '+5.2%',
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.5),
              _buildMetricCard(
                context,
                'Net Profit',
                '₹60,000',
                Icons.account_balance_wallet,
                AppTheme.primaryGreen,
                '+25.8%',
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.5),
              _buildMetricCard(
                context,
                'Yield/Acre',
                '24.5 qt',
                Icons.agriculture,
                AppTheme.accentOrange,
                '+8.3%',
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      'Total Revenue',
                      '₹2,45,000',
                      Icons.trending_up,
                      AppTheme.success,
                      '+12.5%',
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context) * 0.75),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      'Expenses',
                      '₹1,85,000',
                      Icons.trending_down,
                      AppTheme.warning,
                      '+5.2%',
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.75),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      'Net Profit',
                      '₹60,000',
                      Icons.account_balance_wallet,
                      AppTheme.primaryGreen,
                      '+25.8%',
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context) * 0.75),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      'Yield/Acre',
                      '24.5 qt',
                      Icons.agriculture,
                      AppTheme.accentOrange,
                      '+8.3%',
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),
            _buildRevenueChart(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String change,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon, 
                color: color, 
                size: ResponsiveHelper.isMobile(context) ? 18 : 20
              ),
              ResponsiveHelper.autoSizeText(
                change,
                context: context,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveHelper.getFontSize(context, 12),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.5),
          ResponsiveHelper.autoSizeText(
            value,
            context: context,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: ResponsiveHelper.getFontSize(context, ResponsiveHelper.isMobile(context) ? 16 : 18),
            ),
            maxLines: 1,
          ),
          ResponsiveHelper.autoSizeText(
            title,
            context: context,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textGrey,
              fontSize: ResponsiveHelper.getFontSize(context, 12),
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveHelper.autoSizeText(
          'Revenue Trend (Last 6 Months)',
          context: context,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveHelper.getFontSize(context, 16),
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 0.75),
        SizedBox(
          height: ResponsiveHelper.isMobile(context) ? 120 : 150,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: ResponsiveHelper.isMobile(context) ? 35 : 40,
                    getTitlesWidget: (value, meta) {
                      return ResponsiveHelper.autoSizeText(
                        '₹${(value / 1000).toInt()}K',
                        context: context,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: ResponsiveHelper.getFontSize(context, 10),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                      if (value.toInt() < months.length) {
                        return ResponsiveHelper.autoSizeText(
                          months[value.toInt()],
                          context: context,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: ResponsiveHelper.getFontSize(context, 10),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: const [
                    FlSpot(0, 180000),
                    FlSpot(1, 220000),
                    FlSpot(2, 200000),
                    FlSpot(3, 250000),
                    FlSpot(4, 240000),
                    FlSpot(5, 280000),
                  ],
                  isCurved: true,
                  color: AppTheme.primaryGreen,
                  barWidth: ResponsiveHelper.isMobile(context) ? 2 : 3,
                  isStrokeCapRound: true,
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  ),
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                      radius: ResponsiveHelper.isMobile(context) ? 3 : 4,
                      color: AppTheme.primaryGreen,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}