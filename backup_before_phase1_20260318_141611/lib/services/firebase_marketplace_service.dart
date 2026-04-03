import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';

/// Complete Firebase-integrated marketplace service with error handling
class FirebaseMarketplaceService {
  static final FirebaseMarketplaceService _instance = FirebaseMarketplaceService._internal();
  factory FirebaseMarketplaceService() => _instance;
  FirebaseMarketplaceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String _productsCollection = 'products';
  static const String _ordersCollection = 'orders';
  static const String _usersCollection = 'users';

  /// Get all products with search and category filtering
  Future<List<Product>> getProducts({
    String? searchQuery,
    String? category,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection(_productsCollection);

      // Filter by category if provided
      if (category != null && category.isNotEmpty && category != 'All') {
        query = query.where('category', isEqualTo: category);
      }

      // Add ordering and limit
      query = query.orderBy('timestamp', descending: true).limit(limit);

      final snapshot = await query.get();
      List<Product> products = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Product.fromMap(data);
      }).toList();

      // Apply search filter in memory (for simplicity)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        products = products.where((product) {
          return product.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                 product.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
                 product.category.toLowerCase().contains(searchQuery.toLowerCase()) ||
                 product.sellerName.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();
      }

      return products;
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return [];
    }
  }

  /// Get products by seller ID
  Future<List<Product>> getProductsBySeller(String sellerId) async {
    try {
      final snapshot = await _firestore
          .collection(_productsCollection)
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Product.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching seller products: $e');
      return [];
    }
  }

  /// Get product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      final doc = await _firestore.collection(_productsCollection).doc(productId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Product.fromMap(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching product: $e');
      return null;
    }
  }

  /// Add new product
  Future<String?> addProduct(Product product) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final productData = product.toMap();
      productData['sellerId'] = user.uid;
      productData['sellerName'] = user.displayName ?? user.email?.split('@')[0] ?? 'Seller';
      productData['timestamp'] = FieldValue.serverTimestamp();

      final docRef = await _firestore.collection(_productsCollection).add(productData);
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding product: $e');
      return null;
    }
  }

  /// Update product
  Future<bool> updateProduct(String productId, Product product) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user owns the product
      final productDoc = await _firestore.collection(_productsCollection).doc(productId).get();
      if (!productDoc.exists) throw Exception('Product not found');
      
      final productData = productDoc.data()!;
      if (productData['sellerId'] != user.uid) {
        throw Exception('Unauthorized: You can only update your own products');
      }

      final updateData = product.toMap();
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(_productsCollection).doc(productId).update(updateData);
      return true;
    } catch (e) {
      debugPrint('Error updating product: $e');
      return false;
    }
  }

  /// Delete product
  Future<bool> deleteProduct(String productId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user owns the product
      final productDoc = await _firestore.collection(_productsCollection).doc(productId).get();
      if (!productDoc.exists) throw Exception('Product not found');
      
      final productData = productDoc.data()!;
      if (productData['sellerId'] != user.uid) {
        throw Exception('Unauthorized: You can only delete your own products');
      }

      await _firestore.collection(_productsCollection).doc(productId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return false;
    }
  }

  /// Create order
  Future<String?> createOrder({
    required String productId,
    required int quantity,
    required double unitPrice,
    required String buyerName,
    required String buyerPhone,
    required String buyerAddress,
    required DeliveryType deliveryType,
    String? notes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get product details
      final product = await getProductById(productId);
      if (product == null) throw Exception('Product not found');

      // Check availability
      if (product.quantity < quantity) {
        throw Exception('Insufficient quantity available');
      }

      final totalAmount = unitPrice * quantity;
      
      final order = OrderModel(
        id: '', // Will be set by Firestore
        productId: productId,
        productName: product.name,
        productCategory: product.category,
        productImageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
        buyerId: user.uid,
        buyerName: buyerName,
        buyerPhone: buyerPhone,
        buyerAddress: buyerAddress,
        sellerId: product.sellerId,
        sellerName: product.sellerName,
        sellerPhone: '', // Will be fetched from seller profile
        unitPrice: unitPrice,
        quantity: quantity,
        unit: product.unit,
        totalAmount: totalAmount,
        status: OrderStatus.pending,
        paymentStatus: PaymentStatus.pending,
        deliveryType: deliveryType,
        orderDate: DateTime.now(),
        notes: notes,
      );

      // Create order document
      final docRef = await _firestore.collection(_ordersCollection).add(order.toMap());
      
      // Update product quantity
      await _firestore.collection(_productsCollection).doc(productId).update({
        'quantity': FieldValue.increment(-quantity),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating order: $e');
      return null;
    }
  }

  /// Get orders for buyer
  Future<List<OrderModel>> getBuyerOrders() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('buyerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return OrderModel.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching buyer orders: $e');
      return [];
    }
  }

  /// Get orders for seller
  Future<List<OrderModel>> getSellerOrders() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('sellerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return OrderModel.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching seller orders: $e');
      return [];
    }
  }

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      return false;
    }
  }

  /// Update payment status
  Future<bool> updatePaymentStatus(String orderId, PaymentStatus status) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'paymentStatus': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error updating payment status: $e');
      return false;
    }
  }

  /// Get available categories
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore.collection(_productsCollection).get();
      final Set<String> categories = {};
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [
        'Vegetables',
        'Fruits',
        'Grains',
        'Dairy',
        'Organic',
        'Seeds',
        'Equipment',
      ];
    }
  }

  /// Search products
  Stream<List<Product>> searchProducts(String searchQuery) {
    if (searchQuery.isEmpty) {
      return _firestore
          .collection(_productsCollection)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots()
          .map(_convertToProducts);
    }

    // Note: Firestore doesn't support full-text search natively
    // For production, consider using Algolia or similar service
    return _firestore
        .collection(_productsCollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      final products = _convertToProducts(snapshot);
      return products.where((product) {
        return product.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
               product.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
               product.category.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    });
  }

  /// Get real-time products stream
  Stream<List<Product>> getProductsStream({String? category}) {
    Query query = _firestore.collection(_productsCollection);

    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map(_convertToProducts);
  }

  /// Convert Firestore snapshot to Product list
  List<Product> _convertToProducts(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return Product.fromMap(data);
    }).toList();
  }

  /// Check if user is seller of product
  Future<bool> isProductSeller(String productId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection(_productsCollection).doc(productId).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      return data['sellerId'] == user.uid;
    } catch (e) {
      debugPrint('Error checking product seller: $e');
      return false;
    }
  }

  /// Get seller statistics
  Future<Map<String, dynamic>> getSellerStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      // Get products count
      final productsSnapshot = await _firestore
          .collection(_productsCollection)
          .where('sellerId', isEqualTo: user.uid)
          .get();

      // Get orders count
      final ordersSnapshot = await _firestore
          .collection(_ordersCollection)
          .where('sellerId', isEqualTo: user.uid)
          .get();

      // Calculate total revenue
      double totalRevenue = 0;
      int completedOrders = 0;
      
      for (final doc in ordersSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        if (status == 'delivered' || status == 'completed') {
          totalRevenue += (data['totalAmount'] ?? 0.0).toDouble();
          completedOrders++;
        }
      }

      return {
        'totalProducts': productsSnapshot.docs.length,
        'totalOrders': ordersSnapshot.docs.length,
        'completedOrders': completedOrders,
        'totalRevenue': totalRevenue,
        'activeProducts': productsSnapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['quantity'] ?? 0) > 0 && (data['isAvailable'] ?? true);
        }).length,
      };
    } catch (e) {
      debugPrint('Error fetching seller stats: $e');
      return {};
    }
  }
}