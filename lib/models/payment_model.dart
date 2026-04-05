/// Payment method types
enum PaymentMethod {
  cashOnDelivery,
  upi,
  netBanking,
  creditCard,
  debitCard,
  wallet,
  razorpay,
}

/// Payment status
enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded,
  cancelled,
}

/// Payment model
class Payment {
  final String id;
  final String orderId;
  final String buyerId;
  final String sellerId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? transactionId;
  final String? failureReason;
  final Map<String, dynamic>? metadata;

  Payment({
    required this.id,
    required this.orderId,
    required this.buyerId,
    required this.sellerId,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.transactionId,
    this.failureReason,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'amount': amount,
      'method': method.toString().split('.').last,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'transactionId': transactionId,
      'failureReason': failureReason,
      'metadata': metadata,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] ?? '',
      orderId: map['orderId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      method: PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == map['method'],
        orElse: () => PaymentMethod.cashOnDelivery,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => PaymentStatus.pending,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null,
      transactionId: map['transactionId'],
      failureReason: map['failureReason'],
      metadata: map['metadata'],
    );
  }

  Payment copyWith({
    String? id,
    String? orderId,
    String? buyerId,
    String? sellerId,
    double? amount,
    PaymentMethod? method,
    PaymentStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? transactionId,
    String? failureReason,
    Map<String, dynamic>? metadata,
  }) {
    return Payment(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      transactionId: transactionId ?? this.transactionId,
      failureReason: failureReason ?? this.failureReason,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Order model for payment processing
class Order {
  final String id;
  final String productId;
  final String productName;
  final String buyerId;
  final String sellerId;
  final double quantity;
  final double pricePerUnit;
  final double totalAmount;
  final String status; // pending, confirmed, shipped, delivered, cancelled
  final DateTime createdAt;
  final String? deliveryAddress;
  final String? buyerPhone;
  final String? buyerName;

  Order({
    required this.id,
    required this.productId,
    required this.productName,
    required this.buyerId,
    required this.sellerId,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.deliveryAddress,
    this.buyerPhone,
    this.buyerName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'quantity': quantity,
      'pricePerUnit': pricePerUnit,
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'deliveryAddress': deliveryAddress,
      'buyerPhone': buyerPhone,
      'buyerName': buyerName,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      buyerId: map['buyerId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      pricePerUnit: (map['pricePerUnit'] ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      deliveryAddress: map['deliveryAddress'],
      buyerPhone: map['buyerPhone'],
      buyerName: map['buyerName'],
    );
  }
}
