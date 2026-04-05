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
    itemData['userId'] = user.uid; // Force userId to current user

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
        return Stream.value(<InventoryItem>[]);
      }

      return _firestore
          .collection('inventory')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          try {
            return InventoryItem.fromMap(doc.id, doc.data());
          } catch (e) {
            // print('InventoryService: Error mapping item ${doc.id}: $e');
            // Return a minimal item instead of failing the whole list
            return InventoryItem(
              id: doc.id,
              name: 'Error Loading Item',
              description: e.toString(),
              category: 'Error',
              type: InventoryType.other,
              quantity: 0,
              unit: 'error',
              price: 0,
              imageUrls: [],
              userId: user.uid,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }
        }).toList();
      });
    });
  }

  // Helper to sync marketplace products to inventory
  Future<void> syncMarketplaceToInventory() async {
    final user = _currentUser;
    if (user == null) return;

    try {
      final marketplaceDocs = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: user.uid)
          .get();

      for (var doc in marketplaceDocs.docs) {
        final data = doc.data();

        // Check if already in inventory using marketplaceProductId as key
        final existing = await _firestore
            .collection('inventory')
            .where('userId', isEqualTo: user.uid)
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
            'userId': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'isForSale': true,
            'marketplaceProductId': doc.id,
          };
          await _firestore.collection('inventory').add(inventoryItem);
        }
      }
    } catch (e) {
      // print('InventoryService: Sync error: $e');
    }
  }
}
