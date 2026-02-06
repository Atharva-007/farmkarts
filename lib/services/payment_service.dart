import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/payment_model.dart';
import '../models/product_model.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  /// Create a new order
  Future<Order> createOrder({
    required Product product,
    required double quantity,
    required String deliveryAddress,
    required String buyerPhone,
    required String buyerName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final orderId = _uuid.v4();
      final totalAmount = product.price * quantity;

      final order = Order(
        id: orderId,
        productId: product.id,
        productName: product.name,
        buyerId: user.uid,
        sellerId: product.sellerId,
        quantity: quantity,
        pricePerUnit: product.price,
        totalAmount: totalAmount,
        status: 'pending',
        createdAt: DateTime.now(),
        deliveryAddress: deliveryAddress,
        buyerPhone: buyerPhone,
        buyerName: buyerName,
      );

      await _firestore.collection('orders').doc(orderId).set(order.toMap());

      return order;
    } catch (e) {
      print('PaymentService: Error creating order: $e');
      rethrow;
    }
  }

  /// Initialize payment for an order
  Future<Payment> initializePayment({
    required Order order,
    required PaymentMethod method,
  }) async {
    try {
      final paymentId = _uuid.v4();

      final payment = Payment(
        id: paymentId,
        orderId: order.id,
        buyerId: order.buyerId,
        sellerId: order.sellerId,
        amount: order.totalAmount,
        method: method,
        status: PaymentStatus.pending,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('payments').doc(paymentId).set(payment.toMap());

      return payment;
    } catch (e) {
      print('PaymentService: Error initializing payment: $e');
      rethrow;
    }
  }

  /// Process Cash on Delivery
  Future<Payment> processCashOnDelivery(Order order) async {
    try {
      final payment = await initializePayment(
        order: order,
        method: PaymentMethod.cashOnDelivery,
      );

      // COD is automatically approved
      final completedPayment = payment.copyWith(
        status: PaymentStatus.completed,
        completedAt: DateTime.now(),
        transactionId: 'COD-${payment.id.substring(0, 8)}',
      );

      await _firestore
          .collection('payments')
          .doc(payment.id)
          .update(completedPayment.toMap());

      // Update order status
      await _firestore.collection('orders').doc(order.id).update({
        'status': 'confirmed',
        'paymentId': payment.id,
      });

      return completedPayment;
    } catch (e) {
      print('PaymentService: Error processing COD: $e');
      rethrow;
    }
  }

  /// Process UPI Payment (Simulated)
  Future<Payment> processUPIPayment({
    required Order order,
    required String upiId,
  }) async {
    try {
      final payment = await initializePayment(
        order: order,
        method: PaymentMethod.upi,
      );

      // Update payment with UPI details
      await _firestore.collection('payments').doc(payment.id).update({
        'status': PaymentStatus.processing.toString().split('.').last,
        'metadata': {
          'upiId': upiId,
          'processingStarted': DateTime.now().millisecondsSinceEpoch,
        },
      });

      // Simulate UPI processing (in real app, integrate with UPI gateway)
      await Future.delayed(const Duration(seconds: 2));

      // Complete payment
      final completedPayment = payment.copyWith(
        status: PaymentStatus.completed,
        completedAt: DateTime.now(),
        transactionId: 'UPI-${DateTime.now().millisecondsSinceEpoch}',
        metadata: {'upiId': upiId},
      );

      await _firestore
          .collection('payments')
          .doc(payment.id)
          .update(completedPayment.toMap());

      // Update order status
      await _firestore.collection('orders').doc(order.id).update({
        'status': 'confirmed',
        'paymentId': payment.id,
      });

      return completedPayment;
    } catch (e) {
      print('PaymentService: Error processing UPI: $e');
      
      // Mark payment as failed
      await _firestore.collection('payments').doc(payment.id).update({
        'status': PaymentStatus.failed.toString().split('.').last,
        'failureReason': e.toString(),
      });
      
      rethrow;
    }
  }

  /// Process Card Payment (Simulated)
  Future<Payment> processCardPayment({
    required Order order,
    required String cardNumber,
    required String cardHolderName,
    required String expiryDate,
    required String cvv,
    bool isCredit = true,
  }) async {
    try {
      final payment = await initializePayment(
        order: order,
        method: isCredit ? PaymentMethod.creditCard : PaymentMethod.debitCard,
      );

      // Update payment with card details (masked)
      final maskedCard = '****${cardNumber.substring(cardNumber.length - 4)}';
      
      await _firestore.collection('payments').doc(payment.id).update({
        'status': PaymentStatus.processing.toString().split('.').last,
        'metadata': {
          'cardNumber': maskedCard,
          'cardHolderName': cardHolderName,
          'processingStarted': DateTime.now().millisecondsSinceEpoch,
        },
      });

      // Simulate card processing
      await Future.delayed(const Duration(seconds: 3));

      // Complete payment
      final completedPayment = payment.copyWith(
        status: PaymentStatus.completed,
        completedAt: DateTime.now(),
        transactionId: 'CARD-${DateTime.now().millisecondsSinceEpoch}',
        metadata: {
          'cardNumber': maskedCard,
          'cardHolderName': cardHolderName,
        },
      );

      await _firestore
          .collection('payments')
          .doc(payment.id)
          .update(completedPayment.toMap());

      // Update order status
      await _firestore.collection('orders').doc(order.id).update({
        'status': 'confirmed',
        'paymentId': payment.id,
      });

      return completedPayment;
    } catch (e) {
      print('PaymentService: Error processing card payment: $e');
      
      // Mark payment as failed
      await _firestore.collection('payments').doc(payment.id).update({
        'status': PaymentStatus.failed.toString().split('.').last,
        'failureReason': e.toString(),
      });
      
      rethrow;
    }
  }

  /// Get payment by ID
  Future<Payment?> getPayment(String paymentId) async {
    try {
      final doc = await _firestore.collection('payments').doc(paymentId).get();
      
      if (doc.exists) {
        return Payment.fromMap(doc.data()!);
      }
      
      return null;
    } catch (e) {
      print('PaymentService: Error getting payment: $e');
      return null;
    }
  }

  /// Get order by ID
  Future<Order?> getOrder(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      
      if (doc.exists) {
        return Order.fromMap(doc.data()!);
      }
      
      return null;
    } catch (e) {
      print('PaymentService: Error getting order: $e');
      return null;
    }
  }

  /// Get user's orders
  Future<List<Order>> getUserOrders({bool asSeller = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final field = asSeller ? 'sellerId' : 'buyerId';
      
      final snapshot = await _firestore
          .collection('orders')
          .where(field, isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Order.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('PaymentService: Error getting user orders: $e');
      return [];
    }
  }

  /// Get user's payments
  Future<List<Payment>> getUserPayments({bool asSeller = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final field = asSeller ? 'sellerId' : 'buyerId';
      
      final snapshot = await _firestore
          .collection('payments')
          .where(field, isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Payment.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('PaymentService: Error getting user payments: $e');
      return [];
    }
  }

  /// Cancel order
  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'cancelledAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Find associated payment and cancel if exists
      final paymentsSnapshot = await _firestore
          .collection('payments')
          .where('orderId', isEqualTo: orderId)
          .get();

      for (var doc in paymentsSnapshot.docs) {
        await doc.reference.update({
          'status': PaymentStatus.cancelled.toString().split('.').last,
          'failureReason': 'Order cancelled: $reason',
        });
      }
    } catch (e) {
      print('PaymentService: Error cancelling order: $e');
      rethrow;
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('PaymentService: Error updating order status: $e');
      rethrow;
    }
  }
}
