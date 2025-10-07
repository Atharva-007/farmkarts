import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class WeatherDashboard extends StatelessWidget {
  const WeatherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud,
              size: 80,
              color: AppTheme.skyBlue,
            ),
            SizedBox(height: 16),
            Text(
              'Weather Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Advanced weather forecasting,\nalerts, and farming recommendations',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}