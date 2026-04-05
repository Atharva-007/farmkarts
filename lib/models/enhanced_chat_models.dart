import 'package:cloud_firestore/cloud_firestore.dart';

// Enhanced Enums for WhatsApp-like functionality
enum MessageType {
  text,
  image,
  video,
  audio,
  document,
  location,
  bid,
  system,
  call,
  product
}

enum CallType { audio, video }

enum CallStatus { ringing, answered, ended, declined, missed }

enum BidStatus { pending, accepted, rejected, expired, withdrawn, negotiating }

enum MessageStatus { sent, delivered, read }

enum MediaUploadStatus { uploading, completed, failed }

/// Enhanced Chat Message with WhatsApp-like features
class EnhancedChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String receiverId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final bool isForwarded;
  final String? replyToMessageId;
  final Map<String, dynamic>? metadata;

  // Media-specific fields
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? fileName;
  final int? fileSize;
  final Duration? duration;
  final double? latitude;
  final double? longitude;

  // Bid-specific fields
  final BidOffer? bidOffer;

  // Call-specific fields
  final CallInfo? callInfo;

  EnhancedChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar = '',
    required this.receiverId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.isForwarded = false,
    this.replyToMessageId,
    this.metadata,
    this.mediaUrl,
    this.thumbnailUrl,
    this.fileName,
    this.fileSize,
    this.duration,
    this.latitude,
    this.longitude,
    this.bidOffer,
    this.callInfo,
  });

  factory EnhancedChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return EnhancedChatMessage(
      id: id,
      conversationId: map['conversationId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderAvatar: map['senderAvatar'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MessageStatus.sent,
      ),
      isForwarded: map['isForwarded'] ?? false,
      replyToMessageId: map['replyToMessageId'],
      metadata: map['metadata'],
      mediaUrl: map['mediaUrl'],
      thumbnailUrl: map['thumbnailUrl'],
      fileName: map['fileName'],
      fileSize: map['fileSize'],
      duration: map['duration'] != null
          ? Duration(milliseconds: map['duration'])
          : null,
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      bidOffer:
          map['bidOffer'] != null ? BidOffer.fromMap(map['bidOffer']) : null,
      callInfo:
          map['callInfo'] != null ? CallInfo.fromMap(map['callInfo']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'receiverId': receiverId,
      'content': content,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.name,
      'isForwarded': isForwarded,
      'replyToMessageId': replyToMessageId,
      'metadata': metadata,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'duration': duration?.inMilliseconds,
      'latitude': latitude,
      'longitude': longitude,
      'bidOffer': bidOffer?.toMap(),
      'callInfo': callInfo?.toMap(),
    };
  }
}

/// Enhanced Bid Offer with more details
class BidOffer {
  final String id;
  final double amount;
  final int quantity;
  final String unit;
  final String? notes;
  final DateTime validUntil;
  final BidStatus status;
  final DateTime createdAt;
  final String? responseMessage;
  final Map<String, dynamic>? terms;

  BidOffer({
    required this.id,
    required this.amount,
    required this.quantity,
    required this.unit,
    this.notes,
    required this.validUntil,
    this.status = BidStatus.pending,
    required this.createdAt,
    this.responseMessage,
    this.terms,
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
        (e) => e.name == map['status'],
        orElse: () => BidStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      responseMessage: map['responseMessage'],
      terms: map['terms'],
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
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'responseMessage': responseMessage,
      'terms': terms,
    };
  }

  double get totalAmount => amount * quantity;

  bool get isExpired => DateTime.now().isAfter(validUntil);
}

/// Call Information
class CallInfo {
  final String id;
  final CallType type;
  final CallStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? duration;
  final String callerId;
  final String receiverId;

  CallInfo({
    required this.id,
    required this.type,
    required this.status,
    required this.startTime,
    this.endTime,
    this.duration,
    required this.callerId,
    required this.receiverId,
  });

  factory CallInfo.fromMap(Map<String, dynamic> map) {
    return CallInfo(
      id: map['id'] ?? '',
      type: CallType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CallType.audio,
      ),
      status: CallStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CallStatus.ended,
      ),
      startTime: (map['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (map['endTime'] as Timestamp?)?.toDate(),
      duration: map['duration'] != null
          ? Duration(milliseconds: map['duration'])
          : null,
      callerId: map['callerId'] ?? '',
      receiverId: map['receiverId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'status': status.name,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'duration': duration?.inMilliseconds,
      'callerId': callerId,
      'receiverId': receiverId,
    };
  }
}

/// Enhanced Conversation with more features
class EnhancedConversation {
  final String id;
  final String productId;
  final String productName;
  final String productImageUrl;
  final List<String> productImages;
  final double productPrice;
  final String productUnit;
  final Map<String, dynamic> productDetails;
  final String sellerId;
  final String sellerName;
  final String sellerAvatar;
  final String sellerPhone;
  final String buyerId;
  final String buyerName;
  final String buyerAvatar;
  final String buyerPhone;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isActive;
  final DateTime createdAt;
  final Map<String, dynamic>? settings;

  // Bidding information
  final double? currentHighestBid;
  final int totalBids;
  final List<BidOffer> recentBids;

  // Call information
  final CallInfo? lastCall;

  EnhancedConversation({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImageUrl = '',
    this.productImages = const [],
    required this.productPrice,
    required this.productUnit,
    this.productDetails = const {},
    required this.sellerId,
    required this.sellerName,
    this.sellerAvatar = '',
    this.sellerPhone = '',
    required this.buyerId,
    required this.buyerName,
    this.buyerAvatar = '',
    this.buyerPhone = '',
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isActive = true,
    required this.createdAt,
    this.settings,
    this.currentHighestBid,
    this.totalBids = 0,
    this.recentBids = const [],
    this.lastCall,
  });

  factory EnhancedConversation.fromMap(Map<String, dynamic> map, String id) {
    return EnhancedConversation(
      id: id,
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImageUrl: map['productImageUrl'] ?? '',
      productImages: List<String>.from(map['productImages'] ?? []),
      productPrice: (map['productPrice'] ?? 0).toDouble(),
      productUnit: map['productUnit'] ?? '',
      productDetails: Map<String, dynamic>.from(map['productDetails'] ?? {}),
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      sellerAvatar: map['sellerAvatar'] ?? '',
      sellerPhone: map['sellerPhone'] ?? '',
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? '',
      buyerAvatar: map['buyerAvatar'] ?? '',
      buyerPhone: map['buyerPhone'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime:
          (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: map['unreadCount'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      settings: map['settings'],
      currentHighestBid: map['currentHighestBid']?.toDouble(),
      totalBids: map['totalBids'] ?? 0,
      recentBids: (map['recentBids'] as List<dynamic>?)
              ?.map((e) => BidOffer.fromMap(e))
              .toList() ??
          [],
      lastCall:
          map['lastCall'] != null ? CallInfo.fromMap(map['lastCall']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImageUrl': productImageUrl,
      'productImages': productImages,
      'productPrice': productPrice,
      'productUnit': productUnit,
      'productDetails': productDetails,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerAvatar': sellerAvatar,
      'sellerPhone': sellerPhone,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerAvatar': buyerAvatar,
      'buyerPhone': buyerPhone,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount': unreadCount,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'settings': settings,
      'currentHighestBid': currentHighestBid,
      'totalBids': totalBids,
      'recentBids': recentBids.map((e) => e.toMap()).toList(),
      'lastCall': lastCall?.toMap(),
    };
  }
}

/// Media Upload Progress
class MediaUploadProgress {
  final String id;
  final String fileName;
  final MediaUploadStatus status;
  final double progress;
  final String? error;
  final String? downloadUrl;

  MediaUploadProgress({
    required this.id,
    required this.fileName,
    required this.status,
    this.progress = 0.0,
    this.error,
    this.downloadUrl,
  });
}

/// Typing Indicator
class TypingIndicator {
  final String userId;
  final String userName;
  final DateTime lastTyping;

  TypingIndicator({
    required this.userId,
    required this.userName,
    required this.lastTyping,
  });

  bool get isTyping {
    return DateTime.now().difference(lastTyping).inSeconds < 3;
  }
}
