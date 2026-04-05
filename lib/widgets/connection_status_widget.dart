import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_state_service.dart';
import '../theme/app_theme.dart';

class ConnectionStatusWidget extends StatelessWidget {
  final Widget child;

  const ConnectionStatusWidget({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UserStateService>(
      builder: (context, userState, _) {
        return Stack(
          children: [
            child,

            // Show connection status banner when offline or error
            if (!userState.isOnline || userState.error != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          !userState.isOnline ? Colors.orange : AppTheme.error,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          !userState.isOnline
                              ? Icons.wifi_off
                              : Icons.error_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            !userState.isOnline
                                ? 'No internet connection'
                                : userState.error ?? 'Connection error',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (userState.error != null)
                          TextButton(
                            onPressed: () {
                              userState.clearError();
                              userState.retryLoadUser();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                            ),
                            child: const Text('Retry'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
