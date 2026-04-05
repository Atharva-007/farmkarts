import 'package:flutter/material.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart' as order_model;
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';

class OrderDetailPage extends StatefulWidget {
  final String? productId;
  final String? orderId;

  const OrderDetailPage({
    super.key,
    this.productId,
    this.orderId,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final OrderService _orderService = OrderService();
  bool _isLoading = true;
  List<order_model.OrderModel> _orders = [];
  order_model.OrderModel? _specificOrder;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      if (widget.orderId != null) {
        // Load specific order
        _specificOrder = await _orderService.getOrder(widget.orderId!);
      } else if (widget.productId != null) {
        // Load orders for a specific product (seller view)
        final sellerOrders = await _orderService.getSellerOrdersStream().first;
        _orders = sellerOrders
            .where((order) => order.productId == widget.productId)
            .toList();
      } else {
        // Load all seller orders
        final sellerOrders = await _orderService.getSellerOrdersStream().first;
        _orders = sellerOrders;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading orders: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.orderId != null ? 'Order Details' : 'Product Orders'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : widget.orderId != null
              ? _buildOrderDetails()
              : _buildOrdersList(),
    );
  }

  Widget _buildOrderDetails() {
    if (_specificOrder == null) {
      return const Center(
        child: Text('Order not found'),
      );
    }

    return SingleChildScrollView(
      padding: AppConstants.defaultPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderCard(_specificOrder!),
          const SizedBox(height: 20),
          _buildStatusTimeline(_specificOrder!),
          const SizedBox(height: 20),
          _buildOrderActions(_specificOrder!),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_orders.isEmpty) {
      return const Center(
        child: Text('No orders found for this product'),
      );
    }

    return ListView.builder(
      padding: AppConstants.defaultPadding,
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(order_model.OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                _buildStatusChip(order.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppTheme.lightGreen.withValues(alpha: 0.2),
                  ),
                  child: order.productImageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            order.productImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.agriculture,
                                color: AppTheme.primaryGreen,
                                size: 24,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.agriculture,
                          color: AppTheme.primaryGreen,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.productName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Buyer: ${order.buyerName}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quantity: ${order.quantity} ${order.unit}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textGrey,
                            ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${order.totalAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      _formatDate(order.orderDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textGrey,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.notes!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showContactDialog(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.skyBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Contact Buyer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showUpdateStatusDialog(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Update Status'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(order_model.OrderStatus status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case order_model.OrderStatus.pending:
        backgroundColor = AppTheme.warning.withValues(alpha: 0.2);
        textColor = AppTheme.warning;
        break;
      case order_model.OrderStatus.confirmed:
        backgroundColor = AppTheme.skyBlue.withValues(alpha: 0.2);
        textColor = AppTheme.skyBlue;
        break;
      case order_model.OrderStatus.delivered:
        backgroundColor = AppTheme.success.withValues(alpha: 0.2);
        textColor = AppTheme.success;
        break;
      case order_model.OrderStatus.cancelled:
        backgroundColor = AppTheme.error.withValues(alpha: 0.2);
        textColor = AppTheme.error;
        break;
      default:
        backgroundColor = AppTheme.primaryGreen.withValues(alpha: 0.2);
        textColor = AppTheme.primaryGreen;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(order_model.OrderModel order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Timeline',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...order.statusUpdates.map((update) => _buildTimelineItem(update)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(order_model.OrderStatusUpdate update) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  update.status.displayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  update.message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(update.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textGrey,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderActions(order_model.OrderModel order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showContactDialog(order),
                    icon: const Icon(Icons.phone),
                    label: const Text('Contact Buyer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.skyBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addOrderNote(order),
                    icon: const Icon(Icons.note_add),
                    label: const Text('Add Note'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warning,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (order.status != order_model.OrderStatus.delivered &&
                order.status != order_model.OrderStatus.cancelled) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showUpdateStatusDialog(order),
                  icon: const Icon(Icons.update),
                  label: const Text('Update Order Status'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showContactDialog(order_model.OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Buyer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${order.buyerName}'),
            const SizedBox(height: 8),
            Text('Phone: ${order.buyerPhone}'),
            const SizedBox(height: 8),
            Text('Address: ${order.buyerAddress}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Here you could implement actual calling functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Call functionality would be implemented here')),
              );
            },
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog(order_model.OrderModel order) {
    final statuses = order_model.OrderStatus.values.where((status) {
      // Only show valid next statuses
      switch (order.status) {
        case order_model.OrderStatus.pending:
          return [
            order_model.OrderStatus.confirmed,
            order_model.OrderStatus.cancelled,
          ].contains(status);
        case order_model.OrderStatus.confirmed:
          return [
            order_model.OrderStatus.processing,
            order_model.OrderStatus.cancelled,
          ].contains(status);
        case order_model.OrderStatus.processing:
          return [
            order_model.OrderStatus.shipped,
            order_model.OrderStatus.cancelled,
          ].contains(status);
        case order_model.OrderStatus.shipped:
          return [
            order_model.OrderStatus.outForDelivery,
            order_model.OrderStatus.delivered,
          ].contains(status);
        case order_model.OrderStatus.outForDelivery:
          return [order_model.OrderStatus.delivered].contains(status);
        default:
          return false;
      }
    }).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses
              .map((status) => ListTile(
                    title: Text(status.displayName),
                    subtitle: Text(status.description),
                    onTap: () {
                      Navigator.pop(context);
                      _updateOrderStatus(order, status);
                    },
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _updateOrderStatus(
      order_model.OrderModel order, order_model.OrderStatus newStatus) async {
    try {
      await _orderService.updateOrderStatus(
        orderId: order.id,
        newStatus: newStatus,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order status updated successfully')),
      );

      _loadData(); // Refresh the data
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  void _addOrderNote(order_model.OrderModel order) {
    final noteController = TextEditingController(text: order.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add/Edit Note'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            hintText: 'Enter order note...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _orderService.addOrderNote(order.id, noteController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Note updated successfully')),
                );
                _loadData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update note: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
