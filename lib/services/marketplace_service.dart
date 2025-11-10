import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../models/conversation_model.dart';
import '../services/conversation_service.dart';

class MarketplaceService {
  static final MarketplaceService _instance = MarketplaceService._internal();
  factory MarketplaceService() => _instance;
  MarketplaceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for products to avoid repeated fetches
  static final Map<String, List<Product>> _productCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // Pagination state
  static const int _pageSize = 20;
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;

  /// Get products with pagination and caching for better performance
  /// Excludes current user's products from buying section
  Future<List<Product>> getProducts({
    String? category,
    UserRole? userRole,
    bool loadMore = false,
    bool forceRefresh = false,
    bool excludeCurrentUser = false,
  }) async {
    try {
      final cacheKey = '${category ?? 'all'}_${userRole?.toString() ?? 'all'}';
      
      // Check cache first (unless force refresh or loading more)
      if (!forceRefresh && !loadMore && _isCacheValid(cacheKey)) {
        print('MarketplaceService: Returning cached products for $cacheKey');
        List<Product> cachedProducts = _productCache[cacheKey] ?? [];
        
        // Apply current user exclusion to cached results if needed
        if (excludeCurrentUser) {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            cachedProducts = cachedProducts.where((product) => product.sellerId != currentUser.uid).toList();
          }
        }
        
        return cachedProducts;
      }

      // Reset pagination if not loading more
      if (!loadMore) {
        _lastDocument = null;
        _hasMoreData = true;
      }

      print('MarketplaceService: Fetching products from Firestore...');
      
      // Use the simplest possible queries to avoid index issues
      List<Product> allProducts = [];
      
      if (category != null && category != 'All') {
        // Category-specific query
        allProducts = await _getProductsByCategory(category);
      } else {
        // Default query - get all products with simple ordering
        allProducts = await _getAllProducts();
      }
      
      // Apply all filters in application layer
      List<Product> filteredProducts = allProducts;
      
      // Filter by availability for farmers
      if (userRole == UserRole.farmer) {
        filteredProducts = filteredProducts.where((product) => product.isAvailable).toList();
      }
      
      // Filter out current user's products if needed
      if (excludeCurrentUser) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          filteredProducts = filteredProducts.where((product) => product.sellerId != currentUser.uid).toList();
        }
      }

      // Sort by timestamp in memory
      filteredProducts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Limit results to page size
      if (filteredProducts.length > _pageSize) {
        filteredProducts = filteredProducts.take(_pageSize).toList();
      }

      if (loadMore) {
        // Append to existing cache
        final existingProducts = _productCache[cacheKey] ?? [];
        _productCache[cacheKey] = [...existingProducts, ...filteredProducts];
      } else {
        // Replace cache
        _productCache[cacheKey] = filteredProducts;
        _cacheTimestamps[cacheKey] = DateTime.now();
      }

      print('MarketplaceService: Fetched ${filteredProducts.length} products');
      return filteredProducts;

    } catch (e) {
      print('MarketplaceService: Error fetching products: $e');
      
      // Always use fallback for any error
      print('MarketplaceService: Using fallback query...');
      return _getFallbackProducts(category: category, userRole: userRole, excludeCurrentUser: excludeCurrentUser);
    }
  }

  /// Get products by category with simple query
  Future<List<Product>> _getProductsByCategory(String category) async {
    try {
      final query = _firestore
          .collection('products')
          .where('category', isEqualTo: category)
          .limit(_pageSize * 2);
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Product.fromMap(data);
      }).toList();
    } catch (e) {
      print('MarketplaceService: Error in _getProductsByCategory: $e');
      throw e;
    }
  }

  /// Get all products with simple query
  Future<List<Product>> _getAllProducts() async {
    try {
      // Try with createdAt ordering first
      try {
        final query = _firestore
            .collection('products')
            .orderBy('createdAt', descending: true)
            .limit(_pageSize * 2);
        
        final querySnapshot = await query.get();
        
        return querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return Product.fromMap(data);
        }).toList();
      } catch (e) {
        // If createdAt fails, try without ordering
        print('MarketplaceService: CreatedAt ordering failed, trying without ordering: $e');
        final query = _firestore
            .collection('products')
            .limit(_pageSize * 2);
        
        final querySnapshot = await query.get();
        
        return querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return Product.fromMap(data);
        }).toList();
      }
    } catch (e) {
      print('MarketplaceService: Error in _getAllProducts: $e');
      throw e;
    }
  }

  /// Get product by ID with caching
  Future<Product?> getProductById(String productId) async {
    try {
      // Check if product exists in any cache first
      for (final products in _productCache.values) {
        final product = products.where((p) => p.id == productId).firstOrNull;
        if (product != null) {
          return product;
        }
      }

      // Fetch from Firestore
      final doc = await _firestore.collection('products').doc(productId).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Product.fromMap(data);
      }
      
      return null;
    } catch (e) {
      print('MarketplaceService: Error fetching product by ID: $e');
      rethrow;
    }
  }

  /// Add new product (for vendors/addats)
  Future<String> addProduct(Product product, String sellerId) async {
    try {
      print('MarketplaceService: Starting product addition...');
      
      final productData = product.toMap();
      productData['sellerId'] = sellerId;
      productData['timestamp'] = FieldValue.serverTimestamp();
      productData['isAvailable'] = true;
      productData['createdAt'] = FieldValue.serverTimestamp();
      productData['updatedAt'] = FieldValue.serverTimestamp();

      print('MarketplaceService: Product data prepared: ${productData['name']}');
      
      final docRef = await _firestore.collection('products').add(productData);
      
      // Clear relevant caches
      _clearProductCaches();
      
      print('MarketplaceService: Product added successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('MarketplaceService: Error adding product: $e');
      print('MarketplaceService: Error type: ${e.runtimeType}');
      if (e.toString().contains('permission-denied')) {
        throw Exception('Permission denied. Please check your authentication and try again.');
      } else if (e.toString().contains('network')) {
        throw Exception('Network error. Please check your internet connection.');
      } else {
        throw Exception('Failed to add product: ${e.toString()}');
      }
    }
  }

  /// Update product
  Future<void> updateProduct(String productId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('products').doc(productId).update(updates);
      
      // Clear relevant caches
      _clearProductCaches();
      
      print('MarketplaceService: Product updated: $productId');
    } catch (e) {
      print('MarketplaceService: Error updating product: $e');
      rethrow;
    }
  }

  /// Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
      
      // Clear relevant caches
      _clearProductCaches();
      
      print('MarketplaceService: Product deleted: $productId');
    } catch (e) {
      print('MarketplaceService: Error deleting product: $e');
      rethrow;
    }
  }

  /// Get products by seller ID
  Future<List<Product>> getProductsBySeller(String sellerId) async {
    try {
      // Use createdAt instead of timestamp to match Firestore index
      final query = _firestore
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true);
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Product.fromMap(data);
      }).toList();
    } catch (e) {
      print('MarketplaceService: Error fetching products by seller: $e');
      
      // Fallback: Try without ordering if index doesn't exist
      try {
        print('MarketplaceService: Trying fallback query without ordering...');
        final fallbackQuery = _firestore
            .collection('products')
            .where('sellerId', isEqualTo: sellerId);
        
        final fallbackSnapshot = await fallbackQuery.get();
        
        final products = fallbackSnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Product.fromMap(data);
        }).toList();
        
        // Sort in memory
        products.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        return products;
      } catch (fallbackError) {
        print('MarketplaceService: Fallback query also failed: $fallbackError');
        rethrow;
      }
    }
  }

  /// Search products with optimized query
  Future<List<Product>> searchProducts(
    String searchQuery, {
    String? category,
    UserRole? userRole,
  }) async {
    try {
      if (searchQuery.trim().isEmpty) {
        return getProducts(category: category, userRole: userRole);
      }

      Query query = _firestore.collection('products');

      // Filter by category if specified
      if (category != null && category != 'All') {
        query = query.where('category', isEqualTo: category);
      }

      // Role-based filtering
      if (userRole == UserRole.farmer) {
        query = query.where('isAvailable', isEqualTo: true);
      }

      // Use array-contains for tag search or name search
      // For better search, consider using Algolia or similar service
      final querySnapshot = await query.get();

      final searchLower = searchQuery.toLowerCase();
      
      return querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return Product.fromMap(data);
          })
          .where((product) =>
              product.name.toLowerCase().contains(searchLower) ||
              product.description.toLowerCase().contains(searchLower) ||
              product.tags.any((tag) => tag.toLowerCase().contains(searchLower)))
          .toList();
    } catch (e) {
      print('MarketplaceService: Error searching products: $e');
      rethrow;
    }
  }

  /// Get categories
  Future<List<String>> getCategories() async {
    try {
      final doc = await _firestore.collection('app_config').doc('categories').get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return List<String>.from(data['categories'] ?? []);
      }
      
      // Return default categories if not found
      return [
        'Vegetables',
        'Fruits', 
        'Grains',
        'Seeds',
        'Equipment',
        'Dairy',
        'Spices',
        'Fertilizers'
      ];
    } catch (e) {
      print('MarketplaceService: Error fetching categories: $e');
      // Return default categories on error
      return [
        'Vegetables',
        'Fruits', 
        'Grains',
        'Seeds',
        'Equipment',
        'Dairy',
        'Spices',
        'Fertilizers'
      ];
    }
  }

  /// Check if there's more data for pagination
  bool get hasMoreData => _hasMoreData;

  /// Clear all product caches
  void _clearProductCaches() {
    _productCache.clear();
    _cacheTimestamps.clear();
  }

  /// Check if cache is still valid
  bool _isCacheValid(String cacheKey) {
    if (!_productCache.containsKey(cacheKey) || !_cacheTimestamps.containsKey(cacheKey)) {
      return false;
    }
    
    final cacheTime = _cacheTimestamps[cacheKey]!;
    return DateTime.now().difference(cacheTime) < _cacheValidDuration;
  }

  /// Fallback method for when complex queries fail due to missing indexes
  Future<List<Product>> _getFallbackProducts({
    String? category,
    UserRole? userRole,
    bool excludeCurrentUser = false,
  }) async {
    try {
      print('MarketplaceService: Using fallback query...');
      
      // Use the simplest possible query
      Query query = _firestore.collection('products').limit(_pageSize * 2);
      
      final QuerySnapshot querySnapshot = await query.get();
      
      List<Product> products = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Product.fromMap(data);
      }).toList();
      
      // Apply all filters in memory
      if (category != null && category != 'All') {
        products = products.where((product) => product.category == category).toList();
      }
      
      if (userRole == UserRole.farmer) {
        products = products.where((product) => product.isAvailable).toList();
      }
      
      if (excludeCurrentUser) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          products = products.where((product) => product.sellerId != currentUser.uid).toList();
        }
      }
      
      // Sort by timestamp in memory
      products.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Take only the page size after filtering
      if (products.length > _pageSize) {
        products = products.take(_pageSize).toList();
      }
      
      print('MarketplaceService: Fallback query returned ${products.length} products');
      return products;
      
    } catch (e) {
      print('MarketplaceService: Fallback query also failed: $e');
      return [];
    }
  }

  /// Force refresh cache
  void clearCache() {
    _clearProductCaches();
  }

  /// Contact seller and create conversation
  Future<String> contactSeller({
    required Product product,
    required String buyerName,
    String? initialMessage,
  }) async {
    try {
      final conversationService = ConversationService();
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) throw Exception('User not authenticated');
      
      final conversationId = await conversationService.createOrGetConversation(
        productId: product.id,
        productName: product.name,
        buyerId: currentUser.uid,
        buyerName: buyerName,
        sellerId: product.sellerId,
        sellerName: product.sellerName,
      );
      
      // Send initial message if provided
      if (initialMessage != null && initialMessage.isNotEmpty) {
        await conversationService.sendMessage(
          conversationId: conversationId,
          receiverId: product.sellerId,
          content: initialMessage,
          type: MessageType.text,
        );
      }
      
      return conversationId;
    } catch (e) {
      throw Exception('Failed to contact seller: $e');
    }
  }
  Future<void> preloadProducts({UserRole? userRole}) async {
    try {
      // Preload main category data
      await getProducts(userRole: userRole);
      
      // Preload categories
      await getCategories();
      
      print('MarketplaceService: Preloading completed');
    } catch (e) {
      print('MarketplaceService: Error preloading data: $e');
    }
  }
}

// Extension to handle null safety for firstOrNull
extension IterableExtension<E> on Iterable<E> {
  E? get firstOrNull {
    return isEmpty ? null : first;
  }
}