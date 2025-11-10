import 'package:flutter_test/flutter_test.dart';
import 'package:farmkarts_new/services/marketplace_service.dart';
import 'package:farmkarts_new/services/auth_service.dart';
import 'package:farmkarts_new/models/user_model.dart';

void main() {
  group('FarmKarts Performance Tests', () {
    test('MarketplaceService singleton initialization', () {
      final service1 = MarketplaceService();
      final service2 = MarketplaceService();
      
      // Should return the same instance (singleton pattern)
      expect(service1, equals(service2));
    });

    test('AuthService singleton initialization', () {
      final service1 = AuthService();
      final service2 = AuthService();
      
      // Should return the same instance (singleton pattern)
      expect(service1, equals(service2));
    });

    test('UserRole enum values', () {
      expect(UserRole.values.length, equals(2));
      expect(UserRole.values, contains(UserRole.farmer));
      expect(UserRole.values, contains(UserRole.addat));
    });

    test('User model serialization', () {
      final now = DateTime.now();
      final farmer = FarmerModel(
        uid: 'test-uid',
        email: 'test@example.com',
        fullName: 'Test Farmer',
        mobileNo: '1234567890',
        acresLand: 5.5,
        createdAt: now,
        updatedAt: now,
      );

      final map = farmer.toMap();
      expect(map['role'], equals('farmer'));
      expect(map['acresLand'], equals(5.5));
      expect(map['fullName'], equals('Test Farmer'));
      
      final reconstructedFarmer = FarmerModel.fromMap(map);
      expect(reconstructedFarmer.fullName, equals(farmer.fullName));
      expect(reconstructedFarmer.acresLand, equals(farmer.acresLand));
      expect(reconstructedFarmer.role, equals(UserRole.farmer));
    });

    test('Addat model serialization', () {
      final now = DateTime.now();
      final addat = AddatModel(
        uid: 'test-uid-addat',
        email: 'addat@example.com',
        fullName: 'Test Addat',
        mobileNo: '9876543210',
        dukanName: 'Test Shop',
        licenseImageUrl: 'https://example.com/license.jpg',
        createdAt: now,
        updatedAt: now,
      );

      final map = addat.toMap();
      expect(map['role'], equals('addat'));
      expect(map['dukanName'], equals('Test Shop'));
      expect(map['licenseImageUrl'], equals('https://example.com/license.jpg'));
      
      final reconstructedAddat = AddatModel.fromMap(map);
      expect(reconstructedAddat.fullName, equals(addat.fullName));
      expect(reconstructedAddat.dukanName, equals(addat.dukanName));
      expect(reconstructedAddat.role, equals(UserRole.addat));
      expect(reconstructedAddat.isLicenseVerified, equals(false)); // Default value
    });
  });

  group('Performance Optimizations', () {
    test('MarketplaceService has pagination state', () {
      final service = MarketplaceService();
      
      // Test that service has hasMoreData property
      expect(service.hasMoreData, isA<bool>());
    });

    test('Service can clear cache', () {
      final service = MarketplaceService();
      
      // Should not throw when clearing cache
      expect(() => service.clearCache(), returnsNormally);
    });
  });
}