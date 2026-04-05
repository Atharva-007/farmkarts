import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/enhanced_chat_models.dart';
import '../models/product_model.dart';
import '../utils/media_service.dart';

class EnhancedChatService {
  static final EnhancedChatService _instance = EnhancedChatService._internal();
  factory EnhancedChatService() => _instance;
  EnhancedChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MediaService _mediaService = MediaService();

  /// Create or get enhanced conversation
  Future<String> createOrGetEnhancedConversation({
    required Product product,
    required String buyerName,
    String buyerAvatar = '',
    String buyerPhone = '',
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final conversationId = '${product.id}_${user.uid}';

      // Check if conversation exists
      final conversationDoc = await _firestore
          .collection('enhanced_conversations')
          .doc(conversationId)
          .get();

      if (!conversationDoc.exists) {
        // Create new conversation
        final conversation = EnhancedConversation(
          id: conversationId,
          productId: product.id,
          productName: product.name,
          productImageUrl:
              product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
          productImages: product.imageUrls,
          productPrice: product.price,
          productUnit: product.unit,
          productDetails: {
            'description': product.description,
            'category': product.category,
            'location': product.location,
            'quantity': product.quantity,
          },
          sellerId: product.sellerId,
          sellerName: product.sellerName,
          sellerAvatar: '', // Add from user profile
          sellerPhone: '', // Add from user profile
          buyerId: user.uid,
          buyerName: buyerName,
          buyerAvatar: buyerAvatar,
          buyerPhone: buyerPhone,
          lastMessage: 'Conversation started',
          lastMessageTime: DateTime.now(),
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('enhanced_conversations')
            .doc(conversationId)
            .set(conversation.toMap());
      }

      return conversationId;
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  /// Send enhanced message
  Future<void> sendEnhancedMessage({
    required String conversationId,
    required String content,
    required MessageType type,
    required String receiverId,
    String? mediaUrl,
    String? thumbnailUrl,
    String? fileName,
    int? fileSize,
    Duration? duration,
    double? latitude,
    double? longitude,
    BidOffer? bidOffer,
    CallInfo? callInfo,
    String? replyToMessageId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get conversation details
      final conversationDoc = await _firestore
          .collection('enhanced_conversations')
          .doc(conversationId)
          .get();

      if (!conversationDoc.exists) {
        throw Exception('Conversation not found');
      }

      final conversation = EnhancedConversation.fromMap(
        conversationDoc.data()!,
        conversationDoc.id,
      );

      // Determine receiverId if not provided
      final actualReceiverId = receiverId.isNotEmpty
          ? receiverId
          : (user.uid == conversation.buyerId
              ? conversation.sellerId
              : conversation.buyerId);

      // Create message
      final messageId = _firestore
          .collection('enhanced_messages')
          .doc(conversationId)
          .collection('messages')
          .doc()
          .id;

      final message = EnhancedChatMessage(
        id: messageId,
        conversationId: conversationId,
        senderId: user.uid,
        senderName: user.displayName ?? user.email ?? 'User',
        senderAvatar: '', // Add from user profile
        receiverId: actualReceiverId,
        content: content,
        type: type,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
        mediaUrl: mediaUrl,
        thumbnailUrl: thumbnailUrl,
        fileName: fileName,
        fileSize: fileSize,
        duration: duration,
        latitude: latitude,
        longitude: longitude,
        bidOffer: bidOffer,
        callInfo: callInfo,
        replyToMessageId: replyToMessageId,
      );

      // Save message
      await _firestore
          .collection('enhanced_messages')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());

      // Update conversation
      await _updateConversationLastMessage(conversationId, content, type);

      // Update bid information if it's a bid message
      if (bidOffer != null) {
        await _updateBidInformation(conversationId, bidOffer);
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Send media message
  Future<void> sendMediaMessage({
    required String conversationId,
    required File file,
    required MessageType type,
    String? caption,
    Function(double)? onProgress,
  }) async {
    try {
      // Upload file
      final mediaUrl = await _mediaService.uploadFile(
        file,
        conversationId,
        type,
        onProgress: onProgress,
      );

      String? thumbnailUrl;
      Duration? duration;
      int fileSize = await file.length();

      // Generate thumbnail for videos
      if (type == MessageType.video) {
        thumbnailUrl = await _mediaService.generateVideoThumbnail(file.path);
      }

      // Send message
      await sendEnhancedMessage(
        conversationId: conversationId,
        content: caption ?? '',
        type: type,
        receiverId: '', // Will be determined in the method
        mediaUrl: mediaUrl,
        thumbnailUrl: thumbnailUrl,
        fileName: file.path.split('/').last,
        fileSize: fileSize,
        duration: duration,
      );
    } catch (e) {
      throw Exception('Failed to send media: $e');
    }
  }

  /// Send bid offer
  Future<void> sendBidOffer({
    required String conversationId,
    required double amount,
    required int quantity,
    required String unit,
    String? notes,
    Map<String, dynamic>? terms,
    DateTime? validUntil,
  }) async {
    try {
      final bidOffer = BidOffer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        quantity: quantity,
        unit: unit,
        notes: notes,
        validUntil: validUntil ?? DateTime.now().add(Duration(days: 7)),
        status: BidStatus.pending,
        createdAt: DateTime.now(),
        terms: terms,
      );

      final content = '🏷️ BID OFFER\n'
          '💰 Price: ₹$amount per $unit\n'
          '📦 Quantity: $quantity $unit\n'
          '💵 Total: ₹${amount * quantity}\n'
          '${notes != null ? "\n📝 Notes: $notes" : ""}\n'
          '⏰ Valid until: ${_formatDate(bidOffer.validUntil)}';

      await sendEnhancedMessage(
        conversationId: conversationId,
        content: content,
        type: MessageType.bid,
        receiverId: '', // Will be determined in the method
        bidOffer: bidOffer,
      );
    } catch (e) {
      throw Exception('Failed to send bid: $e');
    }
  }

  /// Record call
  Future<void> recordCall({
    required String conversationId,
    required CallType callType,
    required String receiverId,
    CallStatus status = CallStatus.ended,
    Duration? duration,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final callInfo = CallInfo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: callType,
        status: status,
        startTime: DateTime.now().subtract(duration ?? Duration.zero),
        endTime: DateTime.now(),
        duration: duration,
        callerId: user.uid,
        receiverId: receiverId,
      );

      final content =
          callType == CallType.video ? '📹 Video call' : '📞 Voice call';

      await sendEnhancedMessage(
        conversationId: conversationId,
        content: content,
        type: MessageType.call,
        receiverId: receiverId,
        callInfo: callInfo,
      );

      // Update conversation with call info
      await _firestore
          .collection('enhanced_conversations')
          .doc(conversationId)
          .update({
        'lastCall': callInfo.toMap(),
      });
    } catch (e) {
      throw Exception('Failed to record call: $e');
    }
  }

  /// Get enhanced messages stream
  Stream<List<EnhancedChatMessage>> getEnhancedMessages(String conversationId) {
    return _firestore
        .collection('enhanced_messages')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EnhancedChatMessage.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get enhanced conversation
  Future<EnhancedConversation?> getEnhancedConversation(
      String conversationId) async {
    try {
      final doc = await _firestore
          .collection('enhanced_conversations')
          .doc(conversationId)
          .get();

      if (doc.exists) {
        return EnhancedConversation.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get conversation: $e');
    }
  }

  /// Get enhanced conversation stream
  Stream<EnhancedConversation?> getEnhancedConversationStream(
      String conversationId) {
    return _firestore
        .collection('enhanced_conversations')
        .doc(conversationId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return EnhancedConversation.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  /// Update message status
  Future<void> updateMessageStatus(
    String conversationId,
    String messageId,
    MessageStatus status,
  ) async {
    try {
      await _firestore
          .collection('enhanced_messages')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
        'status': status.name,
      });
    } catch (e) {
      throw Exception('Failed to update message status: $e');
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final messagesQuery = await _firestore
          .collection('enhanced_messages')
          .doc(conversationId)
          .collection('messages')
          .where('receiverId', isEqualTo: user.uid)
          .where('status', isNotEqualTo: MessageStatus.read.name)
          .get();

      final batch = _firestore.batch();

      for (final doc in messagesQuery.docs) {
        batch.update(doc.reference, {'status': MessageStatus.read.name});
      }

      await batch.commit();

      // Update conversation unread count
      await _firestore
          .collection('enhanced_conversations')
          .doc(conversationId)
          .update({'unreadCount': 0});
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  /// Update typing status
  Future<void> updateTypingStatus(String conversationId, bool isTyping) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      if (isTyping) {
        await _firestore
            .collection('typing_indicators')
            .doc('${conversationId}_${user.uid}')
            .set({
          'userId': user.uid,
          'userName': user.displayName ?? user.email ?? 'User',
          'lastTyping': Timestamp.now(),
        });
      } else {
        await _firestore
            .collection('typing_indicators')
            .doc('${conversationId}_${user.uid}')
            .delete();
      }
    } catch (e) {
      // print('Failed to update typing status: $e');
    }
  }

  /// Get typing indicators
  Stream<List<TypingIndicator>> getTypingIndicators(String conversationId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('typing_indicators')
        .where('conversationId', isEqualTo: conversationId)
        .where('userId', isNotEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return TypingIndicator(
              userId: data['userId'],
              userName: data['userName'],
              lastTyping: (data['lastTyping'] as Timestamp).toDate(),
            );
          })
          .where((indicator) => indicator.isTyping)
          .toList();
    });
  }

  /// Private helper methods
  Future<void> _updateConversationLastMessage(
    String conversationId,
    String content,
    MessageType type,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    String displayMessage = content;
    if (type == MessageType.image) displayMessage = '📷 Photo';
    if (type == MessageType.video) displayMessage = '🎥 Video';
    if (type == MessageType.audio) displayMessage = '🎵 Audio';
    if (type == MessageType.document) displayMessage = '📄 Document';
    if (type == MessageType.location) displayMessage = '📍 Location';
    if (type == MessageType.bid) displayMessage = '💰 Bid Offer';
    if (type == MessageType.call) displayMessage = content;

    await _firestore
        .collection('enhanced_conversations')
        .doc(conversationId)
        .update({
      'lastMessage': displayMessage,
      'lastMessageTime': Timestamp.now(),
    });
  }

  Future<void> _updateBidInformation(
    String conversationId,
    BidOffer bidOffer,
  ) async {
    try {
      final conversationRef =
          _firestore.collection('enhanced_conversations').doc(conversationId);

      final conversationDoc = await conversationRef.get();
      if (!conversationDoc.exists) return;

      final conversation = EnhancedConversation.fromMap(
        conversationDoc.data()!,
        conversationDoc.id,
      );

      final currentHighest = conversation.currentHighestBid ?? 0.0;
      final newHighest =
          bidOffer.amount > currentHighest ? bidOffer.amount : currentHighest;

      final updatedBids =
          [...conversation.recentBids, bidOffer].take(10).toList();

      await conversationRef.update({
        'currentHighestBid': newHighest,
        'totalBids': conversation.totalBids + 1,
        'recentBids': updatedBids.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      // print('Failed to update bid information: $e');
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Response to bid
  Future<void> respondToBid({
    required String conversationId,
    required String bidId,
    required BidStatus status,
    String? responseMessage,
  }) async {
    try {
      // Update bid status in conversation
      final conversationRef =
          _firestore.collection('enhanced_conversations').doc(conversationId);

      final conversationDoc = await conversationRef.get();
      if (!conversationDoc.exists) return;

      final conversation = EnhancedConversation.fromMap(
        conversationDoc.data()!,
        conversationDoc.id,
      );

      final updatedBids = conversation.recentBids.map((bid) {
        if (bid.id == bidId) {
          return BidOffer(
            id: bid.id,
            amount: bid.amount,
            quantity: bid.quantity,
            unit: bid.unit,
            notes: bid.notes,
            validUntil: bid.validUntil,
            status: status,
            createdAt: bid.createdAt,
            responseMessage: responseMessage,
            terms: bid.terms,
          );
        }
        return bid;
      }).toList();

      await conversationRef.update({
        'recentBids': updatedBids.map((e) => e.toMap()).toList(),
      });

      // Send response message
      String content = '';
      switch (status) {
        case BidStatus.accepted:
          content = '✅ Bid accepted!';
          break;
        case BidStatus.rejected:
          content = '❌ Bid declined.';
          break;
        case BidStatus.negotiating:
          content = '💬 Let\'s negotiate.';
          break;
        default:
          content = responseMessage ?? 'Bid status updated';
      }

      await sendEnhancedMessage(
        conversationId: conversationId,
        content: content,
        type: MessageType.system,
        receiverId: '', // Will be determined in the method
      );
    } catch (e) {
      throw Exception('Failed to respond to bid: $e');
    }
  }
}
