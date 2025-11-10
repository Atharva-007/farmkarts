import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/user_state_service.dart';
import 'optimized_marketplace_home.dart';

class CleanMarketplaceHome extends StatelessWidget {
  const CleanMarketplaceHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserStateService>(
      builder: (context, userStateService, child) {
        // Use the optimized version
        return const OptimizedMarketplaceHome();
      },
    );
  }
}