import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import '../models/inventory_model.dart';

class InventoryService {
  static final InventoryService _instance = InventoryService._internal();
  factory InventoryService() => _instance;
  InventoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  User? get _currentUser => _auth.currentUser;

  // Add Item
  Future<String> addItem(InventoryItem item) async {
    final user = _currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    final itemData = item.toMap();
    itemData['ownerId'] = user.uid; // Force ownerId to current user
    
    final docRef = await _firestore.collection('inventory').add(itemData);
    return docRef.id;
  }

  // Update Item
  Future<void> updateItem(String itemId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('inventory').doc(itemId).update(updates);
  }

  // Delete Item
  Future<void> deleteItem(String itemId) async {
    await _firestore.collection('inventory').doc(itemId).delete();
  }

  // Get Item Stream (Reactive to Auth Changes)
  Stream<List<InventoryItem>> getInventoryStream() {
    return _auth.authStateChanges().switchMap((user) {
      if (user == null) {
        print('InventoryService: No user logged in, returning empty stream');
        return Stream.value(<InventoryItem>[]);
      }
      
      print('InventoryService: Fetching inventory for UID: ${user.uid}');
      
      return _firestore
          .collection('inventory')
          .where('ownerId', isEqualTo: user.uid)
          .snapshots()
          .map((snapshot) {
        print('InventoryService: Received ${snapshot.docs.length} items');
        return snapshot.docs.map((doc) {
          return InventoryItem.fromMap(doc.id, doc.data());
        }).toList();
      }).handleError((error) {
        print('InventoryService: Stream Error: $error');
        throw error;
      });
    });
  }

  // Helper to sync marketplace products to inventory
  Future<void> syncMarketplaceToInventory() async {
    final user = _currentUser;
    if (user == null) {
      print('InventoryService: Cannot sync, user is null');
      return;
    }
    
    print('InventoryService: Syncing products for user ${user.uid}');
    
    try {
      final marketplaceDocs = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: user.uid)
          .get();
          
      print('InventoryService: Found ${marketplaceDocs.docs.length} marketplace products');
          
      for (var doc in marketplaceDocs.docs) {
        final data = doc.data();
        
        // Check if already in inventory using marketplaceProductId as key
        final existing = await _firestore
            .collection('inventory')
            .where('marketplaceProductId', isEqualTo: doc.id)
            .get();
            
        if (existing.docs.isEmpty) {
          final inventoryItem = {
            'name': data['name'],
            'description': data['description'] ?? '',
            'category': data['category'] ?? 'Product',
            'type': 'product',
            'quantity': (data['quantity'] ?? 0).toDouble(),
            'unit': data['unit'] ?? 'units',
            'price': (data['price'] ?? 0).toDouble(),
            'imageUrls': data['imageUrls'] ?? [],
            'ownerId': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'isForSale': true,
            'marketplaceProductId': doc.id,
          };
          await _firestore.collection('inventory').add(inventoryItem);
          print('InventoryService: Added product ${data['name']} to inventory');
        }
      }
    } catch (e) {
      print('InventoryService: Sync error: $e');
    }
  }
}
