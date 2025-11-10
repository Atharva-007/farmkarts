class OrderModel {
  final String id;
  final String productId;
  final String productName;
  final String productCategory;
  final String productImageUrl;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String buyerAddress;
  final String sellerId;
  final String sellerName;
  final String sellerPhone;
  final double unitPrice;
  final int quantity;
  final String unit;
  final double totalAmount;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final DeliveryType deliveryType;
  final String? deliveryAddress;
  final DateTime orderDate;
  final DateTime? confirmedDate;
  final DateTime? shippedDate;
  final DateTime? deliveredDate;
  final DateTime? cancelledDate;
  final String? cancellationReason;
  final List<OrderStatusUpdate> statusUpdates;
  final String? notes;
  final String? trackingNumber;
  final double? deliveryCharges;
  final String? paymentMethod;
  final String? transactionId;

  OrderModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productCategory,
    this.productImageUrl = '',
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerAddress,
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhone,
    required this.unitPrice,
    required this.quantity,
    required this.unit,
    required this.totalAmount,
    this.status = OrderStatus.pending,
    this.paymentStatus = PaymentStatus.pending,
    required this.deliveryType,
    this.deliveryAddress,
    required this.orderDate,
    this.confirmedDate,
    this.shippedDate,
    this.deliveredDate,
    this.cancelledDate,
    this.cancellationReason,
    this.statusUpdates = const [],
    this.notes,
    this.trackingNumber,
    this.deliveryCharges,
    this.paymentMethod,
    this.transactionId,
  });

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    return OrderModel(
      id: id,
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productCategory: map['productCategory'] ?? '',
      productImageUrl: map['productImageUrl'] ?? '',
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? '',
      buyerPhone: map['buyerPhone'] ?? '',
      buyerAddress: map['buyerAddress'] ?? '',
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      sellerPhone: map['sellerPhone'] ?? '',
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      unit: map['unit'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      deliveryType: DeliveryType.values.firstWhere(
        (e) => e.toString().split('.').last == map['deliveryType'],
        orElse: () => DeliveryType.pickup,
      ),
      deliveryAddress: map['deliveryAddress'],
      orderDate: DateTime.fromMillisecondsSinceEpoch(map['orderDate'] ?? 0),
      confirmedDate: map['confirmedDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['confirmedDate'])
          : null,
      shippedDate: map['shippedDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['shippedDate'])
          : null,
      deliveredDate: map['deliveredDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['deliveredDate'])
          : null,
      cancelledDate: map['cancelledDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['cancelledDate'])
          : null,
      cancellationReason: map['cancellationReason'],
      statusUpdates: (map['statusUpdates'] as List<dynamic>?)
              ?.map((item) => OrderStatusUpdate.fromMap(Map<String, dynamic>.from(item)))
              .toList() ?? [],
      notes: map['notes'],
      trackingNumber: map['trackingNumber'],
      deliveryCharges: map['deliveryCharges']?.toDouble(),
      paymentMethod: map['paymentMethod'],
      transactionId: map['transactionId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productCategory': productCategory,
      'productImageUrl': productImageUrl,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'buyerAddress': buyerAddress,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerPhone': sellerPhone,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'unit': unit,
      'totalAmount': totalAmount,
      'status': status.toString().split('.').last,
      'paymentStatus': paymentStatus.toString().split('.').last,
      'deliveryType': deliveryType.toString().split('.').last,
      'deliveryAddress': deliveryAddress,
      'orderDate': orderDate.millisecondsSinceEpoch,
      'confirmedDate': confirmedDate?.millisecondsSinceEpoch,
      'shippedDate': shippedDate?.millisecondsSinceEpoch,
      'deliveredDate': deliveredDate?.millisecondsSinceEpoch,
      'cancelledDate': cancelledDate?.millisecondsSinceEpoch,
      'cancellationReason': cancellationReason,
      'statusUpdates': statusUpdates.map((update) => update.toMap()).toList(),
      'notes': notes,
      'trackingNumber': trackingNumber,
      'deliveryCharges': deliveryCharges,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
    };
  }

  OrderModel copyWith({
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    DateTime? confirmedDate,
    DateTime? shippedDate,
    DateTime? deliveredDate,
    DateTime? cancelledDate,
    String? cancellationReason,
    List<OrderStatusUpdate>? statusUpdates,
    String? notes,
    String? trackingNumber,
    String? transactionId,
  }) {
    return OrderModel(
      id: id,
      productId: productId,
      productName: productName,
      productCategory: productCategory,
      productImageUrl: productImageUrl,
      buyerId: buyerId,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      buyerAddress: buyerAddress,
      sellerId: sellerId,
      sellerName: sellerName,
      sellerPhone: sellerPhone,
      unitPrice: unitPrice,
      quantity: quantity,
      unit: unit,
      totalAmount: totalAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      deliveryType: deliveryType,
      deliveryAddress: deliveryAddress,
      orderDate: orderDate,
      confirmedDate: confirmedDate ?? this.confirmedDate,
      shippedDate: shippedDate ?? this.shippedDate,
      deliveredDate: deliveredDate ?? this.deliveredDate,
      cancelledDate: cancelledDate ?? this.cancelledDate,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      statusUpdates: statusUpdates ?? this.statusUpdates,
      notes: notes ?? this.notes,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      deliveryCharges: deliveryCharges,
      paymentMethod: paymentMethod,
      transactionId: transactionId ?? this.transactionId,
    );
  }
}

class OrderStatusUpdate {
  final OrderStatus status;
  final DateTime timestamp;
  final String message;
  final String? updatedBy;

  OrderStatusUpdate({
    required this.status,
    required this.timestamp,
    required this.message,
    this.updatedBy,
  });

  factory OrderStatusUpdate.fromMap(Map<String, dynamic> map) {
    return OrderStatusUpdate(
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      message: map['message'] ?? '',
      updatedBy: map['updatedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.toString().split('.').last,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'message': message,
      'updatedBy': updatedBy,
    };
  }
}

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
  refunded,
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
  partiallyRefunded,
}

enum DeliveryType {
  pickup,
  delivery,
  courierDelivery,
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  String get description {
    switch (this) {
      case OrderStatus.pending:
        return 'Order is waiting for seller confirmation';
      case OrderStatus.confirmed:
        return 'Order has been confirmed by the seller';
      case OrderStatus.processing:
        return 'Order is being prepared for shipment';
      case OrderStatus.shipped:
        return 'Order has been shipped';
      case OrderStatus.outForDelivery:
        return 'Order is out for delivery';
      case OrderStatus.delivered:
        return 'Order has been delivered successfully';
      case OrderStatus.cancelled:
        return 'Order has been cancelled';
      case OrderStatus.refunded:
        return 'Order amount has been refunded';
    }
  }
}

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.partiallyRefunded:
        return 'Partially Refunded';
    }
  }
}