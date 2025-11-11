import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get authenticated user
  User? _getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  // Create new product using Firebase directly
  Future<String> createProduct({
    required String name,
    required String description,
    required String category,
    required double price,
    required String unit,
    required int quantity,
    required String location,
    List<String>? tags,
    bool isOrganic = false,
    DateTime? harvestDate,
    DateTime? expiryDate,
    String? certificationDetails,
    List<dynamic>? imageFiles,
  }) async {
    try {
      print('ProductService: Starting product creation...');
      print('ProductService: Product name: $name');
      
      // Check if user is authenticated
      final user = _getCurrentUser();
      if (user == null) {
        throw Exception('🔐 User not authenticated. Please login and try again.');
      }

      print('ProductService: User authenticated: ${user.uid}');
      print('ProductService: User email: ${user.email}');

      // Prepare product data with detailed logging
      final productData = {
        'name': name,
        'description': description,
        'category': category,
        'price': price,
        'unit': unit,
        'quantity': quantity,
        'location': location,
        'tags': tags ?? [],
        'isOrganic': isOrganic,
        'sellerId': user.uid,
        'sellerName': user.displayName ?? user.email ?? 'Unknown Seller',
        'imageUrls': <String>[], // For now, empty list of images
        'isAvailable': true,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (harvestDate != null) {
        productData['harvestDate'] = harvestDate.toIso8601String();
      }
      
      if (expiryDate != null) {
        productData['expiryDate'] = expiryDate.toIso8601String();
      }
      
      if (certificationDetails != null) {
        productData['certificationDetails'] = certificationDetails;
      }

      print('ProductService: Product data prepared');
      print('ProductService: Attempting Firestore write to products collection...');
      
      // Test Firestore connectivity first
      try {
        print('ProductService: Testing Firestore connectivity...');
        final testCollection = _firestore.collection('test');
        final testDoc = await testCollection.add({'test': true, 'timestamp': FieldValue.serverTimestamp()});
        print('ProductService: Firestore connectivity test successful: ${testDoc.id}');
        await testDoc.delete(); // Clean up test document
      } catch (connectivityError) {
        print('ProductService: Firestore connectivity test failed: $connectivityError');
        throw Exception('🌐 Cannot connect to database. Please check your internet connection and try again.');
      }
      
      // Add to Firestore
      DocumentReference docRef;
      try {
        docRef = await _firestore.collection('products').add(productData);
        print('ProductService: Product document created successfully with ID: ${docRef.id}');
      } catch (addError) {
        print('ProductService: Failed to add product document: $addError');
        print('ProductService: Add error type: ${addError.runtimeType}');
        
        if (addError.toString().contains('permission-denied')) {
          throw Exception('🔒 Permission denied. Please check your authentication and try again.');
        } else if (addError.toString().contains('network') || 
                   addError.toString().contains('unavailable') ||
                   addError.toString().contains('connection')) {
          throw Exception('🌐 Network error. Please check your internet connection and try again.');
        } else {
          throw Exception('💾 Database error: ${addError.toString()}');
        }
      }
      
      // Create selling history entry
      print('ProductService: Creating selling history entry...');
      final sellingHistoryData = {
        'productId': docRef.id,
        'productName': name,
        'sellerId': user.uid,
        'sellerName': user.displayName ?? user.email ?? 'Unknown Seller',
        'category': category,
        'initialPrice': price,
        'currentPrice': price,
        'totalQuantity': quantity,
        'soldQuantity': 0,
        'availableQuantity': quantity,
        'totalRevenue': 0.0,
        'totalViews': 0,
        'totalInquiries': 0,
        'status': 'active',
        'isActive': true,
        'listedDate': FieldValue.serverTimestamp(),
        'lastSoldDate': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      try {
        await _firestore.collection('selling_history').add(sellingHistoryData);
        print('ProductService: Selling history entry created successfully');
      } catch (historyError) {
        print('ProductService: Warning - Failed to create selling history: $historyError');
        // Don't fail the entire operation if selling history fails
      }
      
      print('ProductService: Product creation completed successfully with ID: ${docRef.id}');
      return docRef.id;
      
    } catch (e) {
      print('ProductService: Error creating product: $e');
      print('ProductService: Error type: ${e.runtimeType}');
      
      // Provide more specific error messages
      String errorMessage = e.toString();
      
      // Remove "Exception: " prefix if present
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      
      // Return formatted error messages
      if (errorMessage.contains('🔐') || errorMessage.contains('🌐') || 
          errorMessage.contains('💾') || errorMessage.contains('🔒')) {
        // Already formatted error message
        throw Exception(errorMessage);
      }
      
      // Handle Firebase-specific errors
      if (errorMessage.contains('permission-denied')) {
        throw Exception('🔒 Permission denied. Please check your authentication and try again.');
      } else if (errorMessage.contains('network') || 
                 errorMessage.contains('unavailable') ||
                 errorMessage.contains('timeout') ||
                 errorMessage.contains('connection')) {
        throw Exception('🌐 Network error. Please check your internet connection.');
      } else if (errorMessage.contains('quota')) {
        throw Exception('📊 Daily quota exceeded. Please try again tomorrow.');
      } else {
        throw Exception('❌ Failed to create product: $errorMessage');
      }
    }
  }

  // Get products with filtering using Firebase directly
  Future<List<Product>> getProducts({
    String? category,
    String? sellerId,
    String? excludeSeller,
    int limit = 20,
    int page = 1,
    bool? isAvailable,
    double? minPrice,
    double? maxPrice,
    bool? isOrganic,
    String? location,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    String? search,
  }) async {
    try {
      print('ProductService: Fetching products from Firestore...');
      
      Query query = _firestore.collection('products');
      
      // Apply filters
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      
      if (sellerId != null) {
        query = query.where('sellerId', isEqualTo: sellerId);
      }
      
      if (excludeSeller != null) {
        // We'll filter this in memory since we can't use != in Firestore
      }
      
      if (isAvailable != null) {
        query = query.where('isAvailable', isEqualTo: isAvailable);
      }
      
      if (isOrganic != null) {
        query = query.where('isOrganic', isEqualTo: isOrganic);
      }
      
      // Add ordering (try with error handling)
      try {
        if (sortBy == 'createdAt') {
          query = query.orderBy('createdAt', descending: sortOrder == 'desc');
        } else if (sortBy == 'price') {
          query = query.orderBy('price', descending: sortOrder == 'desc');
        }
      } catch (e) {
        print('ProductService: Ordering failed, using simple query: $e');
        // If ordering fails (missing index), continue without ordering
      }
      
      // Apply limit
      query = query.limit(limit);
      
      final QuerySnapshot querySnapshot = await query.get();
      
      List<Product> products = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Product.fromMap(data);
      }).toList();
      
      // Apply additional filters in memory
      if (excludeSeller != null) {
        products = products.where((product) => product.sellerId != excludeSeller).toList();
      }
      
      if (minPrice != null) {
        products = products.where((product) => product.price >= minPrice).toList();
      }
      
      if (maxPrice != null) {
        products = products.where((product) => product.price <= maxPrice).toList();
      }
      
      if (location != null) {
        products = products.where((product) => 
          product.location.toLowerCase().contains(location.toLowerCase())).toList();
      }
      
      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        products = products.where((product) =>
          product.name.toLowerCase().contains(searchLower) ||
          product.description.toLowerCase().contains(searchLower) ||
          product.tags.any((tag) => tag.toLowerCase().contains(searchLower))).toList();
      }
      
      print('ProductService: Fetched ${products.length} products');
      return products;
      
    } catch (e) {
      print('ProductService: Error fetching products: $e');
      
      // Fallback: simple query without ordering
      try {
        print('ProductService: Using fallback query...');
        final QuerySnapshot querySnapshot = await _firestore
            .collection('products')
            .limit(limit)
            .get();
        
        List<Product> products = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return Product.fromMap(data);
        }).toList();
        
        // Apply all filters in memory
        if (category != null) {
          products = products.where((product) => product.category == category).toList();
        }
        
        if (sellerId != null) {
          products = products.where((product) => product.sellerId == sellerId).toList();
        }
        
        if (excludeSeller != null) {
          products = products.where((product) => product.sellerId != excludeSeller).toList();
        }
        
        if (isAvailable != null) {
          products = products.where((product) => product.isAvailable == isAvailable).toList();
        }
        
        if (isOrganic != null) {
          products = products.where((product) => product.isOrganic == isOrganic).toList();
        }
        
        // Sort in memory
        products.sort((a, b) {
          if (sortBy == 'price') {
            return sortOrder == 'desc' 
              ? b.price.compareTo(a.price) 
              : a.price.compareTo(b.price);
          } else {
            return sortOrder == 'desc'
              ? b.timestamp.compareTo(a.timestamp)
              : a.timestamp.compareTo(b.timestamp);
          }
        });
        
        return products.take(limit).toList();
        
      } catch (fallbackError) {
        print('ProductService: Fallback query also failed: $fallbackError');
        throw Exception('Failed to fetch products: $fallbackError');
      }
    }
  }

  // Get product by ID using Firebase
  Future<Product?> getProductById(String productId) async {
    try {
      print('ProductService: Fetching product by ID: $productId');
      
      final doc = await _firestore.collection('products').doc(productId).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Product.fromMap(data);
      }
      
      return null;
    } catch (e) {
      print('ProductService: Error fetching product by ID: $e');
      throw Exception('Failed to fetch product: $e');
    }
  }

  // Get selling history by user using Firebase
  Future<Map<String, dynamic>> getSellingHistoryByUser(String userId) async {
    try {
      print('ProductService: Fetching selling history for user: $userId');
      
      final query = _firestore
          .collection('selling_history')
          .where('sellerId', isEqualTo: userId);
      
      final QuerySnapshot querySnapshot = await query.get();
      
      final historyList = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Calculate summary
      double totalRevenue = 0.0;
      int totalProducts = historyList.length;
      int activeProducts = 0;
      
      for (final item in historyList) {
        totalRevenue += (item['totalRevenue'] ?? 0.0).toDouble();
        if (item['isActive'] == true) activeProducts++;
      }
      
      print('ProductService: Found ${historyList.length} selling history records');
      
      return {
        'history': historyList,
        'summary': {
          'totalProducts': totalProducts,
          'activeProducts': activeProducts,
          'totalRevenue': totalRevenue,
        },
        'pagination': {
          'page': 1,
          'limit': historyList.length,
          'total': historyList.length,
        },
      };
      
    } catch (e) {
      print('ProductService: Error fetching selling history: $e');
      throw Exception('Failed to fetch selling history: $e');
    }
  }

  // Update product using Firebase
  Future<void> updateProduct(String productId, Map<String, dynamic> updates) async {
    try {
      print('ProductService: Updating product: $productId');
      
      // Add timestamp for tracking
      updates['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('products').doc(productId).update(updates);
      
      print('ProductService: Product updated successfully');
    } catch (e) {
      print('ProductService: Error updating product: $e');
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete product using Firebase
  Future<void> deleteProduct(String productId) async {
    try {
      print('ProductService: Deleting product: $productId');
      
      await _firestore.collection('products').doc(productId).delete();
      
      // Also delete related selling history
      final historyQuery = await _firestore
          .collection('selling_history')
          .where('productId', isEqualTo: productId)
          .get();
      
      for (final doc in historyQuery.docs) {
        await doc.reference.delete();
      }
      
      print('ProductService: Product and related data deleted successfully');
    } catch (e) {
      print('ProductService: Error deleting product: $e');
      throw Exception('Failed to delete product: $e');
    }
  }

  // Get available categories
  Future<List<String>> getCategories() async {
    return [
      'Vegetables',
      'Fruits',
      'Grains',
      'Seeds',
      'Equipment',
      'Dairy',
      'Spices',
      'Fertilizers',
      'Organic',
      'Other'
    ];
  }

  // Get available units
  List<String> getUnits() {
    return ['kg', 'g', 'ton', 'piece', 'dozen', 'bundle', 'bag', 'liter', 'ml'];
  }
}