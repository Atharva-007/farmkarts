import 'package:flutter_test/flutter_test.dart';
import 'package:farmkarts_new/services/sync_service.dart';

void main() {
  group('SyncService Tests', () {
    late SyncService syncService;

    setUp(() {
      syncService = SyncService();
    });

    test('Should initialize successfully', () async {
      await syncService.initialize();
      expect(syncService, isNotNull);
    });

    test('Should check online status', () {
      final isOnline = syncService.isOnline;
      expect(isOnline, isA<bool>());
    });

    test('Should check syncing status', () {
      final isSyncing = syncService.isSyncing;
      expect(isSyncing, isA<bool>());
    });

    test('Should get sync stats', () async {
      final stats = await syncService.getSyncStats();
      
      expect(stats, isNotNull);
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('isOnline'), true);
      expect(stats.containsKey('isSyncing'), true);
    });

    test('Should handle offline products', () async {
      final products = await syncService.getProducts(
        category: 'Test',
        preferOffline: true,
      );
      
      expect(products, isA<List>());
    });

    test('Should handle search offline', () async {
      final results = await syncService.searchProducts('test');
      expect(results, isA<List>());
    });

    tearDown(() {
      syncService.dispose();
    });
  });
}
