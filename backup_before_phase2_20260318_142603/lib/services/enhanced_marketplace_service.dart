import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../models/conversation_model.dart';
import 'conversation_service.dart';

class EnhancedMarketplaceService {
  static final EnhancedMarketplaceService _instance = EnhancedMarketplaceService._internal();
  factory EnhancedMarketplaceService() => _instance;
  EnhancedMarketplaceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConversationService _conversationService = ConversationService();

  /// Contact seller with enhanced chat functionality
  Future<String> contactSeller({
    required Product product,
    required String buyerName,
    String? initialMessage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      if (user.uid == product.sellerId) {
        throw Exception('Cannot contact yourself');
      }

      // Get or create conversation
      final conversationId = await _conversationService.createOrGetConversation(
        productId: product.id,
        productName: product.name,
        buyerId: user.uid,
        buyerName: buyerName,
        sellerId: product.sellerId,
        sellerName: product.sellerName,
      );

      // Send initial message if provided
      if (initialMessage != null && initialMessage.isNotEmpty) {
        await _conversationService.sendMessage(
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

  /// Send bid offer to seller
  Future<void> sendBidOffer({
    required String conversationId,
    required double bidAmount,
    required int quantity,
    required String unit,
    String? notes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get conversation details
      final conversation = await _conversationService.getConversation(conversationId);
      if (conversation == null) throw Exception('Conversation not found');

      final bidMessage = 'BID OFFER:\n'
          '💰 Amount: ₹$bidAmount per $unit\n'
          '📦 Quantity: $quantity $unit\n'
          '💵 Total: ₹${(bidAmount * quantity).toStringAsFixed(2)}\n'
          '${notes != null && notes.isNotEmpty ? '\n📝 Notes: $notes' : ''}';

      await _conversationService.sendMessage(
        conversationId: conversationId,
        receiverId: conversation.sellerId,
        content: bidMessage,
        type: MessageType.priceQuote,
      );
    } catch (e) {
      throw Exception('Failed to send bid offer: $e');
    }
  }

  /// Get buyer interactions for a product (for seller)
  Future<List<Conversation>> getBuyerInteractions(String productId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final conversations = await _firestore
          .collection('conversations')
          .where('productId', isEqualTo: productId)
          .where('sellerId', isEqualTo: user.uid)
          .orderBy('lastMessageTime', descending: true)
          .get();

      return conversations.docs
          .map((doc) => Conversation.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get buyer interactions: $e');
    }
  }

  /// Get seller's products with interaction counts
  Future<List<Map<String, dynamic>>> getSellerProductsWithInteractions() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get seller's products
      final products = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: user.uid)
          .get();

      List<Map<String, dynamic>> productsWithInteractions = [];

      for (final productDoc in products.docs) {
        final product = Product.fromMap(productDoc.id, productDoc.data());
        
        // Get interaction count for this product
        final conversations = await _firestore
            .collection('conversations')
            .where('productId', isEqualTo: product.id)
            .where('sellerId', isEqualTo: user.uid)
            .get();

        final interactionCount = conversations.docs.length;
        final unreadCount = conversations.docs
            .where((doc) => (doc.data()['unreadCount'] ?? 0) > 0)
            .length;

        productsWithInteractions.add({
          'product': product,
          'interactionCount': interactionCount,
          'unreadCount': unreadCount,
          'conversations': conversations.docs
              .map((doc) => Conversation.fromMap(doc.id, doc.data()))
              .toList(),
        });
      }

      // Sort by interaction count (most active first)
      productsWithInteractions.sort((a, b) => 
          (b['interactionCount'] as int).compareTo(a['interactionCount'] as int));

      return productsWithInteractions;
    } catch (e) {
      throw Exception('Failed to get seller products with interactions: $e');
    }
  }

  /// Get buyer's conversations
  Stream<List<Conversation>> getBuyerConversations() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return _firestore
        .collection('conversations')
        .where('buyerId', isEqualTo: user.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Conversation.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Get seller's conversations
  Stream<List<Conversation>> getSellerConversations() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return _firestore
        .collection('conversations')
        .where('sellerId', isEqualTo: user.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Conversation.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Create notification for user
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    String? productId,
    String? conversationId,
    String type = 'general',
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'productId': productId,
        'conversationId': conversationId,
        'type': type,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      // Silent fail for notifications
      print('Failed to create notification: $e');
    }
  }

  /// Get notifications for user
  Stream<List<Map<String, dynamic>>> getNotifications() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Failed to mark notification as read: $e');
    }
  }

  /// Search products with enhanced filters
  Future<List<Product>> searchProducts({
    String? query,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? location,
    bool? isOrganic,
    int limit = 20,
  }) async {
    try {
      Query queryRef = _firestore.collection('products');

      if (category != null && category.isNotEmpty) {
        queryRef = queryRef.where('category', isEqualTo: category);
      }

      if (isOrganic != null) {
        queryRef = queryRef.where('isOrganic', isEqualTo: isOrganic);
      }

      if (location != null && location.isNotEmpty) {
        queryRef = queryRef.where('location', isGreaterThanOrEqualTo: location)
            .where('location', isLessThan: location + '\uf8ff');
      }

      queryRef = queryRef.limit(limit);

      final snapshot = await queryRef.get();
      List<Product> products = snapshot.docs
          .map((doc) => Product.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      // Apply client-side filters
      if (query != null && query.isNotEmpty) {
        products = products.where((product) =>
            product.name.toLowerCase().contains(query.toLowerCase()) ||
            product.description.toLowerCase().contains(query.toLowerCase()) ||
            product.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase())))
            .toList();
      }

      if (minPrice != null) {
        products = products.where((product) => product.price >= minPrice).toList();
      }

      if (maxPrice != null) {
        products = products.where((product) => product.price <= maxPrice).toList();
      }

      return products;
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  /// Submit price offer (legacy support)
  Future<void> submitPriceOffer({
    required String productId,
    required double offerPrice,
    required int quantity,
    String? message,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('price_offers').add({
        'productId': productId,
        'buyerId': user.uid,
        'offerPrice': offerPrice,
        'quantity': quantity,
        'message': message,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error submitting price offer: $e');
    }
  }

}