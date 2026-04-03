// Buyer Interaction Service
// Handles buyer interests, price offers, and bidding functionality

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/marketplace_models.dart';

class BuyerInteractionService {
  static final BuyerInteractionService _instance = BuyerInteractionService._internal();
  factory BuyerInteractionService() => _instance;
  BuyerInteractionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Show interest in a product
  Future<String> showInterest({
    required String productId,
    required String message,
    required int interestedQuantity,
    String contactPreference = 'email',
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final interestData = BuyerInterest(
        id: '', // Will be set by Firestore
        productId: productId,
        buyerId: user.uid,
        buyerName: user.displayName ?? user.email ?? 'Unknown User',
        buyerEmail: user.email ?? '',
        message: message,
        interestedQuantity: interestedQuantity,
        contactPreference: contactPreference,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('buyer_interests')
          .add(interestData.toMap());

      // Update product view/interest count
      await _updateProductInterestCount(productId);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to show interest: $e');
    }
  }

  // Make a price offer
  Future<String> makeOffer({
    required String productId,
    required double offeredPrice,
    required int quantity,
    required String message,
    DateTime? validUntil,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final offerData = PriceOffer(
        id: '', // Will be set by Firestore
        productId: productId,
        buyerId: user.uid,
        buyerName: user.displayName ?? user.email ?? 'Unknown User',
        buyerEmail: user.email ?? '',
        offeredPrice: offeredPrice,
        quantity: quantity,
        message: message,
        status: 'pending',
        validUntil: validUntil,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('price_offers')
          .add(offerData.toMap());

      // Update product offer count
      await _updateProductOfferCount(productId);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to make offer: $e');
    }
  }

  // Get all interests for a product
  Future<List<BuyerInterest>> getProductInterests(String productId) async {
    try {
      final querySnapshot = await _firestore
          .collection('buyer_interests')
          .where('productId', isEqualTo: productId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return BuyerInterest.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error fetching product interests: $e');
      return [];
    }
  }

  // Get all offers for a product
  Future<List<PriceOffer>> getProductOffers(String productId) async {
    try {
      final querySnapshot = await _firestore
          .collection('price_offers')
          .where('productId', isEqualTo: productId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return PriceOffer.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error fetching product offers: $e');
      return [];
    }
  }

  // Get user's interests (as a buyer)
  Future<List<BuyerInterest>> getUserInterests(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('buyer_interests')
          .where('buyerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return BuyerInterest.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error fetching user interests: $e');
      return [];
    }
  }

  // Get user's offers (as a buyer)
  Future<List<PriceOffer>> getUserOffers(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('price_offers')
          .where('buyerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return PriceOffer.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error fetching user offers: $e');
      return [];
    }
  }

  // Respond to an interest (for sellers)
  Future<void> respondToInterest(String interestId, String status, {String? response}) async {
    try {
      await _firestore
          .collection('buyer_interests')
          .doc(interestId)
          .update({
        'status': status,
        'response': response,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to respond to interest: $e');
    }
  }

  // Respond to an offer (for sellers)
  Future<void> respondToOffer(String offerId, String status, {String? response}) async {
    try {
      final updateData = {
        'status': status,
        'respondedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (response != null) {
        updateData['response'] = response;
      }

      await _firestore
          .collection('price_offers')
          .doc(offerId)
          .update(updateData);

      // If offer is accepted, create a transaction
      if (status == 'accepted') {
        await _createTransaction(offerId);
      }
    } catch (e) {
      throw Exception('Failed to respond to offer: $e');
    }
  }

  // Create a transaction when an offer is accepted
  Future<void> _createTransaction(String offerId) async {
    try {
      final offerDoc = await _firestore
          .collection('price_offers')
          .doc(offerId)
          .get();

      if (!offerDoc.exists) return;

      final offerData = offerDoc.data()!;
      final offer = PriceOffer.fromMap({
        'id': offerDoc.id,
        ...offerData,
      });

      // Get product details
      final productDoc = await _firestore
          .collection('products')
          .doc(offer.productId)
          .get();

      if (!productDoc.exists) return;

      final productData = productDoc.data()!;

      final transactionData = MarketplaceTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: offer.productId,
        sellerId: productData['sellerId'],
        buyerId: offer.buyerId,
        offerId: offerId,
        quantity: offer.quantity,
        pricePerUnit: offer.offeredPrice,
        totalAmount: offer.totalValue,
        status: 'confirmed',
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('marketplace_transactions')
          .add(transactionData.toMap());

      // Update product quantity
      final newQuantity = (productData['quantity'] ?? 0) - offer.quantity;
      await _firestore
          .collection('products')
          .doc(offer.productId)
          .update({
        'quantity': newQuantity,
        'isAvailable': newQuantity > 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update selling history
      await _updateSellingHistory(offer.productId, offer.quantity, offer.totalValue);

    } catch (e) {
      print('Error creating transaction: $e');
      throw Exception('Failed to create transaction: $e');
    }
  }

  // Update product interest count
  Future<void> _updateProductInterestCount(String productId) async {
    try {
      final productRef = _firestore.collection('products').doc(productId);
      
      await _firestore.runTransaction((transaction) async {
        final productDoc = await transaction.get(productRef);
        if (productDoc.exists) {
          final currentCount = productDoc.data()?['totalInquiries'] ?? 0;
          transaction.update(productRef, {
            'totalInquiries': currentCount + 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      // Also update selling history
      final sellingHistoryQuery = await _firestore
          .collection('selling_history')
          .where('productId', isEqualTo: productId)
          .get();

      for (final doc in sellingHistoryQuery.docs) {
        await doc.reference.update({
          'totalInquiries': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating interest count: $e');
    }
  }

  // Update product offer count
  Future<void> _updateProductOfferCount(String productId) async {
    try {
      // Update selling history
      final sellingHistoryQuery = await _firestore
          .collection('selling_history')
          .where('productId', isEqualTo: productId)
          .get();

      for (final doc in sellingHistoryQuery.docs) {
        await doc.reference.update({
          'totalOffers': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating offer count: $e');
    }
  }

  // Update selling history when a sale is made
  Future<void> _updateSellingHistory(String productId, int soldQuantity, double revenue) async {
    try {
      final sellingHistoryQuery = await _firestore
          .collection('selling_history')
          .where('productId', isEqualTo: productId)
          .get();

      for (final doc in sellingHistoryQuery.docs) {
        final data = doc.data();
        final currentSoldQuantity = data['soldQuantity'] ?? 0;
        final currentRevenue = (data['totalRevenue'] ?? 0).toDouble();
        final totalQuantity = data['totalQuantity'] ?? 0;

        final newSoldQuantity = currentSoldQuantity + soldQuantity;
        final newRevenue = currentRevenue + revenue;
        final availableQuantity = totalQuantity - newSoldQuantity;

        String status = 'active';
        if (availableQuantity <= 0) {
          status = 'sold_out';
        }

        await doc.reference.update({
          'soldQuantity': newSoldQuantity,
          'availableQuantity': availableQuantity,
          'totalRevenue': newRevenue,
          'status': status,
          'isActive': status == 'active',
          'lastSoldDate': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating selling history: $e');
    }
  }

  // Track product view
  Future<void> trackProductView(String productId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Add view record
      await _firestore.collection('product_views').add({
        'productId': productId,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update product view count
      await _firestore
          .collection('products')
          .doc(productId)
          .update({
        'totalViews': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update selling history view count
      final sellingHistoryQuery = await _firestore
          .collection('selling_history')
          .where('productId', isEqualTo: productId)
          .get();

      for (final doc in sellingHistoryQuery.docs) {
        await doc.reference.update({
          'totalViews': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error tracking product view: $e');
    }
  }

  // Get transactions for a user
  Future<List<MarketplaceTransaction>> getUserTransactions(String userId, {bool asSeller = false}) async {
    try {
      final field = asSeller ? 'sellerId' : 'buyerId';
      final querySnapshot = await _firestore
          .collection('marketplace_transactions')
          .where(field, isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return MarketplaceTransaction.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error fetching user transactions: $e');
      return [];
    }
  }

  // Update transaction status
  Future<void> updateTransactionStatus(String transactionId, String status) async {
    try {
      await _firestore
          .collection('marketplace_transactions')
          .doc(transactionId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        if (status == 'completed') 'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update transaction status: $e');
    }
  }
}