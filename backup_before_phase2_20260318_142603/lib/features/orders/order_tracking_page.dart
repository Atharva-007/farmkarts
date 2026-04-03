import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/order_model.dart' as OrderModels;
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';
import 'order_detail_page.dart';

class OrderTrackingPage extends StatefulWidget {
  final bool forSeller;

  const OrderTrackingPage({
    super.key,
    this.forSeller = false,
  });

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage>
    with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  late TabController _tabController;
  
  final List<OrderModels.OrderStatus> _statuses = [
    OrderModels.OrderStatus.pending,
    OrderModels.OrderStatus.confirmed,
    OrderModels.OrderStatus.processing,
    OrderModels.OrderStatus.shipped,
    OrderModels.OrderStatus.delivered,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(widget.forSeller ? 'Manage Orders' : 'My Orders'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _statuses.map((status) => Tab(
            text: status.displayName,
          )).toList(),
        ),
      ),
      body: Column(
        children: [
          _buildOrderStats(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _statuses.map((status) => _buildOrderList(status)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStats() {
    return FutureBuilder<Map<String, dynamic>>(
      future: widget.forSeller 
          ? _orderService.getSellerOrderStats() 
          : _orderService.getBuyerOrderStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final stats = snapshot.data!;
        
        return Container(
          padding: AppConstants.defaultPadding,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total Orders',
                stats['totalOrders'].toString(),
                Icons.shopping_cart,
              ),
              _buildStatItem(
                widget.forSeller ? 'Pending' : 'Active',
                (stats['pendingOrders'] ?? stats['activeOrders']).toString(),
                Icons.pending,
              ),
              _buildStatItem(
                'Completed',
                stats['completedOrders'].toString(),
                Icons.check_circle,
              ),
              if (widget.forSeller)
                _buildStatItem(
                  'Revenue',
                  '₹${(stats['totalRevenue'] as double).toStringAsFixed(0)}',
                  Icons.currency_rupee,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textGrey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderList(OrderModels.OrderStatus status) {
    return StreamBuilder<List<OrderModels.OrderModel>>(
      stream: _orderService.getOrdersByStatus(status, forSeller: widget.forSeller),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: AppTheme.textGrey),
                const SizedBox(height: 16),
                Text(
                  'Error loading orders',
                  style: TextStyle(color: AppTheme.textGrey),
                ),
                TextButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return _buildEmptyState(status);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(OrderModels.OrderModel order) {
    final isFromCurrentUser = widget.forSeller;
    final otherUserName = widget.forSeller ? order.buyerName : order.sellerName;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openOrderDetail(order),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.forSeller ? 'Buyer' : 'Seller'}: $otherUserName',
                          style: TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Order #${order.id.substring(0, 8)}...',
                          style: TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          order.status.displayName,
                          style: TextStyle(
                            color: _getStatusColor(order.status),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${order.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.shopping_cart, size: 16, color: AppTheme.textGrey),
                  const SizedBox(width: 4),
                  Text(
                    '${order.quantity} ${order.unit}',
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: AppTheme.textGrey),
                  const SizedBox(width: 4),
                  Text(
                    _formatOrderDate(order.orderDate),
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
                  ),
                  const Spacer(),
                  if (widget.forSeller && order.status == OrderModels.OrderStatus.pending)
                    TextButton(
                      onPressed: () => _confirmOrder(order),
                      child: const Text('Confirm'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(OrderModels.OrderStatus status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getStatusIcon(status),
            size: 64,
            color: AppTheme.textGrey,
          ),
          const SizedBox(height: 16),
          Text(
            'No ${status.displayName.toLowerCase()} orders',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.forSeller
                ? 'Orders will appear here when customers place orders'
                : 'Your ${status.displayName.toLowerCase()} orders will appear here',
            style: TextStyle(color: AppTheme.textGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderModels.OrderStatus status) {
    switch (status) {
      case OrderModels.OrderStatus.pending:
        return AppTheme.warning;
      case OrderModels.OrderStatus.confirmed:
      case OrderModels.OrderStatus.processing:
        return AppTheme.info;
      case OrderModels.OrderStatus.shipped:
      case OrderModels.OrderStatus.outForDelivery:
        return AppTheme.primaryGreen;
      case OrderModels.OrderStatus.delivered:
        return AppTheme.success;
      case OrderModels.OrderStatus.cancelled:
      case OrderModels.OrderStatus.refunded:
        return AppTheme.error;
    }
  }

  IconData _getStatusIcon(OrderModels.OrderStatus status) {
    switch (status) {
      case OrderModels.OrderStatus.pending:
        return Icons.pending;
      case OrderModels.OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case OrderModels.OrderStatus.processing:
        return Icons.settings;
      case OrderModels.OrderStatus.shipped:
        return Icons.local_shipping;
      case OrderModels.OrderStatus.delivered:
        return Icons.check_circle;
      case OrderModels.OrderStatus.cancelled:
        return Icons.cancel;
      case OrderModels.OrderStatus.refunded:
        return Icons.money_off;
      case OrderModels.OrderStatus.outForDelivery:
        return Icons.delivery_dining;
    }
  }

  String _formatOrderDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  void _openOrderDetail(OrderModels.OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailPage(
          orderId: order.id,
        ),
      ),
    );
  }

  void _confirmOrder(OrderModels.OrderModel order) async {
    try {
      await _orderService.updateOrderStatus(
        orderId: order.id,
        newStatus: OrderModels.OrderStatus.confirmed,
        message: 'Order confirmed by seller',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order confirmed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to confirm order: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
}