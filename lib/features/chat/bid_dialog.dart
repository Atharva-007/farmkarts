import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../theme/app_theme.dart';

/// Simple bid dialog - coming soon
class BidDialog extends StatelessWidget {
  final Product product;
  final Function(double amount, int quantity, String notes)? onBidSubmitted;

  const BidDialog({
    super.key,
    required this.product,
    this.onBidSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Make an Offer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.gavel, size: 64, color: AppTheme.primaryGreen),
          const SizedBox(height: 16),
          Text('Product: ${product.name}'),
          const SizedBox(height: 8),
          const Text('Bid feature coming soon!'),
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
