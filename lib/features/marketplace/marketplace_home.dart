import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/user_state_service.dart';
import 'complete_marketplace_page.dart';

class MarketplaceHome extends StatelessWidget {
  const MarketplaceHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserStateService>(
      builder: (context, userStateService, child) {
        // Use the complete marketplace implementation
        return const CompleteMarketplacePage();
      },
    );
  }
}