import 'dart:async';
import 'package:flutter/foundation.dart';
// import 'package:workmanager/workmanager.dart'; // Temporarily disabled due to Flutter embedding API incompatibility
import 'offline_database_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Background Sync Service
/// Handles periodic background synchronization of data using WorkManager
/// TEMPORARILY DISABLED: WorkManager has compatibility issues with current Flutter version
class BackgroundSyncService {
  static final BackgroundSyncService _instance = BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();

  // final Workmanager _workManager = Workmanager(); // Disabled
  bool _initialized = false;

  // Task names
  static const String syncTaskName = 'farmkarts_background_sync';
  static const String cacheSyncTaskName = 'farmkarts_cache_sync';

  // ==================== INITIALIZATION ====================

  Future<void> initialize() async {
    if (_initialized) return;
    
    // WorkManager temporarily disabled
    debugPrint('BackgroundSyncService: WorkManager temporarily disabled due to compatibility issues');
    _initialized = true;
    return;

    /* Disabled code
    try {
      await _workManager.initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

      // Register periodic sync task (every 15 minutes)
      await _workManager.registerPeriodicTask(
        syncTaskName,
        syncTaskName,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        existingWorkPolicy: ExistingWorkPolicy.keep,
      );

      // Register cache cleanup task (daily)
      await _workManager.registerPeriodicTask(
        cacheSyncTaskName,
        cacheSyncTaskName,
        frequency: const Duration(hours: 24),
        constraints: Constraints(
          requiresCharging: false,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      _initialized = true;
      debugPrint('BackgroundSync: Service initialized');
    } catch (e) {
      debugPrint('BackgroundSync: Initialization error - $e');
    }
  }

  // ==================== ONE-TIME SYNC ====================

  /// Trigger immediate background sync
  Future<void> triggerImmediateSync() async {
    debugPrint('BackgroundSync: Immediate sync temporarily disabled');
    /* Disabled code
    try {
      await _workManager.registerOneOffTask(
        'immediate_sync_${DateTime.now().millisecondsSinceEpoch}',
        syncTaskName,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
      debugPrint('BackgroundSync: Immediate sync triggered');
    } catch (e) {
      debugPrint('BackgroundSync: Error triggering immediate sync - $e');
    }
    */
  }

  // ==================== CANCEL TASKS ====================

  /// Cancel all background tasks
  Future<void> cancelAllTasks() async {
    debugPrint('BackgroundSync: Cancel all tasks temporarily disabled');
    /* Disabled code
    try {
      await _workManager.cancelAll();
      _initialized = false;
      debugPrint('BackgroundSync: All tasks cancelled');
    } catch (e) {
      debugPrint('BackgroundSync: Error cancelling tasks - $e');
    }
    */
  }

  /// Cancel specific task
  Future<void> cancelTask(String taskName) async {
    debugPrint('BackgroundSync: Cancel task temporarily disabled');
    /* Disabled code
    try {
      await _workManager.cancelByUniqueName(taskName);
      debugPrint('BackgroundSync: Task $taskName cancelled');
    } catch (e) {
      debugPrint('BackgroundSync: Error cancelling task - $e');
    }
    */
  }

  // ==================== UTILITIES ====================

  bool get isInitialized => _initialized;
}

// ==================== CALLBACK DISPATCHER ====================

/// Background task callback dispatcher (must be top-level function)
/// TEMPORARILY DISABLED
/*
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('BackgroundSync: Task started - $task');

    try {
      switch (task) {
        case BackgroundSyncService.syncTaskName:
          await _performBackgroundSync();
          break;

        case BackgroundSyncService.cacheSyncTaskName:
          await _performCacheCleanup();
          break;

        default:
          debugPrint('BackgroundSync: Unknown task - $task');
      }

      debugPrint('BackgroundSync: Task completed - $task');
      return Future.value(true);
    } catch (e) {
      debugPrint('BackgroundSync: Task failed - $task: $e');
      return Future.value(false);
    }
  });
}
*/

/// Perform background data sync
Future<void> _performBackgroundSync() async {
  debugPrint('BackgroundSync: Starting data sync...');

  try {
    // Check connectivity
    final dynamic connectivity = await Connectivity().checkConnectivity();
    bool isOffline = false;
    if (connectivity is List) {
      isOffline = connectivity.contains(ConnectivityResult.none);
    } else {
      isOffline = connectivity == ConnectivityResult.none;
    }

    if (isOffline) {
      debugPrint('BackgroundSync: No network connection');
      return;
    }

    final offlineDb = OfflineDatabaseService();

    // Sync pending operations
    final pendingOps = await offlineDb.getPendingOperations();
    debugPrint('BackgroundSync: Found ${pendingOps.length} pending operations');

    for (final op in pendingOps) {
      try {
        final type = op['type'] as String;
        final data = op['data'] as Map<String, dynamic>;

        switch (type) {
          case 'add_to_cart':
            await _syncCartOperation(data);
            break;
          case 'add_to_wishlist':
            await _syncWishlistOperation(data);
            break;
          case 'update_profile':
            await _syncProfileOperation(data);
            break;
          default:
            debugPrint('BackgroundSync: Unknown operation type - $type');
        }

        // Mark operation as completed
        await offlineDb.removeOperation(op['id'] as int);
      } catch (e) {
        debugPrint('BackgroundSync: Error syncing operation - $e');
      }
    }

    // Refresh cached products (get latest from Firestore)
    await _refreshProductCache();

    debugPrint('BackgroundSync: Data sync completed');
  } catch (e) {
    debugPrint('BackgroundSync: Sync error - $e');
  }
}

/// Sync cart operation to Firestore
Future<void> _syncCartOperation(Map<String, dynamic> data) async {
  final userId = data['userId'] as String?;
  final productId = data['productId'] as String?;
  final quantity = data['quantity'] as int?;

  if (userId == null || productId == null || quantity == null) return;

  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('cart')
      .doc(productId)
      .set({
    'productId': productId,
    'quantity': quantity,
    'addedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  debugPrint('BackgroundSync: Cart synced for product $productId');
}

/// Sync wishlist operation to Firestore
Future<void> _syncWishlistOperation(Map<String, dynamic> data) async {
  final userId = data['userId'] as String?;
  final productId = data['productId'] as String?;

  if (userId == null || productId == null) return;

  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('wishlist')
      .doc(productId)
      .set({
    'productId': productId,
    'addedAt': FieldValue.serverTimestamp(),
  });

  debugPrint('BackgroundSync: Wishlist synced for product $productId');
}

/// Sync profile operation to Firestore
Future<void> _syncProfileOperation(Map<String, dynamic> data) async {
  final userId = data['userId'] as String?;

  if (userId == null) return;

  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .update(data);

  debugPrint('BackgroundSync: Profile synced for user $userId');
}

/// Refresh product cache from Firestore
Future<void> _refreshProductCache() async {
  try {
    final products = await FirebaseFirestore.instance
        .collection('products')
        .where('status', isEqualTo: 'approved')
        .limit(100)
        .get();

    final offlineDb = OfflineDatabaseService();
    
    for (final doc in products.docs) {
      await offlineDb.saveProduct({
        'id': doc.id,
        ...doc.data(),
      });
    }

    debugPrint('BackgroundSync: Cached ${products.docs.length} products');
  } catch (e) {
    debugPrint('BackgroundSync: Error refreshing cache - $e');
  }
}

/// Perform cache cleanup
Future<void> _performCacheCleanup() async {
  debugPrint('BackgroundSync: Starting cache cleanup...');

  try {
    final offlineDb = OfflineDatabaseService();

    // Remove old search history (older than 30 days)
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    await offlineDb.database.delete(
      'search_history',
      where: 'timestamp < ?',
      whereArgs: [thirtyDaysAgo.millisecondsSinceEpoch],
    );

    // Remove old cached products (older than 7 days)
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    await offlineDb.database.delete(
      'products',
      where: 'cachedAt < ?',
      whereArgs: [sevenDaysAgo.millisecondsSinceEpoch],
    );

    debugPrint('BackgroundSync: Cache cleanup completed');
  } catch (e) {
    debugPrint('BackgroundSync: Cleanup error - $e');
  }
}
