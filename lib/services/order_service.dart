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
        productImageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
        buyerId: user.uid,
        buyerName: user.displayName ?? user.email?.split('@')[0] ?? 'Buyer',
        buyerPhone: buyerPhone,
        buyerAddress: buyerAddress,
        sellerId: product.sellerId,
        sellerName: product.sellerName,
        sellerPhone: '', // Will be fetched from seller profile
        unitPrice: product.price,
        quantity: quantity,
        unit: product.unit,
        totalAmount: totalAmount,
        status: OrderModelFile.OrderStatus.pending,
        paymentStatus: OrderModelFile.PaymentStatus.pending,
        deliveryType: deliveryType,
        deliveryAddress: deliveryAddress,
        orderDate: DateTime.now(),
        createdAt: DateTime.now(), // Add this required parameter
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
        sellerId: product.sellerId,
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

      final order = OrderModelFile.OrderModel.fromMap(orderId, orderDoc.data()!);
      
      // Check permissions - only seller or admin can update
      if (order.sellerId != user.uid) {
        throw Exception('Unauthorized to update this order');
      }

      final now = DateTime.now();
      final statusUpdate = OrderModelFile.OrderStatusUpdate(
        status: newStatus,
        timestamp: now,
        message: message ?? _getDefaultStatusMessage(newStatus),
        updatedBy: user.uid,
      );

      final updatedStatusUpdates = List<OrderModelFile.OrderStatusUpdate>.from(order.statusUpdates)
        ..add(statusUpdate);

      final updateData = <String, dynamic>{
        'status': newStatus.toString().split('.').last,
        'statusUpdates': updatedStatusUpdates.map((update) => update.toMap()).toList(),
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
          updateData['paymentStatus'] = OrderModelFile.PaymentStatus.paid.toString().split('.').last;
          break;
        case OrderModelFile.OrderStatus.cancelled:
          updateData['cancelledDate'] = now.millisecondsSinceEpoch;
          if (message != null) {
            updateData['cancellationReason'] = message;
          }
          // Restore product quantity
          await _firestore.collection('products').doc(order.productId).update({
            'quantity': FieldValue.increment(order.quantity),
          });
          break;
        default:
          break;
      }

      await _firestore.collection('orders').doc(orderId).update(updateData);

      // Create notification for buyer
      await _createOrderNotification(
        sellerId: order.buyerId,
        orderId: orderId,
        message: 'Your order has been ${newStatus.displayName.toLowerCase()}',
        type: 'order_update',
      );
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Get orders for buyer
  Stream<List<OrderModelFile.OrderModel>> getBuyerOrders() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    try {
      return _firestore
          .collection('orders')
          .where('buyerId', isEqualTo: user.uid)
          .orderBy('orderDate', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          try {
            return OrderModelFile.OrderModel.fromMap(doc.id, doc.data());
          } catch (e) {
            print('Error parsing order ${doc.id}: $e');
            // Return a dummy order or skip? Let's skip invalid ones
            return null;
          }
        }).whereType<OrderModelFile.OrderModel>().toList();
      }).handleError((error) {
        print('Firestore error in getBuyerOrders: $error');
        // If index error, try without ordering as fallback
        if (error.toString().contains('FAILED_PRECONDITION')) {
           return _firestore
            .collection('orders')
            .where('buyerId', isEqualTo: user.uid)
            .snapshots()
            .map((snapshot) {
              final list = snapshot.docs.map((doc) => OrderModelFile.OrderModel.fromMap(doc.id, doc.data())).toList();
              list.sort((a, b) => b.orderDate.compareTo(a.orderDate));
              return list;
            });
        }
        return Stream.value(<OrderModelFile.OrderModel>[]);
      });
    } catch (e) {
      print('Exception in getBuyerOrders: $e');
      return Stream.value([]);
    }
  }

  // Get orders for seller
  Stream<List<OrderModelFile.OrderModel>> getSellerOrders() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    try {
      return _firestore
          .collection('orders')
          .where('sellerId', isEqualTo: user.uid)
          .orderBy('orderDate', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          try {
            return OrderModelFile.OrderModel.fromMap(doc.id, doc.data());
          } catch (e) {
            print('Error parsing order ${doc.id}: $e');
            return null;
          }
        }).whereType<OrderModelFile.OrderModel>().toList();
      }).handleError((error) {
        print('Firestore error in getSellerOrders: $error');
        if (error.toString().contains('FAILED_PRECONDITION')) {
           return _firestore
            .collection('orders')
            .where('sellerId', isEqualTo: user.uid)
            .snapshots()
            .map((snapshot) {
              final list = snapshot.docs.map((doc) => OrderModelFile.OrderModel.fromMap(doc.id, doc.data())).toList();
              list.sort((a, b) => b.orderDate.compareTo(a.orderDate));
              return list;
            });
        }
        return Stream.value(<OrderModelFile.OrderModel>[]);
      });
    } catch (e) {
      print('Exception in getSellerOrders: $e');
      return Stream.value([]);
    }
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

  // Get orders by status
  Stream<List<OrderModelFile.OrderModel>> getOrdersByStatus(OrderModelFile.OrderStatus status, {bool forSeller = false}) {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final field = forSeller ? 'sellerId' : 'buyerId';
    
    return _firestore
        .collection('orders')
        .where(field, isEqualTo: user.uid)
        .where('status', isEqualTo: status.toString().split('.').last)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return OrderModelFile.OrderModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Cancel order
  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) throw Exception('Order not found');

      final order = OrderModelFile.OrderModel.fromMap(orderId, orderDoc.data()!);
      
      // Check if user can cancel (buyer or seller)
      if (order.buyerId != user.uid && order.sellerId != user.uid) {
        throw Exception('Unauthorized to cancel this order');
      }

      // Check if order can be cancelled
      if (order.status == OrderModelFile.OrderStatus.delivered || 
          order.status == OrderModelFile.OrderStatus.cancelled) {
        throw Exception('Order cannot be cancelled');
      }

      await updateOrderStatus(
        orderId: orderId,
        newStatus: OrderModelFile.OrderStatus.cancelled,
        message: reason,
      );
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  // Get order statistics for seller
  Future<Map<String, dynamic>> getSellerOrderStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final orders = await _firestore
          .collection('orders')
          .where('sellerId', isEqualTo: user.uid)
          .get();

      int totalOrders = orders.docs.length;
      int pendingOrders = 0;
      int completedOrders = 0;
      int cancelledOrders = 0;
      double totalRevenue = 0;
      double pendingRevenue = 0;

      for (final doc in orders.docs) {
        final order = OrderModelFile.OrderModel.fromMap(doc.id, doc.data());
        
        switch (order.status) {
          case OrderModelFile.OrderStatus.pending:
          case OrderModelFile.OrderStatus.confirmed:
          case OrderModelFile.OrderStatus.processing:
          case OrderModelFile.OrderStatus.shipped:
          case OrderModelFile.OrderStatus.outForDelivery:
            pendingOrders++;
            pendingRevenue += order.totalAmount;
            break;
          case OrderModelFile.OrderStatus.delivered:
            completedOrders++;
            totalRevenue += order.totalAmount;
            break;
          case OrderModelFile.OrderStatus.cancelled:
          case OrderModelFile.OrderStatus.refunded:
            cancelledOrders++;
            break;
        }
      }

      return {
        'totalOrders': totalOrders,
        'pendingOrders': pendingOrders,
        'completedOrders': completedOrders,
        'cancelledOrders': cancelledOrders,
        'totalRevenue': totalRevenue,
        'pendingRevenue': pendingRevenue,
        'completionRate': totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0,
      };
    } catch (e) {
      throw Exception('Failed to get order statistics: $e');
    }
  }

  // Get order statistics for buyer
  Future<Map<String, dynamic>> getBuyerOrderStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final orders = await _firestore
          .collection('orders')
          .where('buyerId', isEqualTo: user.uid)
          .get();

      int totalOrders = orders.docs.length;
      int activeOrders = 0;
      int completedOrders = 0;
      int cancelledOrders = 0;
      double totalSpent = 0;

      for (final doc in orders.docs) {
        final order = OrderModelFile.OrderModel.fromMap(doc.id, doc.data());
        
        switch (order.status) {
          case OrderModelFile.OrderStatus.pending:
          case OrderModelFile.OrderStatus.confirmed:
          case OrderModelFile.OrderStatus.processing:
          case OrderModelFile.OrderStatus.shipped:
          case OrderModelFile.OrderStatus.outForDelivery:
            activeOrders++;
            break;
          case OrderModelFile.OrderStatus.delivered:
            completedOrders++;
            totalSpent += order.totalAmount;
            break;
          case OrderModelFile.OrderStatus.cancelled:
          case OrderModelFile.OrderStatus.refunded:
            cancelledOrders++;
            break;
        }
      }

      return {
        'totalOrders': totalOrders,
        'activeOrders': activeOrders,
        'completedOrders': completedOrders,
        'cancelledOrders': cancelledOrders,
        'totalSpent': totalSpent,
      };
    } catch (e) {
      throw Exception('Failed to get buyer statistics: $e');
    }
  }

  // Create order notification
  Future<void> _createOrderNotification({
    required String sellerId,
    required String orderId,
    required String message,
    required String type,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': sellerId,
        'orderId': orderId,
        'message': message,
        'type': type,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silent fail for notifications
    }
  }

  // Get default status message
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

  // Search orders
  Future<List<OrderModelFile.OrderModel>> searchOrders(String query, {bool forSeller = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final field = forSeller ? 'sellerId' : 'buyerId';
      
      final orders = await _firestore
          .collection('orders')
          .where(field, isEqualTo: user.uid)
          .get();

      return orders.docs
          .map((doc) => OrderModelFile.OrderModel.fromMap(doc.id, doc.data()))
          .where((order) =>
              order.productName.toLowerCase().contains(query.toLowerCase()) ||
              order.id.toLowerCase().contains(query.toLowerCase()) ||
              (forSeller ? order.buyerName : order.sellerName)
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search orders: $e');
    }
  }

  // Update payment status
  Future<void> updatePaymentStatus({
    required String orderId,
    required OrderModelFile.PaymentStatus paymentStatus,
    String? transactionId,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'paymentStatus': paymentStatus.toString().split('.').last,
      };

      if (transactionId != null) {
        updateData['transactionId'] = transactionId;
      }

      await _firestore.collection('orders').doc(orderId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  // Get orders by buyer ID 
  Future<List<OrderModelFile.OrderModel>> getOrdersByBuyer(String buyerId) async {
    try {
      final orders = await _firestore
          .collection('orders')
          .where('buyerId', isEqualTo: buyerId)
          .orderBy('orderDate', descending: true)
          .get();

      return orders.docs.map((doc) {
        return OrderModelFile.OrderModel.fromMap(doc.id, doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Failed to get orders by buyer: $e');
    }
  }

  // Add order note
  Future<void> addOrderNote(String orderId, String note) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'notes': note,
      });
    } catch (e) {
      throw Exception('Failed to add order note: $e');
    }
  }
}