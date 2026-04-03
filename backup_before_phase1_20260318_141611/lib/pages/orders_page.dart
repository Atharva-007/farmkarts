import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';
import '../widgets/universal_drawer.dart';
import 'order_tracking_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with TickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _selectedFilter = 'all';
  List<OrderModel> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadOrders();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final orders = await _orderService.searchOrders('', forSeller: false);
        if (mounted) {
          setState(() {
            _orders = orders;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load orders: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  List<OrderModel> get _filteredOrders {
    switch (_selectedFilter) {
      case 'processing':
        return _orders.where((orderItem) => orderItem.status == OrderStatus.processing).toList();
      case 'pending':
        return _orders.where((orderItem) => orderItem.status == OrderStatus.pending).toList();
      case 'confirmed':
        return _orders.where((orderItem) => orderItem.status == OrderStatus.confirmed).toList();
      case 'shipped':
        return _orders.where((orderItem) => orderItem.status == OrderStatus.shipped).toList();
      case 'delivered':
        return _orders.where((orderItem) => orderItem.status == OrderStatus.delivered || orderItem.status == OrderStatus.outForDelivery).toList();
      case 'cancelled':
        return _orders.where((orderItem) => orderItem.status == OrderStatus.cancelled || orderItem.status == OrderStatus.refunded).toList();
      default:
        return _orders;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      drawer: const UniversalDrawer(currentPage: 'orders'),
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
            tooltip: 'Refresh Orders',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Filter Tabs
              _buildFilterTabs(),
              
              // Orders List
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _filteredOrders.isEmpty
                        ? _buildEmptyState()
                        : _buildOrdersList(isMobile),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      {'key': 'all', 'label': 'All', 'icon': Icons.list_alt},
      {'key': 'pending', 'label': 'Pending', 'icon': Icons.pending},
      {'key': 'confirmed', 'label': 'Confirmed', 'icon': Icons.check_circle},
      {'key': 'shipped', 'label': 'Shipped', 'icon': Icons.local_shipping},
      {'key': 'delivered', 'label': 'Delivered', 'icon': Icons.done_all},
      {'key': 'cancelled', 'label': 'Cancelled', 'icon': Icons.cancel},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        filter['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : AppTheme.primaryGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(filter['label'] as String),
                    ],
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter['key'] as String;
                    });
                  },
                  selectedColor: AppTheme.primaryGreen,
                  backgroundColor: Colors.grey[100],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryGreen),
          const SizedBox(height: 16),
          Text(
            'Loading your orders...',
            style: TextStyle(
              color: AppTheme.textGrey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'all'
                ? 'No orders yet'
                : 'No ${_selectedFilter} orders',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'all'
                ? 'Start shopping to see your orders here'
                : 'No orders with this status found',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          if (_selectedFilter == 'all') ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Start Shopping'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrdersList(bool isMobile) {
    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: AppTheme.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredOrders.length,
        itemBuilder: (context, index) {
          final OrderModel = _filteredOrders[index];
          return AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: Curves.easeOutBack,
            child: _buildOrderCard(OrderModel, isMobile),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel orderItem, bool isMobile) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _viewOrderDetails(orderItem),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // OrderModel Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OrderModel #${orderItem.id.substring(0, 8)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          orderItem.productName,
                          style: TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(orderItem.status),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // OrderModel Progress
              _buildOrderProgress(orderItem.status),
              
              const SizedBox(height: 12),
              
              // OrderModel Details
              Row(
                children: [
                  Expanded(
                    child: _buildOrderInfo('Quantity', '${orderItem.quantity} ${orderItem.unit}'),
                  ),
                  Expanded(
                    child: _buildOrderInfo('Total', '₹${orderItem.totalAmount.toStringAsFixed(0)}'),
                  ),
                  Expanded(
                    child: _buildOrderInfo('Date', _formatDate(orderItem.createdAt)),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewOrderDetails(orderItem),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        side: BorderSide(color: AppTheme.primaryGreen),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _trackOrder(orderItem),
                      icon: const Icon(Icons.track_changes, size: 16),
                      label: const Text('Track OrderModel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        icon = Icons.pending;
        break;
      case OrderStatus.processing:
        color = Colors.blue;
        icon = Icons.hourglass_top;
        break;
      case OrderStatus.confirmed:
        color = Colors.blue;
        icon = Icons.check_circle;
        break;
      case OrderStatus.shipped:
        color = Colors.purple;
        icon = Icons.local_shipping;
        break;
      case OrderStatus.outForDelivery:
        color = Colors.indigo;
        icon = Icons.delivery_dining;
        break;
      case OrderStatus.delivered:
        color = AppTheme.success;
        icon = Icons.done_all;
        break;
      case OrderStatus.cancelled:
        color = AppTheme.error;
        icon = Icons.cancel;
        break;
      case OrderStatus.refunded:
        color = Colors.grey;
        icon = Icons.money_off;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            status.toString().split('.').last.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderProgress(OrderStatus status) {
    final steps = [
      OrderStatus.pending,
      OrderStatus.processing,
      OrderStatus.confirmed,
      OrderStatus.shipped,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
    ];
    
    final currentStepIndex = status == OrderStatus.cancelled || status == OrderStatus.refunded
        ? 0 
        : steps.indexOf(status) + 1;
    
    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index < currentStepIndex;
        final isCancelled = status == OrderStatus.cancelled;
        
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isCancelled 
                      ? AppTheme.error 
                      : isActive 
                          ? AppTheme.primaryGreen 
                          : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCancelled
                      ? Icons.close
                      : isActive
                          ? Icons.check
                          : Icons.circle,
                  color: Colors.white,
                  size: 12,
                ),
              ),
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCancelled 
                        ? AppTheme.error 
                        : isActive 
                            ? AppTheme.primaryGreen 
                            : Colors.grey[300],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildOrderInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textGrey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _viewOrderDetails(OrderModel orderItem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOrderDetailsSheet(orderItem),
    );
  }

  Widget _buildOrderDetailsSheet(OrderModel orderItem) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'OrderModel Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // OrderModel Info
                      _buildDetailSection('OrderModel Information', [
                        _buildDetailItem('OrderModel ID', orderItem.id),
                        _buildDetailItem('Product', orderItem.productName),
                        _buildDetailItem('Quantity', '${orderItem.quantity} ${orderItem.unit}'),
                        _buildDetailItem('Total Amount', '₹${orderItem.totalAmount}'),
                        _buildDetailItem('Payment Method', orderItem.paymentMethod ?? 'Not specified'),
                        _buildDetailItem('OrderModel Date', orderItem.createdAt.toString()),
                      ]),
                      
                      const SizedBox(height: 20),
                      
                      // Delivery Info
                      _buildDetailSection('Delivery Information', [
                        _buildDetailItem('Type', orderItem.deliveryType.toString().split('.').last),
                        if (orderItem.buyerAddress.isNotEmpty)
                          _buildDetailItem('Address', orderItem.buyerAddress),
                        _buildDetailItem('Phone', orderItem.buyerPhone),
                        if (orderItem.notes != null && orderItem.notes!.isNotEmpty)
                          _buildDetailItem('Notes', orderItem.notes!),
                      ]),
                      
                      const SizedBox(height: 20),
                      
                      // Seller Info
                      _buildDetailSection('Seller Information', [
                        _buildDetailItem('Seller ID', orderItem.sellerId),
                        // Add more seller details as needed
                      ]),
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _trackOrder(OrderModel orderItem) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderTrackingPage(order: orderItem),
      ),
    );
  }
}
