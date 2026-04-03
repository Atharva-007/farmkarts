// Enhanced Marketplace Models for FarmKart
// Supports selling history, buyer interests, price offers, and transactions

import 'product_model.dart';

class SellingHistoryItem {
  final String id;
  final String productId;
  final String productName;
  final String sellerId;
  final String sellerName;
  final String category;
  final double initialPrice;
  final double currentPrice;
  final int totalQuantity;
  final int soldQuantity;
  final int availableQuantity;
  final String status; // 'active', 'sold_out', 'expired', 'paused'
  final String imageUrl;
  final DateTime listedDate;
  final DateTime? lastSoldDate;
  final double totalRevenue;
  final int totalInquiries;
  final int totalViews;
  final bool isActive;
  final Product? currentProductData;
  final PerformanceMetrics? performanceMetrics;

  SellingHistoryItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sellerId,
    required this.sellerName,
    required this.category,
    required this.initialPrice,
    required this.currentPrice,
    required this.totalQuantity,
    required this.soldQuantity,
    required this.availableQuantity,
    required this.status,
    this.imageUrl = '',
    required this.listedDate,
    this.lastSoldDate,
    required this.totalRevenue,
    required this.totalInquiries,
    required this.totalViews,
    required this.isActive,
    this.currentProductData,
    this.performanceMetrics,
  });

  factory SellingHistoryItem.fromMap(Map<String, dynamic> map) {
    return SellingHistoryItem(
      id: map['id']?.toString() ?? '',
      productId: map['productId']?.toString() ?? '',
      productName: map['productName']?.toString() ?? '',
      sellerId: map['sellerId']?.toString() ?? '',
      sellerName: map['sellerName']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      initialPrice: (map['initialPrice'] ?? map['originalPrice'] ?? 0).toDouble(),
      currentPrice: (map['currentPrice'] ?? 0).toDouble(),
      totalQuantity: (map['totalQuantity'] ?? map['originalQuantity'] ?? 0) is int 
          ? (map['totalQuantity'] ?? map['originalQuantity'] ?? 0)
          : int.tryParse((map['totalQuantity'] ?? map['originalQuantity'] ?? 0).toString()) ?? 0,
      soldQuantity: (map['soldQuantity'] ?? 0) is int 
          ? map['soldQuantity'] 
          : int.tryParse(map['soldQuantity'].toString()) ?? 0,
      availableQuantity: (map['availableQuantity'] ?? map['currentQuantity'] ?? 0) is int 
          ? (map['availableQuantity'] ?? map['currentQuantity'] ?? 0)
          : int.tryParse((map['availableQuantity'] ?? map['currentQuantity'] ?? 0).toString()) ?? 0,
      status: map['status']?.toString() ?? 'active',
      imageUrl: map['imageUrl']?.toString() ?? '',
      listedDate: BuyerInterest._parseDateTime(map['listedDate']),
      lastSoldDate: map['lastSoldDate'] != null ? BuyerInterest._parseDateTime(map['lastSoldDate']) : null,
      totalRevenue: (map['totalRevenue'] ?? 0).toDouble(),
      totalInquiries: (map['totalInquiries'] ?? 0) is int 
          ? map['totalInquiries'] 
          : int.tryParse(map['totalInquiries'].toString()) ?? 0,
      totalViews: (map['totalViews'] ?? 0) is int 
          ? map['totalViews'] 
          : int.tryParse(map['totalViews'].toString()) ?? 0,
      isActive: map['isActive'] ?? true,
      currentProductData: map['currentProductData'] != null 
        ? Product.fromMap(Map<String, dynamic>.from(map['currentProductData']))
        : null,
      performanceMetrics: map['performanceMetrics'] != null
        ? PerformanceMetrics.fromMap(Map<String, dynamic>.from(map['performanceMetrics']))
        : null,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    // Handle Firestore Timestamp
    if (value.runtimeType.toString().contains('Timestamp')) {
      return (value as dynamic).toDate();
    }
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'category': category,
      'initialPrice': initialPrice,
      'currentPrice': currentPrice,
      'totalQuantity': totalQuantity,
      'soldQuantity': soldQuantity,
      'availableQuantity': availableQuantity,
      'status': status,
      'imageUrl': imageUrl,
      'listedDate': listedDate.toIso8601String(),
      'lastSoldDate': lastSoldDate?.toIso8601String(),
      'totalRevenue': totalRevenue,
      'totalInquiries': totalInquiries,
      'totalViews': totalViews,
      'isActive': isActive,
      'currentProductData': currentProductData?.toMap(),
      'performanceMetrics': performanceMetrics?.toMap(),
    };
  }
}

class PerformanceMetrics {
  final int daysListed;
  final double conversionRate;
  final double avgRevenuePerDay;
  final double sellThroughRate;
  final int totalOffers;
  final int totalInterests;

  PerformanceMetrics({
    required this.daysListed,
    required this.conversionRate,
    required this.avgRevenuePerDay,
    required this.sellThroughRate,
    required this.totalOffers,
    required this.totalInterests,
  });

  factory PerformanceMetrics.fromMap(Map<String, dynamic> map) {
    return PerformanceMetrics(
      daysListed: map['daysListed'] ?? 0,
      conversionRate: (map['conversionRate'] ?? 0).toDouble(),
      avgRevenuePerDay: (map['avgRevenuePerDay'] ?? 0).toDouble(),
      sellThroughRate: (map['sellThroughRate'] ?? 0).toDouble(),
      totalOffers: map['totalOffers'] ?? 0,
      totalInterests: map['totalInterests'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'daysListed': daysListed,
      'conversionRate': conversionRate,
      'avgRevenuePerDay': avgRevenuePerDay,
      'sellThroughRate': sellThroughRate,
      'totalOffers': totalOffers,
      'totalInterests': totalInterests,
    };
  }
}

class BuyerInterest {
  final String id;
  final String productId;
  final String buyerId;
  final String buyerName;
  final String buyerEmail;
  final String message;
  final int interestedQuantity;
  final String contactPreference; // 'email', 'phone', 'chat'
  final String status; // 'pending', 'contacted', 'converted', 'declined'
  final DateTime createdAt;

  BuyerInterest({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.buyerName,
    required this.buyerEmail,
    required this.message,
    required this.interestedQuantity,
    required this.contactPreference,
    required this.status,
    required this.createdAt,
  });

  factory BuyerInterest.fromMap(Map<String, dynamic> map) {
    return BuyerInterest(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? 'Unknown Buyer',
      buyerEmail: map['buyerEmail'] ?? '',
      message: map['message'] ?? '',
      interestedQuantity: (map['interestedQuantity'] ?? 1) is int 
          ? map['interestedQuantity'] 
          : int.tryParse(map['interestedQuantity'].toString()) ?? 1,
      contactPreference: map['contactPreference'] ?? 'email',
      status: map['status'] ?? 'pending',
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    // Handle Firestore Timestamp
    if (value.runtimeType.toString().contains('Timestamp')) {
      return (value as dynamic).toDate();
    }
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerEmail': buyerEmail,
      'message': message,
      'interestedQuantity': interestedQuantity,
      'contactPreference': contactPreference,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class PriceOffer {
  final String id;
  final String productId;
  final String buyerId;
  final String buyerName;
  final String buyerEmail;
  final double offeredPrice;
  final int quantity;
  final String message;
  final String status; // 'pending', 'accepted', 'rejected', 'expired'
  final DateTime? validUntil;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? response;

  PriceOffer({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.buyerName,
    required this.buyerEmail,
    required this.offeredPrice,
    required this.quantity,
    required this.message,
    required this.status,
    this.validUntil,
    required this.createdAt,
    this.respondedAt,
    this.response,
  });

  factory PriceOffer.fromMap(Map<String, dynamic> map) {
    return PriceOffer(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? 'Unknown Buyer',
      buyerEmail: map['buyerEmail'] ?? '',
      offeredPrice: (map['offeredPrice'] ?? 0).toDouble(),
      quantity: (map['quantity'] ?? 1) is int 
          ? map['quantity'] 
          : int.tryParse(map['quantity'].toString()) ?? 1,
      message: map['message'] ?? '',
      status: map['status'] ?? 'pending',
      validUntil: map['validUntil'] != null 
        ? BuyerInterest._parseDateTime(map['validUntil'])
        : null,
      createdAt: BuyerInterest._parseDateTime(map['createdAt']),
      respondedAt: map['respondedAt'] != null
        ? BuyerInterest._parseDateTime(map['respondedAt'])
        : null,
      response: map['response'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerEmail': buyerEmail,
      'offeredPrice': offeredPrice,
      'quantity': quantity,
      'message': message,
      'status': status,
      'validUntil': validUntil?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'response': response,
    };
  }

  bool get isExpired {
    if (validUntil == null) return false;
    return DateTime.now().isAfter(validUntil!);
  }

  double get totalValue => offeredPrice * quantity;
}

class MarketplaceTransaction {
  final String id;
  final String productId;
  final String sellerId;
  final String buyerId;
  final String offerId;
  final int quantity;
  final double pricePerUnit;
  final double totalAmount;
  final String status; // 'confirmed', 'processing', 'shipped', 'delivered', 'completed', 'cancelled'
  final DateTime createdAt;
  final DateTime? completedAt;

  MarketplaceTransaction({
    required this.id,
    required this.productId,
    required this.sellerId,
    required this.buyerId,
    required this.offerId,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  factory MarketplaceTransaction.fromMap(Map<String, dynamic> map) {
    return MarketplaceTransaction(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      offerId: map['offerId'] ?? '',
      quantity: (map['quantity'] ?? 0) is int 
          ? map['quantity'] 
          : int.tryParse(map['quantity'].toString()) ?? 0,
      pricePerUnit: (map['pricePerUnit'] ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      status: map['status'] ?? 'confirmed',
      createdAt: BuyerInterest._parseDateTime(map['createdAt']),
      completedAt: map['completedAt'] != null
        ? BuyerInterest._parseDateTime(map['completedAt'])
        : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'offerId': offerId,
      'quantity': quantity,
      'pricePerUnit': pricePerUnit,
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}

class UserStatistics {
  final String userId;
  final int totalProducts;
  final int activeProducts;
  final int totalViews;
  final int totalInquiries;
  final double totalRevenue;
  final int totalSales;
  final int totalSold;
  final double averageRating;
  final int totalReviews;
  final String responseTime;
  final double completionRate;
  final DateTime joinDate;
  final DateTime lastActive;

  UserStatistics({
    required this.userId,
    required this.totalProducts,
    required this.activeProducts,
    required this.totalViews,
    required this.totalInquiries,
    required this.totalRevenue,
    required this.totalSales,
    required this.totalSold,
    required this.averageRating,
    required this.totalReviews,
    this.responseTime = '0 hours',
    this.completionRate = 0.0,
    required this.joinDate,
    required this.lastActive,
  });

  factory UserStatistics.fromMap(Map<String, dynamic> map) {
    return UserStatistics(
      userId: map['userId'] ?? '',
      totalProducts: map['totalProducts'] ?? 0,
      activeProducts: map['activeProducts'] ?? 0,
      totalViews: map['totalViews'] ?? 0,
      totalInquiries: map['totalInquiries'] ?? 0,
      totalRevenue: (map['totalRevenue'] ?? 0).toDouble(),
      totalSales: map['totalSales'] ?? 0,
      totalSold: map['totalSold'] ?? 0,
      averageRating: (map['averageRating'] ?? 0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      responseTime: map['responseTime'] ?? '0 hours',
      completionRate: (map['completionRate'] ?? 0).toDouble(),
      joinDate: map['joinDate'] != null 
          ? DateTime.tryParse(map['joinDate']) ?? DateTime.now()
          : DateTime.now(),
      lastActive: map['lastActive'] != null 
          ? DateTime.tryParse(map['lastActive']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalProducts': totalProducts,
      'activeProducts': activeProducts,
      'totalViews': totalViews,
      'totalInquiries': totalInquiries,
      'totalRevenue': totalRevenue,
      'totalSales': totalSales,
      'totalSold': totalSold,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'responseTime': responseTime,
      'completionRate': completionRate,
      'joinDate': joinDate.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
    };
  }
}