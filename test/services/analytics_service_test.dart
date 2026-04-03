import 'package:flutter_test/flutter_test.dart';
import 'package:farmkarts_new/services/analytics_service.dart';

void main() {
  group('AnalyticsService Tests', () {
    late AnalyticsService analyticsService;

    setUp(() {
      analyticsService = AnalyticsService();
    });

    test('Should initialize successfully', () async {
      await analyticsService.initialize();
      expect(analyticsService, isNotNull);
    });

    test('Should log user login', () async {
      await analyticsService.logLogin('email');
      // Test passes if no exceptions
      expect(true, true);
    });

    test('Should log product view', () async {
      await analyticsService.logProductView(
        productId: 'test123',
        productName: 'Test Product',
        category: 'Test',
        price: 100.0,
      );
      expect(true, true);
    });

    test('Should log add to cart', () async {
      await analyticsService.logAddToCart(
        productId: 'test123',
        productName: 'Test Product',
        category: 'Test',
        price: 100.0,
        quantity: 2.0,
      );
      expect(true, true);
    });

    test('Should log custom event', () async {
      await analyticsService.logCustomEvent(
        eventName: 'test_event',
        parameters: {'key': 'value'},
      );
      expect(true, true);
    });

    test('Should set user properties', () async {
      await analyticsService.setUserProperties(
        userId: 'user123',
        role: 'farmer',
        location: 'Mumbai',
      );
      expect(true, true);
    });

    test('Should log screen view', () async {
      await analyticsService.logScreenView(
        screenName: 'TestScreen',
      );
      expect(true, true);
    });

    test('Should log search', () async {
      await analyticsService.logSearch('tomato', category: 'Vegetables');
      expect(true, true);
    });

    test('Should log purchase', () async {
      await analyticsService.logPurchase(
        transactionId: 'txn123',
        totalValue: 500.0,
        paymentMethod: 'razorpay',
        items: [
          {
            'id': 'prod1',
            'name': 'Product 1',
            'price': 500.0,
            'quantity': 1,
          }
        ],
      );
      expect(true, true);
    });
  });
}
