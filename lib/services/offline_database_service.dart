import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import 'dart:convert';

/// Local database service for offline support
class OfflineDatabaseService {
  static final OfflineDatabaseService _instance = OfflineDatabaseService._internal();
  factory OfflineDatabaseService() => _instance;
  OfflineDatabaseService._internal();

  Database? _database;
  
  static const String _dbName = 'farmkarts_offline.db';
  static const int _dbVersion = 1;

  /// Initialize database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    debugPrint('OfflineDB: Initializing database at $path');

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    debugPrint('OfflineDB: Creating tables...');

    // Products table
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT,
        price REAL NOT NULL,
        unit TEXT,
        imageUrls TEXT,
        sellerId TEXT,
        sellerName TEXT,
        location TEXT,
        timestamp INTEGER,
        createdAt INTEGER,
        isOrganic INTEGER DEFAULT 0,
        isAvailable INTEGER DEFAULT 1,
        quantity INTEGER DEFAULT 0,
        tags TEXT,
        rating REAL,
        reviewCount INTEGER DEFAULT 0,
        syncStatus TEXT DEFAULT 'synced',
        lastSyncedAt INTEGER
      )
    ''');

    // User profiles table
    await db.execute('''
      CREATE TABLE user_profiles (
        uid TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        role TEXT NOT NULL,
        fullName TEXT NOT NULL,
        mobileNo TEXT,
        acresLand REAL,
        dukanName TEXT,
        licenseImageUrl TEXT,
        createdAt INTEGER,
        updatedAt INTEGER,
        syncStatus TEXT DEFAULT 'synced',
        lastSyncedAt INTEGER
      )
    ''');

    // Pending operations table (for sync queue)
    await db.execute('''
      CREATE TABLE pending_operations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operationType TEXT NOT NULL,
        tableName TEXT NOT NULL,
        recordId TEXT NOT NULL,
        data TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        retryCount INTEGER DEFAULT 0
      )
    ''');

    // Cart table (offline cart)
    await db.execute('''
      CREATE TABLE cart_items (
        id TEXT PRIMARY KEY,
        productId TEXT NOT NULL,
        productName TEXT,
        quantity REAL NOT NULL,
        price REAL NOT NULL,
        imageUrl TEXT,
        addedAt INTEGER,
        syncStatus TEXT DEFAULT 'pending'
      )
    ''');

    // Wishlist table
    await db.execute('''
      CREATE TABLE wishlist_items (
        id TEXT PRIMARY KEY,
        productId TEXT NOT NULL,
        productName TEXT,
        price REAL,
        imageUrl TEXT,
        addedAt INTEGER,
        syncStatus TEXT DEFAULT 'pending'
      )
    ''');

    // Search history table
    await db.execute('''
      CREATE TABLE search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_products_category ON products(category)');
    await db.execute('CREATE INDEX idx_products_sellerId ON products(sellerId)');
    await db.execute('CREATE INDEX idx_pending_ops_timestamp ON pending_operations(timestamp)');

    debugPrint('OfflineDB: Tables created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('OfflineDB: Upgrading from v$oldVersion to v$newVersion');
    // Handle database migrations here
  }

  // ==================== PRODUCTS ====================

  /// Save product to offline database
  Future<void> saveProduct(Product product) async {
    final db = await database;
    
    final data = {
      'id': product.id,
      'name': product.name,
      'description': product.description,
      'category': product.category,
      'price': product.price,
      'unit': product.unit,
      'imageUrls': jsonEncode(product.imageUrls),
      'sellerId': product.sellerId,
      'sellerName': product.sellerName,
      'location': product.location,
      'timestamp': product.timestamp.millisecondsSinceEpoch,
      'createdAt': product.createdAt.millisecondsSinceEpoch,
      'isOrganic': product.isOrganic ? 1 : 0,
      'isAvailable': product.isAvailable ? 1 : 0,
      'quantity': product.quantity,
      'tags': jsonEncode(product.tags),
      'rating': product.rating,
      'reviewCount': product.reviewCount,
      'syncStatus': 'synced',
      'lastSyncedAt': DateTime.now().millisecondsSinceEpoch,
    };

    await db.insert(
      'products',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    debugPrint('OfflineDB: Saved product ${product.id}');
  }

  /// Save multiple products (batch operation)
  Future<void> saveProducts(List<Product> products) async {
    final db = await database;
    final batch = db.batch();

    for (final product in products) {
      final data = {
        'id': product.id,
        'name': product.name,
        'description': product.description,
        'category': product.category,
        'price': product.price,
        'unit': product.unit,
        'imageUrls': jsonEncode(product.imageUrls),
        'sellerId': product.sellerId,
        'sellerName': product.sellerName,
        'location': product.location,
        'timestamp': product.timestamp.millisecondsSinceEpoch,
        'createdAt': product.createdAt.millisecondsSinceEpoch,
        'isOrganic': product.isOrganic ? 1 : 0,
        'isAvailable': product.isAvailable ? 1 : 0,
        'quantity': product.quantity,
        'tags': jsonEncode(product.tags),
        'rating': product.rating,
        'reviewCount': product.reviewCount,
        'syncStatus': 'synced',
        'lastSyncedAt': DateTime.now().millisecondsSinceEpoch,
      };

      batch.insert(
        'products',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    debugPrint('OfflineDB: Saved ${products.length} products');
  }

  /// Get products from offline database
  Future<List<Product>> getProducts({
    String? category,
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (category != null && category != 'All') {
      whereClause = 'WHERE category = ?';
      whereArgs.add(category);
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM products
      $whereClause
      ORDER BY timestamp DESC
      LIMIT ? OFFSET ?
    ''', [...whereArgs, limit, offset]);

    return maps.map((map) => _productFromMap(map)).toList();
  }

  /// Get product by ID
  Future<Product?> getProductById(String productId) async {
    final db = await database;
    
    final maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _productFromMap(maps.first);
  }

  /// Search products offline
  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    
    final maps = await db.rawQuery('''
      SELECT * FROM products
      WHERE name LIKE ? OR description LIKE ? OR category LIKE ?
      ORDER BY timestamp DESC
      LIMIT 50
    ''', ['%$query%', '%$query%', '%$query%']);

    // Save search query
    await db.insert('search_history', {
      'query': query,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    return maps.map((map) => _productFromMap(map)).toList();
  }

  /// Delete product
  Future<void> deleteProduct(String productId) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [productId]);
    debugPrint('OfflineDB: Deleted product $productId');
  }

  // ==================== PENDING OPERATIONS ====================

  /// Add operation to sync queue
  Future<void> addPendingOperation({
    required String operationType,
    required String tableName,
    required String recordId,
    required Map<String, dynamic> data,
  }) async {
    final db = await database;
    
    await db.insert('pending_operations', {
      'operationType': operationType,
      'tableName': tableName,
      'recordId': recordId,
      'data': jsonEncode(data),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'retryCount': 0,
    });

    debugPrint('OfflineDB: Added pending operation: $operationType on $tableName');
  }

  /// Get all pending operations
  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    final db = await database;
    return await db.query(
      'pending_operations',
      orderBy: 'timestamp ASC',
    );
  }

  /// Remove pending operation
  Future<void> removePendingOperation(int id) async {
    final db = await database;
    await db.delete('pending_operations', where: 'id = ?', whereArgs: [id]);
  }

  /// Clear all pending operations
  Future<void> clearPendingOperations() async {
    final db = await database;
    await db.delete('pending_operations');
    debugPrint('OfflineDB: Cleared all pending operations');
  }

  // ==================== CART ====================

  /// Add item to offline cart
  Future<void> addToCart({
    required String productId,
    required String productName,
    required double quantity,
    required double price,
    String? imageUrl,
  }) async {
    final db = await database;
    
    final cartItemId = 'cart_${productId}_${DateTime.now().millisecondsSinceEpoch}';
    
    await db.insert('cart_items', {
      'id': cartItemId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
      'addedAt': DateTime.now().millisecondsSinceEpoch,
      'syncStatus': 'pending',
    });

    debugPrint('OfflineDB: Added to cart: $productName');
  }

  /// Get cart items
  Future<List<Map<String, dynamic>>> getCartItems() async {
    final db = await database;
    return await db.query('cart_items', orderBy: 'addedAt DESC');
  }

  /// Remove from cart
  Future<void> removeFromCart(String cartItemId) async {
    final db = await database;
    await db.delete('cart_items', where: 'id = ?', whereArgs: [cartItemId]);
  }

  /// Clear cart
  Future<void> clearCart() async {
    final db = await database;
    await db.delete('cart_items');
    debugPrint('OfflineDB: Cleared cart');
  }

  // ==================== UTILITY ====================

  /// Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('products');
    await db.delete('user_profiles');
    await db.delete('pending_operations');
    await db.delete('cart_items');
    await db.delete('wishlist_items');
    debugPrint('OfflineDB: Cleared all data');
  }

  /// Get database stats
  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    
    final productsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM products'),
    ) ?? 0;
    
    final pendingOpsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM pending_operations'),
    ) ?? 0;
    
    final cartItemsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM cart_items'),
    ) ?? 0;

    return {
      'products': productsCount,
      'pendingOperations': pendingOpsCount,
      'cartItems': cartItemsCount,
    };
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    debugPrint('OfflineDB: Database closed');
  }

  // ==================== HELPERS ====================

  Product _productFromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      price: map['price'],
      unit: map['unit'] ?? 'kg',
      imageUrls: map['imageUrls'] != null 
          ? List<String>.from(jsonDecode(map['imageUrls']))
          : [],
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      location: map['location'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      isOrganic: map['isOrganic'] == 1,
      isAvailable: map['isAvailable'] == 1,
      quantity: map['quantity'] ?? 0,
      tags: map['tags'] != null 
          ? List<String>.from(jsonDecode(map['tags']))
          : [],
      rating: map['rating'],
      reviewCount: map['reviewCount'] ?? 0,
    );
  }
}
