import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/product_model.dart';

class WeatherForecastCard extends StatelessWidget {
  final DailyForecast forecast;

  const WeatherForecastCard({
    super.key,
    required this.forecast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: AppTheme.defaultShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatDate(forecast.date),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          _getWeatherIcon(forecast.condition),
          Column(
            children: [
              Text(
                '${forecast.maxTemp.round()}°',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${forecast.minTemp.round()}°',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textGrey,
                ),
              ),
            ],
          ),
          if (forecast.rainfall > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.water_drop,
                  size: 12,
                  color: AppTheme.skyBlue,
                ),
                const SizedBox(width: 2),
                Text(
                  '${forecast.rainfall.round()}mm',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.skyBlue,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    
    if (date.day == now.day) {
      return 'Today';
    } else if (date.day == tomorrow.day) {
      return 'Tomorrow';
    } else {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    }
  }

  Widget _getWeatherIcon(String condition) {
    IconData iconData;
    Color color;

    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        iconData = Icons.wb_sunny;
        color = AppTheme.sunshine;
        break;
      case 'partly cloudy':
        iconData = Icons.wb_cloudy;
        color = AppTheme.skyBlue;
        break;
      case 'light rain':
      case 'rain':
        iconData = Icons.grain;
        color = AppTheme.skyBlue;
        break;
      default:
        iconData = Icons.wb_sunny;
        color = AppTheme.sunshine;
    }

    return Icon(iconData, size: 32, color: color);
  }
}

class WeatherAlertsCard extends StatelessWidget {
  const WeatherAlertsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: AppTheme.warning),
                const SizedBox(width: 8),
                Text(
                  'Weather Alerts',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAlert(
              'High Wind Warning',
              'Strong winds expected tomorrow (25+ km/h). Secure equipment and crops.',
              AppTheme.warning,
              Icons.air,
            ),
            const SizedBox(height: 8),
            _buildAlert(
              'Frost Advisory',
              'Temperature may drop below 5°C on Friday. Protect sensitive crops.',
              AppTheme.info,
              Icons.ac_unit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlert(String title, String description, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FarmingAdviceCard extends StatelessWidget {
  const FarmingAdviceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.agriculture, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  'Farming Advice',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAdvice(
              'Irrigation Recommendation',
              'Current humidity is 65%. Consider reducing irrigation for the next 2 days.',
              Icons.water_drop,
              AppTheme.skyBlue,
            ),
            const SizedBox(height: 8),
            _buildAdvice(
              'Pest Management',
              'Weather conditions are favorable for aphids. Monitor crops closely.',
              Icons.bug_report,
              AppTheme.warning,
            ),
            const SizedBox(height: 8),
            _buildAdvice(
              'Harvesting Window',
              'Ideal weather for harvesting wheat. Consider starting tomorrow.',
              Icons.agriculture,
              AppTheme.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvice(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}