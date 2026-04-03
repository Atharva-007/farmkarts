import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import '../models/conversation_model.dart';

class ConversationService {
  static final ConversationService _instance = ConversationService._internal();
  factory ConversationService() => _instance;
  ConversationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create a new conversation or get existing one
  Future<String> createOrGetConversation({
    required String productId,
    required String productName,
    required String buyerId,
    required String buyerName,
    required String sellerId,
    required String sellerName,
  }) async {
    try {
      // Check if conversation already exists
      final existingConversation = await _firestore
          .collection('conversations')
          .where('productId', isEqualTo: productId)
          .where('buyerId', isEqualTo: buyerId)
          .where('sellerId', isEqualTo: sellerId)
          .limit(1)
          .get();

      if (existingConversation.docs.isNotEmpty) {
        return existingConversation.docs.first.id;
      }

      // Create new conversation with participants field
      final conversation = Conversation(
        id: '',
        productId: productId,
        productName: productName,
        buyerId: buyerId,
        buyerName: buyerName,
        sellerId: sellerId,
        sellerName: sellerName,
        lastMessage: 'Conversation started',
        lastMessageTime: DateTime.now(),
        lastMessageSenderId: buyerId,
        createdAt: DateTime.now(),
      );

      // Add participants field for security rules
      final conversationData = conversation.toMap();
      conversationData['participants'] = [buyerId, sellerId];

      final docRef = await _firestore
          .collection('conversations')
          .add(conversationData);

      // Add initial system message
      await sendMessage(
        conversationId: docRef.id,
        receiverId: sellerId,
        content: 'New inquiry about $productName',
        type: MessageType.system,
      );

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  // Send a message
  Future<String> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
    File? imageFile,
    Uint8List? imageBytes,
    String? fileName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      String? imageUrl;
      String? fileUrl;

      // Upload image if provided
      if (type == MessageType.image && (imageFile != null || imageBytes != null)) {
        imageUrl = await _uploadMessageImage(
          conversationId: conversationId,
          imageFile: imageFile,
          imageBytes: imageBytes,
          fileName: fileName ?? 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      // Upload file if provided
      if (type == MessageType.file && (imageFile != null || imageBytes != null)) {
        fileUrl = await _uploadMessageFile(
          conversationId: conversationId,
          file: imageFile,
          fileBytes: imageBytes,
          fileName: fileName ?? 'file_${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      final message = Message(
        id: '',
        conversationId: conversationId,
        senderId: user.uid,
        senderName: user.displayName ?? user.email?.split('@')[0] ?? 'User',
        receiverId: receiverId,
        content: content,
        type: type,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
        fileUrl: fileUrl,
        fileName: fileName,
      );

      // Add message to Firestore
      final messageRef = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add(message.toMap());

      // Update conversation last message
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .update({
        'lastMessage': _getDisplayContent(message),
        'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
        'lastMessageSenderId': user.uid,
        'unreadCount': FieldValue.increment(1),
      });

      // Update unread count for receiver
      await _updateUnreadCount(conversationId, receiverId, increment: true);

      return messageRef.id;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get conversations for current user (improved query to fetch both buyer and seller conversations)
  Stream<List<Conversation>> getUserConversations() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Use participants array to get all conversations for current user
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: user.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Add proper unread count handling
        final unreadCount = _getUnreadCountForUser(doc.id, user.uid);
        data['unreadCount'] = unreadCount;
        return Conversation.fromMap(doc.id, data);
      }).toList();
    });
  }

  // Get messages for a conversation
  Stream<List<Message>> getConversationMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Message.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get unread messages
      final unreadMessages = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('receiverId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      // Batch update
      final batch = _firestore.batch();
      
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      // Reset unread count
      await _updateUnreadCount(conversationId, user.uid, reset: true);
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Get conversation by ID
  Future<Conversation?> getConversation(String conversationId) async {
    try {
      final doc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();

      if (doc.exists) {
        return Conversation.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get conversation: $e');
    }
  }

  // Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Delete all messages in the conversation
      final messages = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      
      for (final doc in messages.docs) {
        batch.delete(doc.reference);
      }

      // Delete conversation
      batch.delete(_firestore.collection('conversations').doc(conversationId));
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }

  // Upload message image
  Future<String> _uploadMessageImage({
    required String conversationId,
    File? imageFile,
    Uint8List? imageBytes,
    required String fileName,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage
          .ref()
          .child('chat_images')
          .child(conversationId)
          .child('${timestamp}_$fileName');

      UploadTask uploadTask;
      if (imageBytes != null) {
        uploadTask = ref.putData(imageBytes);
      } else if (imageFile != null) {
        uploadTask = ref.putFile(imageFile);
      } else {
        throw Exception('No image data provided');
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Upload message file
  Future<String> _uploadMessageFile({
    required String conversationId,
    File? file,
    Uint8List? fileBytes,
    required String fileName,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage
          .ref()
          .child('chat_files')
          .child(conversationId)
          .child('${timestamp}_$fileName');

      UploadTask uploadTask;
      if (fileBytes != null) {
        uploadTask = ref.putData(fileBytes);
      } else if (file != null) {
        uploadTask = ref.putFile(file);
      } else {
        throw Exception('No file data provided');
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  // Update unread count
  Future<void> _updateUnreadCount(
    String conversationId,
    String userId, {
    bool increment = false,
    bool reset = false,
  }) async {
    try {
      final userConversationRef = _firestore
          .collection('user_conversations')
          .doc(userId)
          .collection('conversations')
          .doc(conversationId);

      if (reset) {
        await userConversationRef.set({'unreadCount': 0}, SetOptions(merge: true));
      } else if (increment) {
        await userConversationRef.set(
          {'unreadCount': FieldValue.increment(1)},
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      print('Error updating unread count: $e');
    }
  }

  // Get unread count for specific user in conversation
  int _getUnreadCountForUser(String conversationId, String userId) {
    // This is a simplified version - in production you'd want to use a more efficient method
    // For now, return 0 and handle unread counts in the UI
    return 0;
  }

  // Send bid offer message
  Future<void> sendBidOffer({
    required String conversationId,
    required double bidAmount,
    required int quantity,
    required String unit,
    String? message,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final conversation = await getConversation(conversationId);
      if (conversation == null) throw Exception('Conversation not found');

      final receiverId = user.uid == conversation.buyerId ? conversation.sellerId : conversation.buyerId;
      
      final bidContent = '🏷️ **BID OFFER**\n\n'
          '💰 **Price**: ₹${bidAmount.toStringAsFixed(2)} per $unit\n'
          '📦 **Quantity**: $quantity $unit\n'
          '💵 **Total Amount**: ₹${(bidAmount * quantity).toStringAsFixed(2)}\n'
          '${message != null && message.isNotEmpty ? '\n📝 **Message**: $message' : ''}';

      await sendMessage(
        conversationId: conversationId,
        receiverId: receiverId,
        content: bidContent,
        type: MessageType.priceQuote,
      );
    } catch (e) {
      throw Exception('Failed to send bid offer: $e');
    }
  }

  // Get display content for different message types
  String _getDisplayContent(Message message) {
    switch (message.type) {
      case MessageType.text:
        return message.content;
      case MessageType.image:
        return '📷 Photo';
      case MessageType.file:
        return '📎 ${message.fileName ?? 'File'}';
      case MessageType.system:
        return message.content;
      case MessageType.orderUpdate:
        return '📦 Order Update';
      case MessageType.priceQuote:
        return '💰 Price Quote';
      default:
        return message.content;
    }
  }

  // Search conversations (improved)
  Future<List<Conversation>> searchConversations(String query) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get conversations where user is buyer or seller
      final buyerConversations = await _firestore
          .collection('conversations')
          .where('buyerId', isEqualTo: user.uid)
          .get();

      final sellerConversations = await _firestore
          .collection('conversations')
          .where('sellerId', isEqualTo: user.uid)
          .get();

      // Merge and deduplicate results
      final allDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      allDocs.addAll(buyerConversations.docs);
      
      // Add seller conversations that are not already included
      for (final doc in sellerConversations.docs) {
        if (!allDocs.any((existing) => existing.id == doc.id)) {
          allDocs.add(doc);
        }
      }

      return allDocs
          .map((doc) => Conversation.fromMap(doc.id, doc.data()))
          .where((conversation) =>
              conversation.productName.toLowerCase().contains(query.toLowerCase()) ||
              conversation.buyerName.toLowerCase().contains(query.toLowerCase()) ||
              conversation.sellerName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search conversations: $e');
    }
  }

  // Get total unread count for user
  Stream<int> getTotalUnreadCount() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('user_conversations')
        .doc(user.uid)
        .collection('conversations')
        .snapshots()
        .map((snapshot) {
      int totalUnread = 0;
      for (final doc in snapshot.docs) {
        totalUnread += (doc.data()['unreadCount'] ?? 0) as int;
      }
      return totalUnread;
    });
  }

  // Contact seller method for marketplace integration
  Future<String> contactSeller({
    required String sellerId,
    required String productId,
    String? productName,
    String? sellerName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get current user info
      final buyerId = user.uid;
      final buyerName = user.displayName ?? user.email?.split('@')[0] ?? 'Buyer';

      // Get product info if not provided
      String finalProductName = productName ?? 'Product';
      String finalSellerName = sellerName ?? 'Seller';

      // Try to get product details from Firestore if available
      if (productName == null || sellerName == null) {
        try {
          final productDoc = await _firestore
              .collection('products')
              .doc(productId)
              .get();

          if (productDoc.exists) {
            final productData = productDoc.data()!;
            finalProductName = productData['name'] ?? productData['title'] ?? 'Product';
            
            // Try to get seller name from user document
            if (sellerName == null) {
              final sellerDoc = await _firestore
                  .collection('users')
                  .doc(sellerId)
                  .get();
              
              if (sellerDoc.exists) {
                final sellerData = sellerDoc.data()!;
                finalSellerName = sellerData['displayName'] ?? sellerData['fullName'] ?? 'Seller';
              }
            }
          }
        } catch (e) {
          // Continue with provided or default values if Firestore lookup fails
          print('Could not fetch product/seller details: $e');
        }
      }

      // Create or get existing conversation
      return await createOrGetConversation(
        productId: productId,
        productName: finalProductName,
        buyerId: buyerId,
        buyerName: buyerName,
        sellerId: sellerId,
        sellerName: finalSellerName,
      );
    } catch (e) {
      throw Exception('Failed to contact seller: $e');
    }
  }
}