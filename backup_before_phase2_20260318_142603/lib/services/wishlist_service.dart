import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Add product to wishlist
  static Future<bool> addToWishlist(String productId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(productId)
          .set({
        'addedAt': FieldValue.serverTimestamp(),
        'productId': productId,
      });

      return true;
    } catch (e) {
      print('Error adding to wishlist: $e');
      return false;
    }
  }

  /// Remove product from wishlist
  static Future<bool> removeFromWishlist(String productId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(productId)
          .delete();

      return true;
    } catch (e) {
      print('Error removing from wishlist: $e');
      return false;
    }
  }

  /// Check if product is in wishlist
  static Future<bool> isInWishlist(String productId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(productId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking wishlist: $e');
      return false;
    }
  }

  /// Toggle wishlist (add if not exists, remove if exists)
  static Future<bool> toggleWishlist(String productId) async {
    final isInList = await isInWishlist(productId);
    
    if (isInList) {
      return await removeFromWishlist(productId);
    } else {
      return await addToWishlist(productId);
    }
  }

  /// Get wishlist count
  static Future<int> getWishlistCount() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 0;

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting wishlist count: $e');
      return 0;
    }
  }
}
