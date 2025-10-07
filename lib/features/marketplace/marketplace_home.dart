import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class MarketplaceHome extends StatelessWidget {
  const MarketplaceHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront,
              size: 80,
              color: AppTheme.primaryGreen,
            ),
            SizedBox(height: 16),
            Text(
              'Marketplace Feature',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Coming Soon - Advanced marketplace with\nbuying, selling, and bidding features',
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