import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Add product to cart
  static Future<bool> addToCart(String productId, {int quantity = 1}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(productId)
          .set({
        'productId': productId,
        'quantity': quantity,
        'addedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      // print('Error adding to cart: $e');
      return false;
    }
  }

  /// Update cart item quantity
  static Future<bool> updateQuantity(String productId, int quantity) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      if (quantity <= 0) {
        return await removeFromCart(productId);
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(productId)
          .update({'quantity': quantity});

      return true;
    } catch (e) {
      // print('Error updating cart quantity: $e');
      return false;
    }
  }

  /// Remove product from cart
  static Future<bool> removeFromCart(String productId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(productId)
          .delete();

      return true;
    } catch (e) {
      // print('Error removing from cart: $e');
      return false;
    }
  }

  /// Check if product is in cart
  static Future<bool> isInCart(String productId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(productId)
          .get();

      return doc.exists;
    } catch (e) {
      // print('Error checking cart: $e');
      return false;
    }
  }

  /// Get cart item quantity
  static Future<int> getCartQuantity(String productId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 0;

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(productId)
          .get();

      if (doc.exists) {
        return doc.data()?['quantity'] ?? 0;
      }
      return 0;
    } catch (e) {
      // print('Error getting cart quantity: $e');
      return 0;
    }
  }

  /// Get total cart item count
  static Future<int> getCartCount() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 0;

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      int total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['quantity'] as int? ?? 1);
      }
      return total;
    } catch (e) {
      // print('Error getting cart count: $e');
      return 0;
    }
  }

  /// Clear all cart items
  static Future<bool> clearCart() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      return true;
    } catch (e) {
      // print('Error clearing cart: $e');
      return false;
    }
  }

  /// Get cart stream for real-time updates
  static Stream<QuerySnapshot> getCartStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .snapshots();
  }
}
