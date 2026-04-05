import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // AGGRESSIVE ENTERPRISE CACHE
  final Map<String, Product> _productCache = {};
  final Map<String, List<Product>> _queryCache = {};
  DateTime? _lastCacheClear;

  // REACTIVE STREAM FOR INSTANT UPDATES
  final StreamController<void> _updateController =
      StreamController<void>.broadcast();
  Stream<void> get onProductsUpdated => _updateController.stream;

  Future<String> createProduct({
    required String name,
    required String description,
    required String category,
    required double price,
    required String unit,
    required int quantity,
    required String location,
    List<String> tags = const [],
    bool isOrganic = false,
    DateTime? harvestDate,
    DateTime? expiryDate,
    String? certificationDetails,
    List<XFile> imageFiles = const [],
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      List<String> imageUrls = [];
      if (imageFiles.isNotEmpty) {
        imageUrls =
            imageFiles.map((f) => 'https://placeholder.com/${f.name}').toList();
      }

      final product = Product(
        id: '',
        name: name,
        description: description,
        category: category,
        price: price,
        unit: unit,
        imageUrls: imageUrls,
        sellerId: user.uid,
        sellerName: user.displayName ?? user.email?.split('@')[0] ?? 'Seller',
        location: location,
        timestamp: DateTime.now(),
        createdAt: DateTime.now(),
        isOrganic: isOrganic,
        isAvailable: true,
        quantity: quantity,
        tags: tags,
      );

      return await addProduct(product);
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  Future<String> addProduct(Product product) async {
    try {
      final docRef =
          await _firestore.collection('products').add(product.toMap());
      final newProduct = product.copyWith(id: docRef.id);

      // Update Cache Immediately
      _productCache[docRef.id] = newProduct;
      _queryCache.clear();

      // Notify Listeners Instantly
      _updateController.add(null);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  Future<List<Product>> getProducts({
    String? category,
    String? sellerId,
    String? searchQuery,
    bool forceRefresh = false,
  }) async {
    final cacheKey =
        '${category ?? 'All'}_${sellerId ?? 'None'}_${searchQuery ?? 'None'}';

    if (!forceRefresh && _queryCache.containsKey(cacheKey)) {
      if (_lastCacheClear != null &&
          DateTime.now().difference(_lastCacheClear!) <
              const Duration(minutes: 5)) {
        return _queryCache[cacheKey]!;
      }
    }

    try {
      Query query = _firestore.collection('products');

      if (category != null && category != 'All') {
        query = query.where('category', isEqualTo: category);
      }

      if (sellerId != null) {
        query = query.where('sellerId', isEqualTo: sellerId);
      }

      query = query.orderBy('timestamp', descending: true);

      final snapshot =
          await query.get(const GetOptions(source: Source.serverAndCache));

      var products = snapshot.docs.map((doc) {
        final p = Product.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        _productCache[doc.id] = p;
        return p;
      }).toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        products = products
            .where((p) =>
                p.name.toLowerCase().contains(q) ||
                p.description.toLowerCase().contains(q))
            .toList();
      }

      _queryCache[cacheKey] = products;
      _lastCacheClear = DateTime.now();

      return products;
    } catch (e) {
      return _queryCache[cacheKey] ?? [];
    }
  }

  Future<List<Product>> getSellerProducts(String sellerId) async {
    return getProducts(sellerId: sellerId, forceRefresh: true);
  }

  Future<List<dynamic>> getSellingHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('sellerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getSellingSummary(String userId) async {
    try {
      final history = await getSellingHistory(userId);
      double totalRevenue = 0;
      for (var item in history) {
        totalRevenue += (item['totalAmount'] ?? 0.0);
      }
      return {
        'totalOrders': history.length,
        'totalRevenue': totalRevenue,
      };
    } catch (e) {
      return {'totalOrders': 0, 'totalRevenue': 0.0};
    }
  }

  Stream<List<Product>> getSellerProductsStream(String sellerId) {
    return _firestore
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final p = Product.fromMap(doc.id, doc.data());
        _productCache[doc.id] = p;
        return p;
      }).toList();
    });
  }

  Future<Product?> getProductById(String productId) async {
    if (_productCache.containsKey(productId)) {
      return _productCache[productId];
    }

    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        final product =
            Product.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        _productCache[productId] = product;
        return product;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateProduct(
      String productId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('products').doc(productId).update(updates);
      _productCache.remove(productId);
      _queryCache.clear();
      _updateController.add(null); // Notify Update
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
      _productCache.remove(productId);
      _queryCache.clear();
      _updateController.add(null); // Notify Update
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  Future<List<String>> getCategories() async {
    return [
      'Vegetables',
      'Fruits',
      'Grains',
      'Seeds',
      'Equipment',
      'Livestock',
      'Dairy',
      'Spices',
      'Fertilizers',
      'Organic',
      'Other'
    ];
  }

  List<String> getUnits() {
    return ['kg', 'g', 'ton', 'piece', 'dozen', 'bundle', 'bag', 'liter', 'ml'];
  }
}
