import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Dialog showing buyer profile - simplified version
class BuyerProfileDialog extends StatelessWidget {
  final String buyerId;
  final Function(double rating, String review)? onRateUser;

  const BuyerProfileDialog({
    super.key,
    required this.buyerId,
    this.onRateUser,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('User Profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person, size: 64, color: AppTheme.primaryGreen),
          const SizedBox(height: 16),
          Text('User ID: $buyerId'),
          const SizedBox(height: 8),
          const Text('Profile feature coming soon!'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
