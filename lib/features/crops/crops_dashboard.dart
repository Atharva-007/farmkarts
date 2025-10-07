import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CropsDashboard extends StatelessWidget {
  const CropsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crops'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.agriculture,
              size: 80,
              color: AppTheme.lightGreen,
            ),
            SizedBox(height: 16),
            Text(
              'Crop Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Track crops, disease detection,\nyield prediction, and harvest planning',
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