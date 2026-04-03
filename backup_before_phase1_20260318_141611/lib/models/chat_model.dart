import 'package:cloud_firestore/cloud_firestore.dart';

// Enums
enum ChatStatus { active, archived, blocked }
enum MessageType { text, image, bid, system }
enum BidStatus { pending, accepted, rejected, expired, withdrawn }
enum NotificationType { message, bid, rating, order, system }

/// Chat conversation model
class ChatConversation {
  final String id;
  final String productId;
  final String productName;
  final String productImageUrl;
  final String sellerId;
  final String sellerName;
  final String buyerId;
  final String buyerName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isActive;
  final ChatStatus status;
  final List<String> participantIds;
  final String lastSenderId;

  ChatConversation({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.sellerId,
    required this.sellerName,
    required this.buyerId,
    required this.buyerName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isActive = true,
    this.status = ChatStatus.active,
    List<String>? participantIds,
    String? lastSenderId,
  }) : participantIds = participantIds ?? [sellerId, buyerId],
       lastSenderId = lastSenderId ?? '';

  factory ChatConversation.fromMap(Map<String, dynamic> map) {
    return ChatConversation(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImageUrl: map['productImageUrl'] ?? '',
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: map['unreadCount'] ?? 0,
      isActive: map['isActive'] ?? true,
      status: ChatStatus.values.firstWhere(
        (e) => e.toString() == 'ChatStatus.${map['status']}',
        orElse: () => ChatStatus.active,
      ),
      participantIds: List<String>.from(map['participantIds'] ?? []),
      lastSenderId: map['lastSenderId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'productImageUrl': productImageUrl,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount': unreadCount,
      'isActive': isActive,
      'status': status.toString().split('.').last,
      'participantIds': participantIds,
      'lastSenderId': lastSenderId,
    };
  }
}

/// Individual chat message
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final MessageType type;
  final String? imageUrl;
  final BidOffer? bidOffer;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.type = MessageType.text,
    this.imageUrl,
    this.bidOffer,
    this.isRead = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      conversationId: map['conversationId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${map['type']}',
        orElse: () => MessageType.text,
      ),
      imageUrl: map['imageUrl'],
      bidOffer: map['bidOffer'] != null ? BidOffer.fromMap(map['bidOffer']) : null,
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.toString().split('.').last,
      'imageUrl': imageUrl,
      'bidOffer': bidOffer?.toMap(),
      'isRead': isRead,
    };
  }
}

/// Bid offer within chat
class BidOffer {
  final String id;
  final double amount;
  final int quantity;
  final String unit;
  final String? notes;
  final DateTime validUntil;
  final BidStatus status;

  BidOffer({
    required this.id,
    required this.amount,
    required this.quantity,
    required this.unit,
    this.notes,
    required this.validUntil,
    this.status = BidStatus.pending,
  });

  factory BidOffer.fromMap(Map<String, dynamic> map) {
    return BidOffer(
      id: map['id'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      unit: map['unit'] ?? '',
      notes: map['notes'],
      validUntil: (map['validUntil'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: BidStatus.values.firstWhere(
        (e) => e.toString() == 'BidStatus.${map['status']}',
        orElse: () => BidStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'quantity': quantity,
      'unit': unit,
      'notes': notes,
      'validUntil': Timestamp.fromDate(validUntil),
      'status': status.toString().split('.').last,
    };
  }
}

/// User rating and review
class UserRating {
  final String id;
  final String userId;
  final String ratedByUserId;
  final String ratedByUserName;
  final double rating;
  final String review;
  final DateTime timestamp;
  final String? transactionId;

  UserRating({
    required this.id,
    required this.userId,
    required this.ratedByUserId,
    required this.ratedByUserName,
    required this.rating,
    required this.review,
    required this.timestamp,
    this.transactionId,
  });

  factory UserRating.fromMap(Map<String, dynamic> map) {
    return UserRating(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      ratedByUserId: map['ratedByUserId'] ?? '',
      ratedByUserName: map['ratedByUserName'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      review: map['review'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      transactionId: map['transactionId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'ratedByUserId': ratedByUserId,
      'ratedByUserName': ratedByUserName,
      'rating': rating,
      'review': review,
      'timestamp': Timestamp.fromDate(timestamp),
      'transactionId': transactionId,
    };
  }
}

/// Notification model
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data = const {},
    required this.timestamp,
    this.isRead = false,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${map['type']}',
        orElse: () => NotificationType.message,
      ),
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.toString().split('.').last,
      'data': data,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }
}