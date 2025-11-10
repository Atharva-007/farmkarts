import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/order_tracking_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';

class OrderTrackingPage extends StatefulWidget {
  final String? trackingId;
  final String? orderId;

  const OrderTrackingPage({
    super.key,
    this.trackingId,
    this.orderId,
  });

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final TextEditingController _trackingController = TextEditingController();
  final OrderTrackingService _orderService = OrderTrackingService();
  
  OrderTrackingDetails? _trackingDetails;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.trackingId != null) {
      _trackingController.text = widget.trackingId!;
      _trackOrder();
    }
  }

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  Future<void> _trackOrder() async {
    if (_trackingController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please enter a tracking ID';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final details = await _orderService.trackOrder(_trackingController.text.trim());
      
      setState(() {
        _trackingDetails = details;
        _isLoading = false;
        if (details == null) {
          _error = 'Order not found. Please check your tracking ID.';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to track order: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Your Order'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTrackingInputCard(),
            const SizedBox(height: 20),
            if (_isLoading) _buildLoadingWidget(),
            if (_error != null) _buildErrorWidget(),
            if (_trackingDetails != null) ...[
              _buildOrderInfoCard(),
              const SizedBox(height: 20),
              _buildTrackingTimelineCard(),
              const SizedBox(height: 20),
              _buildDeliveryEstimateCard(),
              const SizedBox(height: 20),
              _buildActionButtonsCard(),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingInputCard() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Tracking ID',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _trackingController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., FK1234567890',
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: Icon(Icons.qr_code_scanner),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _trackOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Track'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'You can find your tracking ID in the order confirmation email or SMS.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Tracking your order...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(color: AppTheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    final order = _trackingDetails!.order;
    
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(order.status),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image placeholder or actual image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.agriculture),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.productName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Quantity: ${order.quantity} ${order.unit}'),
                      const SizedBox(height: 4),
                      Text(
                        '₹${order.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Order ID', order.id),
            _buildInfoRow('Tracking ID', order.trackingId),
            _buildInfoRow('Order Date', DateFormat('MMM dd, yyyy').format(order.orderDate)),
            _buildInfoRow('Seller', order.sellerName),
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
              final isLast = index == _trackingDetails!.trackingTimeline.length - 1;
              
              return _buildTimelineItem(timeline, isLast);
            }).toList(),
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
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: timeline.completed ? AppTheme.success : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getTimelineIcon(timeline.status),
                color: timeline.completed ? Colors.white : Colors.grey[600],
                size: 18,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: timeline.completed ? AppTheme.success : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timeline.status,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: timeline.completed ? AppTheme.success : AppTheme.textGrey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeline.message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textGrey,
                ),
              ),
              if (timeline.timestamp != null) ...[
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy - HH:mm').format(timeline.timestamp!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
              if (!isLast) const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryEstimateCard() {
    if (_trackingDetails!.estimatedDelivery == null) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: AppTheme.primaryGreen),
                const SizedBox(width: 12),
                Text(
                  'Estimated Delivery',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_shipping, color: AppTheme.primaryGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM dd, yyyy').format(_trackingDetails!.estimatedDelivery!),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        Text(
                          'Your order is expected to arrive by this date',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ],
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

  Widget _buildActionButtonsCard() {
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Copy tracking ID to clipboard
                      Clipboard.setData(ClipboardData(text: _trackingController.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tracking ID copied to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy ID'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Navigate to contact seller or support
                    },
                    icon: const Icon(Icons.support_agent),
                    label: const Text('Support'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    
    switch (status.toLowerCase()) {
      case 'delivered':
        color = AppTheme.success;
        icon = Icons.check_circle;
        break;
      case 'shipped':
        color = AppTheme.info;
        icon = Icons.local_shipping;
        break;
      case 'processing':
        color = AppTheme.warning;
        icon = Icons.inventory;
        break;
      case 'cancelled':
        color = AppTheme.error;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.schedule;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textGrey,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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
      case 'delivered':
        return Icons.home;
      default:
        return Icons.circle;
    }
  }
}