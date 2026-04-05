import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart' as OrderModelFile;
import '../models/product_model.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Caching
  final Map<String, List<OrderModelFile.OrderModel>> _buyerOrdersCache = {};
  final Map<String, List<OrderModelFile.OrderModel>> _sellerOrdersCache = {};

  // Create a new order
  Future<String> createOrder({
    required Product product,
    required int quantity,
    required String buyerPhone,
    required String buyerAddress,
    required OrderModelFile.DeliveryType deliveryType,
    String? deliveryAddress,
    String? notes,
    String? paymentMethod,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final orderId = _firestore.collection('orders').doc().id;
      final totalAmount = product.price * quantity;

      final order = OrderModelFile.OrderModel(
        id: orderId,
        productId: product.id,
        productName: product.name,
        productCategory: product.category,
        productImageUrl:
            product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
        buyerId: user.uid,
        buyerName: user.displayName ?? user.email?.split('@')[0] ?? 'Buyer',
        buyerPhone: buyerPhone,
        buyerAddress: buyerAddress,
        sellerId: product.sellerId,
        sellerName: product.sellerName,
        sellerPhone: '',
        unitPrice: product.price,
        quantity: quantity,
        unit: product.unit,
        totalAmount: totalAmount,
        status: OrderModelFile.OrderStatus.pending,
        paymentStatus: OrderModelFile.PaymentStatus.pending,
        deliveryType: deliveryType,
        deliveryAddress: deliveryAddress,
        orderDate: DateTime.now(),
        createdAt: DateTime.now(),
        notes: notes,
        paymentMethod: paymentMethod,
        statusUpdates: [
          OrderModelFile.OrderStatusUpdate(
            status: OrderModelFile.OrderStatus.pending,
            timestamp: DateTime.now(),
            message: 'Order placed successfully',
            updatedBy: user.uid,
          ),
        ],
      );

      // Save order
      await _firestore.collection('orders').doc(orderId).set(order.toMap());

      // Update product quantity if tracked
      if (product.quantity > 0) {
        await _firestore.collection('products').doc(product.id).update({
          'quantity': FieldValue.increment(-quantity),
        });
      }

      // Create order notifications for seller
      await _createOrderNotification(
        userId: product.sellerId,
        orderId: orderId,
        message: 'New order received for ${product.name}',
        type: 'new_order',
      );

      return orderId;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Update order status
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderModelFile.OrderStatus newStatus,
    String? message,
    String? trackingNumber,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) throw Exception('Order not found');

      final order =
          OrderModelFile.OrderModel.fromMap(orderId, orderDoc.data()!);

      if (order.sellerId != user.uid && order.buyerId != user.uid) {
        throw Exception('Unauthorized to update this order');
      }

      final now = DateTime.now();
      final statusUpdate = OrderModelFile.OrderStatusUpdate(
        status: newStatus,
        timestamp: now,
        message: message ?? _getDefaultStatusMessage(newStatus),
        updatedBy: user.uid,
      );

      final updatedStatusUpdates =
          List<OrderModelFile.OrderStatusUpdate>.from(order.statusUpdates)
            ..add(statusUpdate);

      final updateData = <String, dynamic>{
        'status': newStatus.toString().split('.').last,
        'statusUpdates':
            updatedStatusUpdates.map((update) => update.toMap()).toList(),
        'updatedAt': now.millisecondsSinceEpoch,
      };

      // Add timestamp fields based on status
      switch (newStatus) {
        case OrderModelFile.OrderStatus.confirmed:
          updateData['confirmedDate'] = now.millisecondsSinceEpoch;
          break;
        case OrderModelFile.OrderStatus.shipped:
          updateData['shippedDate'] = now.millisecondsSinceEpoch;
          if (trackingNumber != null) {
            updateData['trackingNumber'] = trackingNumber;
          }
          break;
        case OrderModelFile.OrderStatus.delivered:
          updateData['deliveredDate'] = now.millisecondsSinceEpoch;
          updateData['paymentStatus'] =
              OrderModelFile.PaymentStatus.paid.toString().split('.').last;
          break;
        case OrderModelFile.OrderStatus.cancelled:
          updateData['cancelledDate'] = now.millisecondsSinceEpoch;
          if (message != null) {
            updateData['cancellationReason'] = message;
          }
          await _firestore.collection('products').doc(order.productId).update({
            'quantity': FieldValue.increment(order.quantity),
          });
          break;
        default:
          break;
      }

      await _firestore.collection('orders').doc(orderId).update(updateData);

      // Notify the other party
      final notifyId =
          user.uid == order.buyerId ? order.sellerId : order.buyerId;
      await _createOrderNotification(
        userId: notifyId,
        orderId: orderId,
        message:
            'Order #${orderId.substring(0, 5)} has been ${newStatus.displayName.toLowerCase()}',
        type: 'order_update',
      );
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Reactive Stream for Buyer Orders (Real-time & High Performance)
  Stream<List<OrderModelFile.OrderModel>> getBuyerOrdersStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('orders')
        .where('buyerId', isEqualTo: user.uid)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => OrderModelFile.OrderModel.fromMap(doc.id, doc.data()))
          .toList();
      _buyerOrdersCache[user.uid] = orders;
      return orders;
    });
  }

  // Reactive Stream for Seller Orders
  Stream<List<OrderModelFile.OrderModel>> getSellerOrdersStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('orders')
        .where('sellerId', isEqualTo: user.uid)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => OrderModelFile.OrderModel.fromMap(doc.id, doc.data()))
          .toList();
      _sellerOrdersCache[user.uid] = orders;
      return orders;
    });
  }

  // Get order by ID
  Future<OrderModelFile.OrderModel?> getOrder(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return OrderModelFile.OrderModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  // Statistics for Dashboard (Fast)
  Future<Map<String, dynamic>> getBuyerStats() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final orders = _buyerOrdersCache[user.uid] ??
        (await _firestore
                .collection('orders')
                .where('buyerId', isEqualTo: user.uid)
                .get())
            .docs
            .map((doc) => OrderModelFile.OrderModel.fromMap(doc.id, doc.data()))
            .toList();

    double totalSpent = 0;
    int activeCount = 0;
    for (var o in orders) {
      if (o.status != OrderModelFile.OrderStatus.delivered &&
          o.status != OrderModelFile.OrderStatus.cancelled) {
        activeCount++;
      }
      if (o.status == OrderModelFile.OrderStatus.delivered) {
        totalSpent += o.totalAmount;
      }
    }

    return {
      'totalOrders': orders.length,
      'activeOrders': activeCount,
      'totalSpent': totalSpent,
    };
  }

  // Search orders (from cache if possible for speed)
  Future<List<OrderModelFile.OrderModel>> searchOrders(String query,
      {bool forSeller = false}) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    List<OrderModelFile.OrderModel> source = (forSeller
            ? _sellerOrdersCache[user.uid]
            : _buyerOrdersCache[user.uid]) ??
        [];

    if (source.isEmpty) {
      final field = forSeller ? 'sellerId' : 'buyerId';
      final snapshot = await _firestore
          .collection('orders')
          .where(field, isEqualTo: user.uid)
          .get();
      source = snapshot.docs
          .map((doc) => OrderModelFile.OrderModel.fromMap(doc.id, doc.data()))
          .toList();
      if (forSeller) {
        _sellerOrdersCache[user.uid] = source;
      } else {
        _buyerOrdersCache[user.uid] = source;
      }
    }

    if (query.isEmpty) return source;

    return source
        .where((o) =>
            o.productName.toLowerCase().contains(query.toLowerCase()) ||
            o.id.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<void> cancelOrder(String orderId, [String? reason]) async {
    await updateOrderStatus(
        orderId: orderId,
        newStatus: OrderModelFile.OrderStatus.cancelled,
        message: reason);
  }

  Future<void> addOrderNote(String orderId, String note) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'notes': note,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to add order note: $e');
    }
  }

  // Create notification
  Future<void> _createOrderNotification({
    required String userId,
    required String orderId,
    required String message,
    required String type,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'orderId': orderId,
        'message': message,
        'type': type,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  String _getDefaultStatusMessage(OrderModelFile.OrderStatus status) {
    switch (status) {
      case OrderModelFile.OrderStatus.pending:
        return 'Order is waiting for confirmation';
      case OrderModelFile.OrderStatus.confirmed:
        return 'Order has been confirmed';
      case OrderModelFile.OrderStatus.processing:
        return 'Order is being prepared';
      case OrderModelFile.OrderStatus.shipped:
        return 'Order has been shipped';
      case OrderModelFile.OrderStatus.outForDelivery:
        return 'Order is out for delivery';
      case OrderModelFile.OrderStatus.delivered:
        return 'Order has been delivered successfully';
      case OrderModelFile.OrderStatus.cancelled:
        return 'Order has been cancelled';
      case OrderModelFile.OrderStatus.refunded:
        return 'Order amount has been refunded';
    }
  }
}
