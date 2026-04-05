import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/conversation_model.dart';
import '../models/product_model.dart';
import 'conversation_service.dart';

/// Enhanced chat service with improved functionality
class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConversationService _conversationService = ConversationService();

  /// Start a conversation between buyer and seller
  Future<String> startConversation({
    required Product product,
    required String buyerName,
    String initialMessage = 'Hi! I\'m interested in your product.',
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      if (user.uid == product.sellerId) {
        throw Exception('Cannot start conversation with yourself');
      }

      // Create or get conversation
      final conversationId = await _conversationService.createOrGetConversation(
        productId: product.id,
        productName: product.name,
        buyerId: user.uid,
        buyerName: buyerName,
        sellerId: product.sellerId,
        sellerName: product.sellerName,
      );

      // Send initial message
      await _conversationService.sendMessage(
        conversationId: conversationId,
        receiverId: product.sellerId,
        content: initialMessage,
        type: MessageType.text,
      );

      return conversationId;
    } catch (e) {
      throw Exception('Failed to start conversation: $e');
    }
  }

  /// Send a bid offer
  Future<void> sendBidOffer({
    required String conversationId,
    required double amount,
    required int quantity,
    required String unit,
    String? notes,
  }) async {
    try {
      final conversation =
          await _conversationService.getConversation(conversationId);
      if (conversation == null) throw Exception('Conversation not found');

      final bidMessage = '🏷️ BID OFFER\n'
          '💰 Price: ₹$amount per $unit\n'
          '📦 Quantity: $quantity $unit\n'
          '💵 Total: ₹${(amount * quantity).toStringAsFixed(2)}'
          '${notes != null && notes.isNotEmpty ? '\n📝 $notes' : ''}';

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

  /// Send a message in conversation
  Future<void> sendMessage({
    required String conversationId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    try {
      final conversation =
          await _conversationService.getConversation(conversationId);
      if (conversation == null) throw Exception('Conversation not found');

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final receiverId = user.uid == conversation.buyerId
          ? conversation.sellerId
          : conversation.buyerId;

      await _conversationService.sendMessage(
        conversationId: conversationId,
        receiverId: receiverId,
        content: content,
        type: type,
      );
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get conversation messages
  Stream<List<Message>> getMessages(String conversationId) {
    return _conversationService.getConversationMessages(conversationId);
  }

  /// Get user conversations
  Stream<List<Conversation>> getConversations() {
    return _conversationService.getUserConversations();
  }

  /// Get user conversations (backward compatibility)
  Stream<List<Conversation>> getUserConversations() {
    return _conversationService.getUserConversations();
  }

  /// Get total unread message count for current user
  Stream<int> getUnreadCount() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _conversationService.getUserConversations().map((conversations) {
      return conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
    });
  }

  /// Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    // Note: In production, you might want to soft-delete or archive
    await _firestore.collection('conversations').doc(conversationId).delete();
  }

  /// Mark messages as read
  Future<void> markAsRead(String conversationId) async {
    await _conversationService.markMessagesAsRead(conversationId);
  }
}
