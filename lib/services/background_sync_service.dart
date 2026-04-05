import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Offline database manager for background synchronization
class OfflineDatabase {
  static final OfflineDatabase _instance = OfflineDatabase._internal();
  factory OfflineDatabase() => _instance;
  OfflineDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    if (kIsWeb) {
      // sqflite is not supported on web
      throw Exception('Offline database is not supported on Web');
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docsDir.path, 'farmkart_offline.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE sync_queue (
            id TEXT PRIMARY KEY,
            collection TEXT NOT NULL,
            action TEXT NOT NULL,
            data TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            retryCount INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE products (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            cachedAt INTEGER NOT NULL
          )
        ''');
      },
    );
  }
}

/// Service to handle background data synchronization and offline support
class BackgroundSyncService {
  static final BackgroundSyncService _instance =
      BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();

  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  /// Initialize background sync
  Future<void> initialize() async {
    if (kIsWeb) return;

    _connectivitySubscription = _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        _startSync();
      }
    });

    // Initial sync check
    final results = await _connectivity.checkConnectivity();
    if (results.any((result) => result != ConnectivityResult.none)) {
      _startSync();
    }
  }

  /// Add operation to sync queue
  Future<void> queueOperation({
    required String collection,
    required String action,
    required Map<String, dynamic> data,
  }) async {
    if (kIsWeb) return;

    try {
      final offlineDb = await OfflineDatabase().database;
      final id = DateTime.now().microsecondsSinceEpoch.toString();

      await offlineDb.insert('sync_queue', {
        'id': id,
        'collection': collection,
        'action': action,
        'data': data.toString(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      debugPrint('BackgroundSync: Queued $action for $collection');

      // Try to sync immediately if online
      final results = await _connectivity.checkConnectivity();
      if (results.any((result) => result != ConnectivityResult.none)) {
        _startSync();
      }
    } catch (e) {
      debugPrint('BackgroundSync: Error queuing operation - $e');
    }
  }

  /// Sync data with Firestore
  Future<void> _startSync() async {
    if (kIsWeb || _isSyncing) return;
    _isSyncing = true;

    try {
      final offlineDb = await OfflineDatabase().database;
      final List<Map<String, dynamic>> queue = await offlineDb.query(
        'sync_queue',
        orderBy: 'timestamp ASC',
      );

      if (queue.isEmpty) {
        _isSyncing = false;
        return;
      }

      debugPrint('BackgroundSync: Starting sync of ${queue.length} items');

      for (final item in queue) {
        final String id = item['id'];
        // final String collection = item['collection'];
        final String action = item['action'];

        try {
          if (action == 'add') {
            // Implementation
          }

          await offlineDb
              .delete('sync_queue', where: 'id = ?', whereArgs: [id]);
        } catch (e) {
          debugPrint('BackgroundSync: Error syncing item $id - $e');
          await offlineDb.rawUpdate(
            'UPDATE sync_queue SET retryCount = retryCount + 1 WHERE id = ?',
            [id],
          );
        }
      }

      debugPrint('BackgroundSync: Sync completed');
    } catch (e) {
      debugPrint('BackgroundSync: Sync error - $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Clean up old cache
  Future<void> cleanupCache() async {
    if (kIsWeb) return;

    try {
      final offlineDb = await OfflineDatabase().database;

      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      await offlineDb.delete(
        'products',
        where: 'cachedAt < ?',
        whereArgs: [sevenDaysAgo.millisecondsSinceEpoch],
      );

      debugPrint('BackgroundSync: Cache cleanup completed');
    } catch (e) {
      debugPrint('BackgroundSync: Cleanup error - $e');
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
