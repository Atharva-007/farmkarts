import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/order_model.dart';
import '../services/order_tracking_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';
import '../utils/toast_helper.dart';

/// Production-Ready Enhanced Order Tracking Page
/// Features: Real-time tracking, Security, Performance optimization, Error handling
class EnhancedOrderTrackingPage extends StatefulWidget {
  final String? trackingId;
  final String? orderId;

  const EnhancedOrderTrackingPage({
    super.key,
    this.trackingId,
    this.orderId,
  });

  @override
  State<EnhancedOrderTrackingPage> createState() =>
      _EnhancedOrderTrackingPageState();
}

class _EnhancedOrderTrackingPageState extends State<EnhancedOrderTrackingPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final TextEditingController _trackingController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TabController _tabController;
  OrderTrackingDetails? _trackingDetails;
  OrderModel? _currentOrder;
  bool _isLoading = false;
  String? _error;
  Stream<DocumentSnapshot>? _orderStream;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    if (widget.trackingId != null) {
      _trackingController.text = widget.trackingId!;
      _trackOrder();
    } else if (widget.orderId != null) {
      _loadOrderById(widget.orderId!);
    }
  }

  @override
  void dispose() {
    _trackingController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// Track order with security validation
  Future<void> _trackOrder() async {
    if (_trackingController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a tracking ID');
      return;
    }

    // Input sanitization
    final trackingId = _trackingController.text.trim().toUpperCase();

    // Validate tracking ID format
    if (!_validateTrackingId(trackingId)) {
      setState(() => _error = 'Invalid tracking ID format');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Try to find order by tracking ID in Firestore
      final querySnapshot = await _firestore
          .collection('orders')
          .where('trackingId', isEqualTo: trackingId)
          .limit(1)
          .get()
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout. Please try again.');
        },
      );

      if (querySnapshot.docs.isNotEmpty) {
        final orderDoc = querySnapshot.docs.first;
        final orderData = orderDoc.data();

        // Security check: Verify user has access to this order
        final userId = _auth.currentUser?.uid;
        if (userId == null ||
            (orderData['buyerId'] != userId &&
                orderData['sellerId'] != userId)) {
          throw Exception('Access denied. You cannot view this order.');
        }

        final order = OrderModel.fromMap(orderDoc.id, orderData);

        setState(() {
          _currentOrder = order;
          _trackingDetails = _buildTrackingDetails(order);
          _isLoading = false;

          // Setup real-time updates
          _setupRealtimeTracking(orderDoc.id);
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Order not found. Please check your tracking ID.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to track order: ${e.toString()}';
      });
    }
  }

  /// Load order by ID with security check
  Future<void> _loadOrderById(String orderId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orderDoc =
          await _firestore.collection('orders').doc(orderId).get().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout. Please try again.');
        },
      );

      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;

      // Security check
      final userId = _auth.currentUser?.uid;
      if (userId == null ||
          (orderData['buyerId'] != userId && orderData['sellerId'] != userId)) {
        throw Exception('Access denied');
      }

      final order = OrderModel.fromMap(orderDoc.id, orderData);

      setState(() {
        _currentOrder = order;
        _trackingController.text = order.trackingId ?? '';
        _trackingDetails = _buildTrackingDetails(order);
        _isLoading = false;

        _setupRealtimeTracking(orderId);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load order: ${e.toString()}';
      });
    }
  }

  /// Setup real-time order tracking
  void _setupRealtimeTracking(String orderId) {
    _orderStream = _firestore.collection('orders').doc(orderId).snapshots();

    _orderStream!.listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null && mounted) {
        final order = OrderModel.fromMap(
            snapshot.id, snapshot.data() as Map<String, dynamic>);
        setState(() {
          _currentOrder = order;
          _trackingDetails = _buildTrackingDetails(order);
        });
      }
    });
  }

  /// Build tracking details from order
  OrderTrackingDetails _buildTrackingDetails(OrderModel order) {
    final timeline = <TrackingTimeline>[];

    // Order Placed
    timeline.add(TrackingTimeline(
      status: 'Order Placed',
      timestamp: order.orderDate,
      message: 'Your order has been placed successfully',
      updatedBy: order.buyerId,
      completed: true,
    ));

    // Payment Confirmed
    if (order.paymentStatus == PaymentStatus.paid) {
      timeline.add(TrackingTimeline(
        status: 'Payment Confirmed',
        timestamp: order.orderDate,
        message: 'Payment received and confirmed',
        updatedBy: 'system',
        completed: true,
      ));
    }

    // Order Confirmed
    if (order.confirmedDate != null) {
      timeline.add(TrackingTimeline(
        status: 'Order Confirmed',
        timestamp: order.confirmedDate!,
        message: 'Seller has confirmed your order',
        updatedBy: order.sellerId,
        completed: true,
      ));
    } else if (order.status.index >= OrderStatus.confirmed.index) {
      timeline.add(TrackingTimeline(
        status: 'Order Confirmed',
        timestamp: null,
        message: 'Waiting for seller confirmation',
        updatedBy: '',
        completed: false,
      ));
    }

    // Processing
    if (order.status == OrderStatus.processing) {
      timeline.add(TrackingTimeline(
        status: 'Processing',
        timestamp: DateTime.now(),
        message: 'Your order is being prepared',
        updatedBy: order.sellerId,
        completed: true,
      ));
    } else if (order.status.index >= OrderStatus.processing.index) {
      timeline.add(TrackingTimeline(
        status: 'Processing',
        timestamp: null,
        message: 'Order will be processed soon',
        updatedBy: '',
        completed: false,
      ));
    }

    // Shipped
    if (order.shippedDate != null) {
      timeline.add(TrackingTimeline(
        status: 'Shipped',
        timestamp: order.shippedDate!,
        message: order.trackingNumber != null
            ? 'Order shipped. Tracking: ${order.trackingNumber}'
            : 'Your order has been shipped',
        updatedBy: order.sellerId,
        completed: true,
      ));
    } else if (order.status.index >= OrderStatus.shipped.index) {
      timeline.add(TrackingTimeline(
        status: 'Shipped',
        timestamp: null,
        message: 'Order will be shipped soon',
        updatedBy: '',
        completed: false,
      ));
    }

    // Out for Delivery
    if (order.status == OrderStatus.outForDelivery) {
      timeline.add(TrackingTimeline(
        status: 'Out for Delivery',
        timestamp: DateTime.now(),
        message: 'Your order is out for delivery',
        updatedBy: 'delivery_partner',
        completed: true,
      ));
    } else if (order.status.index >= OrderStatus.outForDelivery.index) {
      timeline.add(TrackingTimeline(
        status: 'Out for Delivery',
        timestamp: null,
        message: 'Will be out for delivery soon',
        updatedBy: '',
        completed: false,
      ));
    }

    // Delivered
    if (order.deliveredDate != null) {
      timeline.add(TrackingTimeline(
        status: 'Delivered',
        timestamp: order.deliveredDate!,
        message: 'Order delivered successfully',
        updatedBy: 'delivery_partner',
        completed: true,
      ));
    } else {
      timeline.add(TrackingTimeline(
        status: 'Delivered',
        timestamp: null,
        message: 'Final delivery pending',
        updatedBy: '',
        completed: false,
      ));
    }

    // Cancelled
    if (order.status == OrderStatus.cancelled) {
      timeline.add(TrackingTimeline(
        status: 'Cancelled',
        timestamp: order.cancelledDate ?? DateTime.now(),
        message: order.cancellationReason ?? 'Order cancelled',
        updatedBy: order.buyerId,
        completed: true,
      ));
    }

    // Calculate estimated delivery
    DateTime? estimatedDelivery;
    if (order.status != OrderStatus.delivered &&
        order.status != OrderStatus.cancelled) {
      estimatedDelivery = order.shippedDate?.add(const Duration(days: 3)) ??
          order.orderDate.add(const Duration(days: 5));
    }

    return OrderTrackingDetails(
      order: order,
      trackingTimeline: timeline,
      estimatedDelivery: estimatedDelivery,
      currentStatus: order.status.toString().split('.').last,
    );
  }

  /// Validate tracking ID format
  bool _validateTrackingId(String trackingId) {
    // Format: FK + timestamp or custom format
    if (trackingId.length < 8) return false;
    if (!trackingId.startsWith('FK') && !trackingId.startsWith('TRK'))
      return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Your Order'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          if (_currentOrder != null) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareTrackingInfo,
              tooltip: 'Share tracking info',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _trackOrder(),
              tooltip: 'Refresh',
            ),
          ],
        ],
        bottom: _currentOrder != null
            ? TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'Timeline', icon: Icon(Icons.timeline, size: 18)),
                  Tab(
                      text: 'Details',
                      icon: Icon(Icons.info_outline, size: 18)),
                  Tab(text: 'Actions', icon: Icon(Icons.settings, size: 18)),
                ],
              )
            : null,
      ),
      body: _currentOrder == null
          ? _buildSearchView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTimelineTab(),
                _buildDetailsTab(),
                _buildActionsTab(),
              ],
            ),
    );
  }

  Widget _buildSearchView() {
    return SingleChildScrollView(
      padding: AppConstants.defaultPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTrackingInputCard(),
          const SizedBox(height: 20),
          if (_isLoading) _buildLoadingWidget(),
          if (_error != null) _buildErrorWidget(),
          const SizedBox(height: 20),
          _buildHelpCard(),
        ],
      ),
    );
  }

  Widget _buildTrackingInputCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.search, color: AppTheme.primaryGreen),
                const SizedBox(width: 12),
                Text(
                  'Enter Tracking ID',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _trackingController,
              decoration: InputDecoration(
                hintText: 'e.g., FK1234567890',
                prefixIcon: const Icon(Icons.qr_code_scanner),
                suffixIcon: _trackingController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _trackingController.clear();
                            _error = null;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) {
                if (_error != null) {
                  setState(() => _error = null);
                }
              },
              onSubmitted: (_) => _trackOrder(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _trackOrder,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(_isLoading ? 'Tracking...' : 'Track Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Find your tracking ID in order confirmation email/SMS',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: AppTheme.primaryGreen),
              const SizedBox(height: 16),
              const Text('Tracking your order...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade200),
      ),
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCard() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need Help?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.phone, color: AppTheme.primaryGreen),
              title: const Text('Call Support'),
              subtitle: const Text('+91 1800-123-4567'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.chat, color: AppTheme.primaryGreen),
              title: const Text('Live Chat'),
              subtitle: const Text('Available 24/7'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineTab() {
    if (_trackingDetails == null) return const SizedBox();

    return RefreshIndicator(
      onRefresh: () => _trackOrder(),
      child: ListView(
        padding: AppConstants.defaultPadding,
        children: [
          _buildOrderStatusHeader(),
          const SizedBox(height: 20),
          _buildDeliveryEstimateCard(),
          const SizedBox(height: 20),
          _buildTrackingTimelineCard(),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    if (_currentOrder == null) return const SizedBox();

    return ListView(
      padding: AppConstants.defaultPadding,
      children: [
        _buildOrderInfoCard(),
        const SizedBox(height: 16),
        _buildPaymentInfoCard(),
        const SizedBox(height: 16),
        _buildDeliveryInfoCard(),
      ],
    );
  }

  Widget _buildActionsTab() {
    if (_currentOrder == null) return const SizedBox();

    return ListView(
      padding: AppConstants.defaultPadding,
      children: [
        _buildActionButtons(),
        const SizedBox(height: 16),
        _buildContactCard(),
        const SizedBox(height: 16),
        _buildSupportCard(),
      ],
    );
  }

  Widget _buildOrderStatusHeader() {
    final order = _currentOrder!;
    Color statusColor = _getStatusColor(order.status);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: AppConstants.defaultPadding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [statusColor.withValues(alpha: 0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              _getStatusIcon(order.status),
              size: 64,
              color: statusColor,
            ),
            const SizedBox(height: 12),
            Text(
              order.status.displayName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              order.status.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryEstimateCard() {
    if (_trackingDetails!.estimatedDelivery == null) return const SizedBox();

    final daysRemaining =
        _trackingDetails!.estimatedDelivery!.difference(DateTime.now()).inDays;

    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping, color: AppTheme.primaryGreen),
                const SizedBox(width: 12),
                Text(
                  'Estimated Delivery',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM dd, yyyy')
                              .format(_trackingDetails!.estimatedDelivery!),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          daysRemaining > 0
                              ? '$daysRemaining days remaining'
                              : 'Delivery today',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      daysRemaining > 0 ? '$daysRemaining' : '0',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingTimelineCard() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Timeline',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            ..._trackingDetails!.trackingTimeline.asMap().entries.map((entry) {
              final index = entry.key;
              final timeline = entry.value;
              final isLast =
                  index == _trackingDetails!.trackingTimeline.length - 1;

              return _buildTimelineItem(timeline, isLast);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(TrackingTimeline timeline, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: timeline.completed ? AppTheme.success : Colors.grey[300],
                shape: BoxShape.circle,
                boxShadow: timeline.completed
                    ? [
                        BoxShadow(
                          color: AppTheme.success.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: Icon(
                _getTimelineIcon(timeline.status),
                color: timeline.completed ? Colors.white : Colors.grey[600],
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: timeline.completed ? AppTheme.success : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: timeline.completed
                  ? AppTheme.success.withValues(alpha: 0.05)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: timeline.completed
                    ? AppTheme.success.withValues(alpha: 0.2)
                    : Colors.grey[300]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeline.status,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: timeline.completed
                        ? AppTheme.success
                        : AppTheme.textGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeline.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                if (timeline.timestamp != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd, yyyy - HH:mm')
                            .format(timeline.timestamp!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderInfoCard() {
    final order = _currentOrder!;

    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            _buildInfoRow('Order ID', order.id),
            _buildInfoRow('Tracking ID', order.trackingId ?? 'Not available'),
            _buildInfoRow('Product', order.productName),
            _buildInfoRow('Quantity', '${order.quantity} ${order.unit}'),
            _buildInfoRow(
                'Unit Price', '₹${order.unitPrice.toStringAsFixed(2)}'),
            _buildInfoRow(
                'Total Amount', '₹${order.totalAmount.toStringAsFixed(2)}',
                isBold: true),
            _buildInfoRow('Order Date',
                DateFormat('MMM dd, yyyy').format(order.orderDate)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoCard() {
    final order = _currentOrder!;

    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            _buildInfoRow('Payment Method', order.paymentMethod ?? 'COD'),
            _buildInfoRow('Payment Status', order.paymentStatus.displayName),
            if (order.transactionId != null)
              _buildInfoRow('Transaction ID', order.transactionId!),
            if (order.deliveryCharges != null)
              _buildInfoRow('Delivery Charges',
                  '₹${order.deliveryCharges!.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfoCard() {
    final order = _currentOrder!;

    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            _buildInfoRow(
                'Delivery Type', order.deliveryType.toString().split('.').last),
            _buildInfoRow('Delivery Address',
                order.deliveryAddress ?? order.buyerAddress),
            if (order.trackingNumber != null)
              _buildInfoRow('Tracking Number', order.trackingNumber!),
            _buildInfoRow('Buyer Name', order.buyerName),
            _buildInfoRow('Buyer Phone', order.buyerPhone),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final order = _currentOrder!;
    final userId = _auth.currentUser?.uid;
    final isBuyer = userId == order.buyerId;

    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (isBuyer &&
                order.status != OrderStatus.delivered &&
                order.status != OrderStatus.cancelled) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _cancelOrder(),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel Order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _copyTrackingId(),
                icon: const Icon(Icons.copy),
                label: const Text('Copy Tracking ID'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _shareTrackingInfo(),
                icon: const Icon(Icons.share),
                label: const Text('Share Tracking Info'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    final order = _currentOrder!;

    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Seller',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryGreen,
                child: Text(
                  order.sellerName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(order.sellerName),
              subtitle: Text(order.sellerPhone),
              trailing: IconButton(
                icon: const Icon(Icons.phone),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need Help?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.support_agent, color: AppTheme.primaryGreen),
              title: const Text('Contact Support'),
              subtitle: const Text('Available 24/7'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, '/help-support');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textGrey,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return AppTheme.success;
      case OrderStatus.shipped:
      case OrderStatus.outForDelivery:
        return AppTheme.info;
      case OrderStatus.processing:
      case OrderStatus.confirmed:
        return AppTheme.warning;
      case OrderStatus.cancelled:
        return AppTheme.error;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.shipped:
      case OrderStatus.outForDelivery:
        return Icons.local_shipping;
      case OrderStatus.processing:
        return Icons.inventory;
      case OrderStatus.confirmed:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.schedule;
    }
  }

  IconData _getTimelineIcon(String status) {
    switch (status.toLowerCase()) {
      case 'order placed':
        return Icons.shopping_cart;
      case 'payment confirmed':
        return Icons.payment;
      case 'order confirmed':
        return Icons.check_circle;
      case 'processing':
        return Icons.inventory;
      case 'shipped':
        return Icons.local_shipping;
      case 'out for delivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.home;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.circle;
    }
  }

  void _copyTrackingId() {
    if (_currentOrder?.trackingId != null) {
      Clipboard.setData(ClipboardData(text: _currentOrder!.trackingId!));
      ToastHelper.showSuccess(context, 'Tracking ID copied to clipboard');
    }
  }

  void _shareTrackingInfo() {
    if (_currentOrder != null) {
      final text = '''
Order Tracking Info:
Tracking ID: ${_currentOrder!.trackingId ?? 'N/A'}
Product: ${_currentOrder!.productName}
Status: ${_currentOrder!.status.displayName}
Amount: ₹${_currentOrder!.totalAmount.toStringAsFixed(2)}

Track your order: https://farmkarts.com/track/${_currentOrder!.trackingId}
      ''';

      Share.share(text, subject: 'Order Tracking - FarmKarts');
    }
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

    if (confirmed == true && mounted) {
      try {
        await _firestore.collection('orders').doc(_currentOrder!.id).update({
          'status': 'cancelled',
          'cancelledDate': DateTime.now().millisecondsSinceEpoch,
          'cancellationReason': 'Cancelled by user',
        });

        if (mounted) {
          ToastHelper.showSuccess(context, 'Order cancelled successfully');
        }
      } catch (e) {
        if (mounted) {
          ToastHelper.showError(context, 'Failed to cancel order: $e');
        }
      }
    }
  }
}
