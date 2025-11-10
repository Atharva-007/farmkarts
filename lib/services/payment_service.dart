import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/order_model.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  static const String baseUrl = 'http://localhost:3000/api';
  late Razorpay _razorpay;
  Function(String)? onPaymentSuccess;
  Function(PaymentFailureResponse)? onPaymentError;

  void initialize() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  // Create Razorpay order
  Future<Map<String, dynamic>?> createRazorpayOrder({
    required double amount,
    required String receipt,
    String currency = 'INR',
    String? productId,
    String? buyerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments/razorpay/create-order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'currency': currency,
          'receipt': receipt,
          'productId': productId,
          'buyerId': buyerId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error creating Razorpay order: $e');
      return null;
    }
  }

  // Start payment process
  Future<bool> makePayment({
    required double amount,
    required String orderId,
    required String buyerName,
    required String buyerEmail,
    required String buyerPhone,
    required String description,
    String? razorpayKey,
  }) async {
    try {
      var options = {
        'key': razorpayKey ?? 'rzp_test_1DP5mmOlF5G5ag', // Replace with your key
        'amount': (amount * 100).toInt(), // Amount in paise
        'name': 'FarmKart',
        'order_id': orderId,
        'description': description,
        'timeout': 300, // 5 minutes
        'prefill': {
          'contact': buyerPhone,
          'email': buyerEmail,
          'name': buyerName,
        },
        'theme': {
          'color': '#4CAF50', // FarmKart green
        }
      };

      _razorpay.open(options);
      return true;
    } catch (e) {
      print('Error starting payment: $e');
      return false;
    }
  }

  // Verify payment on backend
  Future<Map<String, dynamic>?> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
    required String productId,
    required String buyerId,
    required String sellerId,
    required Map<String, dynamic> orderDetails,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments/razorpay/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'razorpay_payment_id': paymentId,
          'razorpay_order_id': orderId,
          'razorpay_signature': signature,
          'productId': productId,
          'buyerId': buyerId,
          'sellerId': sellerId,
          'orderDetails': orderDetails,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      print('Error verifying payment: $e');
      return null;
    }
  }

  // Payment event handlers
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (onPaymentSuccess != null) {
      onPaymentSuccess!(response.paymentId!);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (onPaymentError != null) {
      onPaymentError!(response);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External wallet selected: ${response.walletName}');
  }

  // Create complete order with payment
  Future<OrderModel?> createOrderWithPayment({
    required String productId,
    required String productName,
    required String sellerId,
    required String sellerName,
    required String buyerId,
    required String buyerName,
    required String buyerEmail,
    required String buyerPhone,
    required String buyerAddress,
    required double price,
    required int quantity,
    required String unit,
    String? notes,
    String deliveryType = 'standard',
  }) async {
    try {
      // Step 1: Create Razorpay order
      final amount = price * quantity;
      final receipt = 'FK_${DateTime.now().millisecondsSinceEpoch}';
      
      final razorpayOrder = await createRazorpayOrder(
        amount: amount,
        receipt: receipt,
        productId: productId,
        buyerId: buyerId,
      );

      if (razorpayOrder == null) {
        throw Exception('Failed to create payment order');
      }

      // Step 2: Prepare order details
      final orderDetails = {
        'productId': productId,
        'productName': productName,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'buyerId': buyerId,
        'buyerName': buyerName,
        'buyerEmail': buyerEmail,
        'buyerPhone': buyerPhone,
        'buyerAddress': buyerAddress,
        'price': price,
        'quantity': quantity,
        'unit': unit,
        'totalAmount': amount,
        'notes': notes ?? '',
        'deliveryType': deliveryType,
      };

      // Step 3: Start payment
      final paymentStarted = await makePayment(
        amount: amount,
        orderId: razorpayOrder['orderId'],
        buyerName: buyerName,
        buyerEmail: buyerEmail,
        buyerPhone: buyerPhone,
        description: 'Payment for $productName',
        razorpayKey: razorpayOrder['key'],
      );

      if (!paymentStarted) {
        throw Exception('Failed to start payment process');
      }

      return null; // Payment success will be handled in callback
    } catch (e) {
      print('Error creating order with payment: $e');
      return null;
    }
  }

  // Get payment history
  Future<List<Map<String, dynamic>>> getPaymentHistory(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders?buyerId=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching payment history: $e');
      return [];
    }
  }

  // Cancel payment (if supported)
  Future<bool> cancelPayment(String paymentId) async {
    try {
      // Implementation depends on payment gateway capabilities
      // For now, return true as placeholder
      return true;
    } catch (e) {
      print('Error cancelling payment: $e');
      return false;
    }
  }

  // Refund payment (seller initiated)
  Future<bool> refundPayment({
    required String paymentId,
    required double amount,
    String? reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments/refund'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'paymentId': paymentId,
          'amount': amount,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error processing refund: $e');
      return false;
    }
  }

  // Get payment details
  Future<Map<String, dynamic>?> getPaymentDetails(String paymentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payments/$paymentId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error fetching payment details: $e');
      return null;
    }
  }
}

// Payment Models
class PaymentResult {
  final bool success;
  final String? paymentId;
  final String? orderId;
  final String? trackingId;
  final String? error;

  PaymentResult({
    required this.success,
    this.paymentId,
    this.orderId,
    this.trackingId,
    this.error,
  });
}

class PaymentConfig {
  static const String razorpayKeyId = 'rzp_test_1DP5mmOlF5G5ag'; // Replace with your key
  static const String companyName = 'FarmKart';
  static const String companyLogo = 'https://farmkart.com/logo.png'; // Replace with your logo
  static const String supportEmail = 'support@farmkart.com';
  static const String supportPhone = '+91-1234567890';
}