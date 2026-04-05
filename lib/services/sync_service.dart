import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'offline_database_service.dart';
import 'marketplace_service.dart';
import '../models/product_model.dart';

/// Sync service to handle offline/online data synchronization
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final OfflineDatabaseService _offlineDb = OfflineDatabaseService();
  final MarketplaceService _marketplaceService = MarketplaceService();
  final Connectivity _connectivity = Connectivity();

  bool _isOnline = true;
  bool _isSyncing = false;
  StreamSubscription? _connectivitySubscription;

  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;

  /// Initialize sync service
  Future<void> initialize() async {
    debugPrint('SyncService: Initializing...');

    // Check initial connectivity
    final dynamic connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult is List) {
      _isOnline = !connectivityResult.contains(ConnectivityResult.none);
    } else {
      _isOnline = connectivityResult != ConnectivityResult.none;
    }

    debugPrint(
        'SyncService: Initial status - ${_isOnline ? "Online" : "Offline"}');

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (dynamic result) {
        _handleConnectivityChange(result);
      },
    );
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(dynamic result) {
    final wasOnline = _isOnline;

    if (result is List) {
      _isOnline = !result.contains(ConnectivityResult.none);
    } else {
      _isOnline = result != ConnectivityResult.none;
    }

    debugPrint(
        'SyncService: Connectivity changed - ${_isOnline ? "Online" : "Offline"}');

    _syncStatusController.add(SyncStatus(
      isOnline: _isOnline,
      isSyncing: _isSyncing,
    ));

    // If we just came online, start syncing
    if (!wasOnline && _isOnline) {
      debugPrint('SyncService: Connection restored, starting sync...');
      syncPendingOperations();
    }
  }

  /// Check if device is online
  bool get isOnline => _isOnline;

  /// Check if currently syncing
  bool get isSyncing => _isSyncing;

  /// Sync products from server to local database
  Future<void> syncProductsFromServer({
    String? category,
    bool forceRefresh = false,
  }) async {
    if (!_isOnline) {
      debugPrint('SyncService: Offline - cannot sync from server');
      return;
    }

    try {
      _isSyncing = true;
      _notifySyncStatus();

      debugPrint('SyncService: Syncing products from server...');

      // Fetch products from server
      final products = await _marketplaceService.getProducts(
        category: category,
        forceRefresh: forceRefresh,
      );

      // Save to offline database
      await _offlineDb.saveProducts(products);

      debugPrint('SyncService: Synced ${products.length} products');
    } catch (e) {
      debugPrint('SyncService: Error syncing products: $e');
    } finally {
      _isSyncing = false;
      _notifySyncStatus();
    }
  }

  /// Sync pending operations to server
  Future<void> syncPendingOperations() async {
    if (!_isOnline || _isSyncing) {
      debugPrint(
          'SyncService: Cannot sync - ${!_isOnline ? "offline" : "already syncing"}');
      return;
    }

    try {
      _isSyncing = true;
      _notifySyncStatus();

      final pendingOps = await _offlineDb.getPendingOperations();

      if (pendingOps.isEmpty) {
        debugPrint('SyncService: No pending operations to sync');
        return;
      }

      debugPrint(
          'SyncService: Syncing ${pendingOps.length} pending operations...');

      int successCount = 0;
      int failCount = 0;

      for (final op in pendingOps) {
        try {
          await _processPendingOperation(op);
          await _offlineDb.removePendingOperation(op['id']);
          successCount++;
        } catch (e) {
          debugPrint(
              'SyncService: Failed to process operation ${op['id']}: $e');
          failCount++;

          // Implement exponential backoff for retries
          final retryCount = op['retryCount'] as int;
          if (retryCount >= 3) {
            debugPrint(
                'SyncService: Max retries reached for operation ${op['id']}');
            await _offlineDb.removePendingOperation(op['id']);
          }
        }
      }

      debugPrint(
          'SyncService: Sync complete - Success: $successCount, Failed: $failCount');
    } catch (e) {
      debugPrint('SyncService: Error syncing pending operations: $e');
    } finally {
      _isSyncing = false;
      _notifySyncStatus();
    }
  }

  /// Process a single pending operation
  Future<void> _processPendingOperation(Map<String, dynamic> op) async {
    final operationType = op['operationType'] as String;
    final tableName = op['tableName'] as String;
    final recordId = op['recordId'] as String;
    final Map<String, dynamic> data = op['data'] as Map<String, dynamic>;

    debugPrint(
        'SyncService: Processing $operationType on $tableName/$recordId');

    try {
      switch (operationType) {
        case 'CREATE':
          if (tableName == 'products') {
            final product = Product.fromMap(recordId, data);
            await _marketplaceService.addProduct(product, product.sellerId);
          }
          break;
        case 'UPDATE':
          if (tableName == 'products') {
            await _marketplaceService.updateProduct(recordId, data);
          }
          break;
        case 'DELETE':
          if (tableName == 'products') {
            await _marketplaceService.deleteProduct(recordId);
          }
          break;
        default:
          debugPrint('SyncService: Unknown operation type: $operationType');
      }
    } catch (e) {
      debugPrint('SyncService: Error processing operation: $e');
      rethrow;
    }
  }

  /// Get products (from local DB if offline, from server if online)
  Future<List<Product>> getProducts({
    String? category,
    bool preferOffline = false,
  }) async {
    if (!_isOnline || preferOffline) {
      debugPrint('SyncService: Fetching products from offline DB');
      return await _offlineDb.getProducts(category: category);
    }

    try {
      debugPrint('SyncService: Fetching products from server');
      final products =
          await _marketplaceService.getProducts(category: category);

      // Save to offline DB for future offline access
      await _offlineDb.saveProducts(products);

      return products;
    } catch (e) {
      debugPrint(
          'SyncService: Error fetching from server, falling back to offline DB: $e');
      return await _offlineDb.getProducts(category: category);
    }
  }

  /// Search products (offline first, then online)
  Future<List<Product>> searchProducts(String query) async {
    if (!_isOnline) {
      debugPrint('SyncService: Searching offline database');
      return await _offlineDb.searchProducts(query);
    }

    try {
      // Try online search first
      final products = await _marketplaceService.searchProducts(query);

      // Save results to offline DB
      await _offlineDb.saveProducts(products);

      return products;
    } catch (e) {
      debugPrint('SyncService: Online search failed, using offline: $e');
      return await _offlineDb.searchProducts(query);
    }
  }

  /// Add product with offline support
  Future<void> addProduct(Product product, String sellerId) async {
    if (_isOnline) {
      try {
        // Add to server
        final productId =
            await _marketplaceService.addProduct(product, sellerId);

        // Update local product with server ID
        final updatedProduct = Product(
          id: productId,
          name: product.name,
          description: product.description,
          category: product.category,
          price: product.price,
          unit: product.unit,
          imageUrls: product.imageUrls,
          sellerId: product.sellerId,
          sellerName: product.sellerName,
          location: product.location,
          timestamp: product.timestamp,
          createdAt: product.createdAt,
          isOrganic: product.isOrganic,
          isAvailable: product.isAvailable,
          quantity: product.quantity,
          tags: product.tags,
          rating: product.rating,
          reviewCount: product.reviewCount,
        );

        // Save to offline DB
        await _offlineDb.saveProduct(updatedProduct);

        return;
      } catch (e) {
        debugPrint(
            'SyncService: Failed to add product online, queuing for sync: $e');
      }
    }

    // If offline or online failed, save to offline DB and add to pending operations
    await _offlineDb.saveProduct(product);
    await _offlineDb.addPendingOperation(
      operationType: 'CREATE',
      tableName: 'products',
      recordId: product.id,
      data: product.toMap(),
    );

    debugPrint('SyncService: Product queued for sync when online');
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getSyncStats() async {
    final dbStats = await _offlineDb.getDatabaseStats();
    final pendingOps = await _offlineDb.getPendingOperations();

    return {
      'isOnline': _isOnline,
      'isSyncing': _isSyncing,
      'offlineProducts': dbStats['products'],
      'pendingOperations': pendingOps.length,
      'cartItems': dbStats['cartItems'],
    };
  }

  /// Force sync now
  Future<void> forceSyncNow() async {
    if (!_isOnline) {
      throw Exception('Cannot sync while offline');
    }

    await syncPendingOperations();
    await syncProductsFromServer(forceRefresh: true);
  }

  /// Clear offline cache
  Future<void> clearOfflineCache() async {
    await _offlineDb.clearAllData();
    debugPrint('SyncService: Offline cache cleared');
  }

  /// Notify sync status change
  void _notifySyncStatus() {
    _syncStatusController.add(SyncStatus(
      isOnline: _isOnline,
      isSyncing: _isSyncing,
    ));
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
  }
}

/// Sync status model
class SyncStatus {
  final bool isOnline;
  final bool isSyncing;

  SyncStatus({
    required this.isOnline,
    required this.isSyncing,
  });

  @override
  String toString() => 'SyncStatus(isOnline: $isOnline, isSyncing: $isSyncing)';
}
