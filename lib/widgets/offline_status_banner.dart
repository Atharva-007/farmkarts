import 'package:flutter/material.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';

/// Widget to display offline/sync status
class OfflineStatusBanner extends StatefulWidget {
  const OfflineStatusBanner({super.key});

  @override
  State<OfflineStatusBanner> createState() => _OfflineStatusBannerState();
}

class _OfflineStatusBannerState extends State<OfflineStatusBanner> {
  final SyncService _syncService = SyncService();
  bool _isOnline = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _initSync();
  }

  Future<void> _initSync() async {
    await _syncService.initialize();
    
    _syncService.syncStatus.listen((status) {
      if (mounted) {
        setState(() {
          _isOnline = status.isOnline;
          _isSyncing = status.isSyncing;
        });
      }
    });
    
    setState(() {
      _isOnline = _syncService.isOnline;
      _isSyncing = _syncService.isSyncing;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline && !_isSyncing) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _isSyncing 
          ? Colors.blue.shade100 
          : Colors.orange.shade100,
      child: Row(
        children: [
          Icon(
            _isSyncing 
                ? Icons.sync 
                : Icons.cloud_off,
            size: 16,
            color: _isSyncing 
                ? Colors.blue.shade800 
                : Colors.orange.shade800,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isSyncing 
                  ? 'Syncing data...' 
                  : 'Offline mode - Changes will sync when online',
              style: TextStyle(
                fontSize: 12,
                color: _isSyncing 
                    ? Colors.blue.shade800 
                    : Colors.orange.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (!_isOnline)
            TextButton(
              onPressed: () => _showOfflineDialog(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
              ),
              child: Text(
                'Info',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showOfflineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.orange),
            SizedBox(width: 12),
            Text('Offline Mode'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You are currently offline. Here\'s what you can do:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              icon: Icons.search,
              text: 'Browse cached products',
              available: true,
            ),
            _buildFeatureItem(
              icon: Icons.shopping_cart,
              text: 'Add items to cart',
              available: true,
            ),
            _buildFeatureItem(
              icon: Icons.favorite,
              text: 'Manage wishlist',
              available: true,
            ),
            _buildFeatureItem(
              icon: Icons.cloud_upload,
              text: 'Changes sync automatically when online',
              available: true,
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            _buildFeatureItem(
              icon: Icons.block,
              text: 'Add new products',
              available: false,
            ),
            _buildFeatureItem(
              icon: Icons.payment,
              text: 'Process payments',
              available: false,
            ),
            _buildFeatureItem(
              icon: Icons.chat,
              text: 'Send messages',
              available: false,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String text,
    required bool available,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: available ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: available ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating sync button
class SyncFloatingButton extends StatefulWidget {
  const SyncFloatingButton({super.key});

  @override
  State<SyncFloatingButton> createState() => _SyncFloatingButtonState();
}

class _SyncFloatingButtonState extends State<SyncFloatingButton> {
  final SyncService _syncService = SyncService();
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _syncService.syncStatus.listen((status) {
      if (mounted) {
        setState(() {
          _isSyncing = status.isSyncing;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: _isSyncing ? null : _handleSync,
      icon: _isSyncing 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.sync),
      label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
      backgroundColor: _isSyncing ? Colors.grey : AppTheme.primaryGreen,
    );
  }

  Future<void> _handleSync() async {
    try {
      await _syncService.forceSyncNow();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
