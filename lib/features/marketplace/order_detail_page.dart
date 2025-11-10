import 'package:flutter/material.dart';
import '../../models/order_model.dart' as OrderModelFile;
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';

class OrderDetailPage extends StatefulWidget {
  final String productId;

  const OrderDetailPage({super.key, required this.productId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final OrderService _orderService = OrderService();
  List<OrderModelFile.OrderModel> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() => _isLoading = true);
      
      // Get all orders for the seller and filter by product
      final allOrders = await _orderService.searchOrders('', forSeller: true);
      _orders = allOrders.where((order) => order.productId == widget.productId).toList();
      
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
        title: const Text('Product Orders'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No orders found for this product'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return _buildOrderCard(order);
                  },
                ),
    );
  }

  Widget _buildOrderCard(OrderModelFile.OrderModel order) {
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                _buildStatusChip(order.status),
              ],
            ),
            const SizedBox(height: 12),
            
            _buildInfoRow('Buyer', order.buyerName),
            _buildInfoRow('Phone', order.buyerPhone),
            _buildInfoRow('Address', order.buyerAddress),
            _buildInfoRow('Quantity', '${order.quantity} ${order.unit}'),
            _buildInfoRow('Total Amount', '₹${order.totalAmount}'),
            _buildInfoRow('Order Date', _formatDate(order.orderDate)),
            
            if (order.notes != null && order.notes!.isNotEmpty)
              _buildInfoRow('Notes', order.notes!),
            
            const SizedBox(height: 16),
            
            if (order.status == OrderModelFile.OrderStatus.pending)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateOrderStatus(order, OrderModelFile.OrderStatus.confirmed),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Accept'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showCancelDialog(order),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              )
            else if (order.status == OrderModelFile.OrderStatus.confirmed)
              ElevatedButton(
                onPressed: () => _updateOrderStatus(order, OrderModelFile.OrderStatus.shipped),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                child: const Text('Mark as Shipped'),
              )
            else if (order.status == OrderModelFile.OrderStatus.shipped)
              ElevatedButton(
                onPressed: () => _updateOrderStatus(order, OrderModelFile.OrderStatus.delivered),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Mark as Delivered'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(OrderModelFile.OrderStatus status) {
    Color color;
    switch (status) {
      case OrderModelFile.OrderStatus.pending:
        color = Colors.orange;
        break;
      case OrderModelFile.OrderStatus.confirmed:
        color = Colors.blue;
        break;
      case OrderModelFile.OrderStatus.shipped:
        color = Colors.purple;
        break;
      case OrderModelFile.OrderStatus.delivered:
        color = Colors.green;
        break;
      case OrderModelFile.OrderStatus.cancelled:
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status.displayName,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  Future<void> _updateOrderStatus(OrderModelFile.OrderModel order, OrderModelFile.OrderStatus newStatus) async {
    try {
      await _orderService.updateOrderStatus(
        orderId: order.id,
        newStatus: newStatus,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to ${newStatus.displayName}')),
      );
      
      _loadOrders(); // Refresh the orders
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating order: $e')),
      );
    }
  }

  void _showCancelDialog(OrderModelFile.OrderModel order) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for cancellation:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Cancellation reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelOrder(order, reasonController.text.trim());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(OrderModelFile.OrderModel order, String reason) async {
    try {
      await _orderService.cancelOrder(order.id, reason.isNotEmpty ? reason : 'Cancelled by seller');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled successfully')),
      );
      
      _loadOrders(); // Refresh the orders
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling order: $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}