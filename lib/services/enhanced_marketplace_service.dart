// Enhanced Marketplace Service for FarmKart  
// Updated to use Firebase directly through MarketplaceService
// This service now delegates to the main MarketplaceService to avoid API calls

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/marketplace_models.dart';
import 'marketplace_service.dart';

class EnhancedMarketplaceService {
  static final EnhancedMarketplaceService _instance = EnhancedMarketplaceService._internal();
  factory EnhancedMarketplaceService() => _instance;
  EnhancedMarketplaceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MarketplaceService _marketplaceService = MarketplaceService();

  // Get current authenticated user
  User? _getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  // Selling History Management using Firebase
  Future<List<SellingHistoryItem>> getSellingHistory(String userId) async {
    try {
      print('EnhancedMarketplaceService: Fetching selling history for user: $userId');
      
      final user = _getCurrentUser();
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Use the main marketplace service to get selling history data
      final sellingHistoryList = await _marketplaceService.getSellingHistoryByUser(userId);

      return sellingHistoryList.map((data) {
        // Convert to SellingHistoryItem format
        return SellingHistoryItem(
          id: data['id'] ?? '',
          productId: data['productId'] ?? '',
          productName: data['productName'] ?? '',
          sellerId: data['sellerId'] ?? '',
          sellerName: data['sellerName'] ?? '',
          category: data['category'] ?? '',
          initialPrice: (data['initialPrice'] ?? 0).toDouble(),
          currentPrice: (data['currentPrice'] ?? 0).toDouble(),
          totalQuantity: data['totalQuantity'] ?? 0,
          soldQuantity: data['soldQuantity'] ?? 0,
          availableQuantity: data['availableQuantity'] ?? 0,
          totalRevenue: (data['totalRevenue'] ?? 0).toDouble(),
          totalViews: data['totalViews'] ?? 0,
          totalInquiries: data['totalInquiries'] ?? 0,
          status: data['status'] ?? 'active',
          isActive: data['isActive'] ?? true,
          listedDate: data['listedDate'] is Timestamp 
            ? (data['listedDate'] as Timestamp).toDate()
            : DateTime.now(),
          lastSoldDate: data['lastSoldDate'] != null && data['lastSoldDate'] is Timestamp
            ? (data['lastSoldDate'] as Timestamp).toDate()
            : null,
        );
      }).toList();
      
    } catch (e) {
      print('EnhancedMarketplaceService: Error fetching selling history: $e');
      return []; // Return empty list instead of throwing to prevent crashes
    }
  }

  // User Statistics using Firebase
  Future<UserStatistics> getUserStatistics(String userId) async {
    try {
      print('EnhancedMarketplaceService: Fetching user statistics for: $userId');
      
      final user = _getCurrentUser();
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get selling history to calculate stats
      final sellingHistory = await getSellingHistory(userId);
      
      // Get user's products using the marketplace service
      final products = await _marketplaceService.getProductsBySeller(userId);

      // Calculate statistics
      double totalRevenue = 0;
      int totalSold = 0;
      int activeProducts = 0;
      int totalViews = 0;
      int totalInquiries = 0;

      for (final item in sellingHistory) {
        totalRevenue += item.totalRevenue;
        totalSold += item.soldQuantity;
        if (item.isActive) activeProducts++;
        totalViews += item.totalViews;
        totalInquiries += item.totalInquiries;
      }

      final stats = UserStatistics(
        userId: userId,
        totalProducts: products.length,
        activeProducts: activeProducts,
        totalSold: totalSold,
        totalSales: totalSold,
        totalRevenue: totalRevenue,
        totalViews: totalViews,
        totalInquiries: totalInquiries,
        averageRating: 4.5, // Default rating - can be calculated from reviews
        totalReviews: 0, // Can be calculated from reviews collection
        joinDate: DateTime.now(), // Can be fetched from user profile
        lastActive: DateTime.now(),
      );

      print('EnhancedMarketplaceService: User statistics calculated successfully');
      return stats;
      
    } catch (e) {
      print('EnhancedMarketplaceService: Error fetching user statistics: $e');
      // Return default stats to prevent crashes
      return UserStatistics(
        userId: userId,
        totalProducts: 0,
        activeProducts: 0,
        totalSold: 0,
        totalSales: 0,
        totalRevenue: 0,
        totalViews: 0,
        totalInquiries: 0,
        averageRating: 0,
        totalReviews: 0,
        joinDate: DateTime.now(),
        lastActive: DateTime.now(),
      );
    }
  }

  // Buyer Interest Management using Firebase
  Future<String> showInterestInProduct({
    required String productId,
    required String message,
    required int interestedQuantity,
    String contactPreference = 'email',
  }) async {
    try {
      print('EnhancedMarketplaceService: Registering interest in product: $productId');
      
      final user = _getCurrentUser();
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final interestData = {
        'productId': productId,
        'buyerId': user.uid,
        'buyerName': user.displayName ?? user.email ?? 'Unknown Buyer',
        'message': message,
        'interestedQuantity': interestedQuantity,
        'contactPreference': contactPreference,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('buyer_interests').add(interestData);
      
      print('EnhancedMarketplaceService: Interest registered successfully with ID: ${docRef.id}');
      return docRef.id;
      
    } catch (e) {
      print('EnhancedMarketplaceService: Error registering interest: $e');
      throw Exception('Failed to register interest: $e');
    }
  }

  // Get product interests using Firebase
  Future<List<BuyerInterest>> getProductInterests(String productId) async {
    try {
      print('EnhancedMarketplaceService: Fetching interests for product: $productId');
      
      final query = _firestore
          .collection('buyer_interests')
          .where('productId', isEqualTo: productId);

      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return BuyerInterest.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();
      
    } catch (e) {
      print('EnhancedMarketplaceService: Error fetching product interests: $e');
      return []; // Return empty list to prevent crashes
    }
  }

  // Simplified stub methods for other functionality
  Future<void> submitPriceOffer({
    required String productId,
    required double offerPrice,
    required int quantity,
    String? message,
  }) async {
    // Placeholder implementation - store in Firebase
    try {
      final user = _getCurrentUser();
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('price_offers').add({
        'productId': productId,
        'buyerId': user.uid,
        'offerPrice': offerPrice,
        'quantity': quantity,
        'message': message,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error submitting price offer: $e');
    }
  }

  Future<void> respondToPriceOffer(String offerId, String response, {double? counterOffer}) async {
    // Placeholder implementation
    try {
      final user = _getCurrentUser();
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('price_offers').doc(offerId).update({
        'response': response,
        if (counterOffer != null) 'counterOffer': counterOffer,
        'respondedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error responding to price offer: $e');
    }
  }

  Future<List<PriceOffer>> getUserOffers(String userId) async {
    // Placeholder implementation - return empty list for now
    return [];
  }

  Future<List<PriceOffer>> getProductOffers(String productId) async {
    // Placeholder implementation - return empty list for now
    return [];
  }

  Future<Map<String, dynamic>> getMarketAnalytics(String userId) async {
    // Placeholder implementation with default values
    return {
      'totalViews': 0,
      'totalInquiries': 0,
      'conversionRate': 0.0,
      'averageResponseTime': 0,
      'topProducts': [],
      'recentActivity': [],
    };
  }

  Future<Map<String, dynamic>> getProductAnalytics(String productId) async {
    // Placeholder implementation with default values
    return {
      'totalViews': 0,
      'totalInquiries': 0,
      'totalInterests': 0,
      'averagePrice': 0.0,
      'viewsToday': 0,
      'inquiriesToday': 0,
    };
  }

  Future<bool> checkApiHealth() async {
    // Always return true since we're using Firebase
    return true;
  }
}