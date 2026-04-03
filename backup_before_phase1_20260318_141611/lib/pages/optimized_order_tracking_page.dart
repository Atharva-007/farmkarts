import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';
import '../theme/app_theme.dart';
import '../utils/toast_helper.dart';
import 'package:intl/intl.dart';

/// Optimized Order Tracking Page with async operations
class OptimizedOrderTrackingPage extends StatefulWidget {
  final String? orderId;

  const OptimizedOrderTrackingPage({
    super.key,
    this.orderId,
  });

  @override
  State<OptimizedOrderTrackingPage> createState() =>
      _OptimizedOrderTrackingPageState();
}

class _OptimizedOrderTrackingPageState
    extends State<OptimizedOrderTrackingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Order? _order;
  Payment? _payment;
  bool _isLoading = true;
  String? _error;

  List<OrderStatusStep> _statusSteps = [];

  @override
  void initState() {
    super.initState();
    _loadOrderData();
  }

  /// Load order data asynchronously (off main thread)
  Future<void> _loadOrderData() async {
    if (widget.orderId == null) {
      setState(() {
        _error = 'No order ID provided';
        _isLoading = false;
      });
      return;
    }

    try {
      // Run Firebase queries in parallel
      final results = await Future.wait([
        _firestore.collection('orders').doc(widget.orderId).get(),
        _firestore
            .collection('payments')
            .where('orderId', isEqualTo: widget.orderId)
            .limit(1)
            .get(),
      ]);

      final orderDoc = results[0] as DocumentSnapshot;
      final paymentDocs = results[1] as QuerySnapshot;

      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      // Parse data off main thread
      final order = Order.fromMap(orderDoc.data() as Map<String, dynamic>);
      Payment? payment;
      if (paymentDocs.docs.isNotEmpty) {
        payment = Payment.fromMap(
            paymentDocs.docs.first.data() as Map<String, dynamic>);
      }

      // Update UI
      if (mounted) {
        setState(() {
          _order = order;
          _payment = payment;
          _statusSteps = _generateStatusSteps(order);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Generate status steps for stepper
  List<OrderStatusStep> _generateStatusSteps(Order order) {
    final steps = <OrderStatusStep>[
      OrderStatusStep(
        title: 'Order Placed',
        subtitle: 'We have received your order',
        timestamp: order.createdAt,
        isCompleted: true,
        icon: Icons.shopping_cart,
      ),
      OrderStatusStep(
        title: 'Confirmed',
        subtitle: 'Seller confirmed your order',
        timestamp: null,
        isCompleted: _isStatusReached(order.status, 'confirmed'),
        icon: Icons.check_circle,
      ),
      OrderStatusStep(
        title: 'Shipped',
        subtitle: 'Your order is on the way',
        timestamp: null,
        isCompleted: _isStatusReached(order.status, 'shipped'),
        icon: Icons.local_shipping,
      ),
      OrderStatusStep(
        title: 'Out for Delivery',
        subtitle: 'Order will be delivered soon',
        timestamp: null,
        isCompleted: _isStatusReached(order.status, 'out_for_delivery'),
        icon: Icons.delivery_dining,
      ),
      OrderStatusStep(
        title: 'Delivered',
        subtitle: 'Order has been delivered',
        timestamp: null,
        isCompleted: _isStatusReached(order.status, 'delivered'),
        icon: Icons.done_all,
      ),
    ];

    // Handle cancelled status
    if (order.status == 'cancelled') {
      steps.add(OrderStatusStep(
        title: 'Cancelled',
        subtitle: 'Order has been cancelled',
        timestamp: DateTime.now(),
        isCompleted: true,
        icon: Icons.cancel,
        isError: true,
      ));
    }

    return steps;
  }

  /// Check if current status has reached the given status
  bool _isStatusReached(String currentStatus, String targetStatus) {
    const statusOrder = {
      'pending': 0,
      'confirmed': 1,
      'shipped': 2,
      'out_for_delivery': 3,
      'delivered': 4,
    };

    final currentIndex = statusOrder[currentStatus] ?? 0;
    final targetIndex = statusOrder[targetStatus] ?? 0;

    return currentIndex >= targetIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          if (_order != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareTrackingInfo(),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    if (_order == null) {
      return const Center(
        child: Text('No order found'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrderData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderHeader(),
            const Divider(),
            _buildStatusStepper(),
            const Divider(),
            _buildOrderDetails(),
            if (_payment != null) ...[
              const Divider(),
              _buildPaymentDetails(),
            ],
            const SizedBox(height: 16),
            _buildActionButtons(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryGreen.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${_order!.id.substring(0, 8)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildStatusChip(_order!.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _order!.productName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Quantity: ${_order!.quantity} | Total: ₹${_order!.totalAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'confirmed':
        color = Colors.blue;
        label = 'Confirmed';
        break;
      case 'shipped':
        color = Colors.purple;
        label = 'Shipped';
        break;
      case 'out_for_delivery':
        color = Colors.indigo;
        label = 'Out for Delivery';
        break;
      case 'delivered':
        color = Colors.green;
        label = 'Delivered';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildStatusStepper() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _statusSteps.length,
            itemBuilder: (context, index) {
              final step = _statusSteps[index];
              final isLast = index == _statusSteps.length - 1;
              
              return _buildStatusStep(step, isLast);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStep(OrderStatusStep step, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: step.isCompleted
                    ? (step.isError ? Colors.red : AppTheme.primaryGreen)
                    : Colors.grey[300],
              ),
              child: Icon(
                step.icon,
                color: step.isCompleted ? Colors.white : Colors.grey[600],
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: step.isCompleted
                    ? AppTheme.primaryGreen
                    : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: step.isCompleted
                      ? (step.isError ? Colors.red : Colors.black)
                      : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step.subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              if (step.timestamp != null) ...[
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy - hh:mm a').format(step.timestamp!),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetails() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Order Date', DateFormat('MMM dd, yyyy').format(_order!.createdAt)),
          _buildDetailRow('Product', _order!.productName),
          _buildDetailRow('Quantity', '${_order!.quantity}'),
          _buildDetailRow('Price per unit', '₹${_order!.pricePerUnit.toStringAsFixed(2)}'),
          _buildDetailRow('Total Amount', '₹${_order!.totalAmount.toStringAsFixed(2)}'),
          const Divider(height: 24),
          const Text(
            'Delivery Address',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _order!.deliveryAddress ?? 'No address provided',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Contact', _order!.buyerPhone ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Payment Method', _payment!.method.toString().split('.').last.toUpperCase()),
          _buildDetailRow('Payment Status', _payment!.status.toString().split('.').last.toUpperCase()),
          if (_payment!.transactionId != null)
            _buildDetailRow('Transaction ID', _payment!.transactionId!),
          _buildDetailRow('Amount Paid', '₹${_payment!.amount.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (_order!.status == 'pending' || _order!.status == 'confirmed')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _cancelOrder(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Cancel Order'),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _contactSeller(),
              icon: const Icon(Icons.chat),
              label: const Text('Contact Seller'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _firestore.collection('orders').doc(_order!.id).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ToastHelper.showSuccess(context, 'Order cancelled successfully');
        _loadOrderData(); // Reload data
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Failed to cancel order: $e');
      }
    }
  }

  void _contactSeller() {
    // Implement chat/contact functionality
    ToastHelper.showInfo(context, 'Contact seller feature coming soon');
  }

  void _shareTrackingInfo() {
    // Implement share functionality
    ToastHelper.showInfo(context, 'Share tracking info coming soon');
  }
}

/// Order status step model
class OrderStatusStep {
  final String title;
  final String subtitle;
  final DateTime? timestamp;
  final bool isCompleted;
  final IconData icon;
  final bool isError;

  OrderStatusStep({
    required this.title,
    required this.subtitle,
    this.timestamp,
    required this.isCompleted,
    required this.icon,
    this.isError = false,
  });
}
