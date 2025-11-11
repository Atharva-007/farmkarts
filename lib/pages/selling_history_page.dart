import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/marketplace_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';

class SellingHistoryPage extends StatefulWidget {
  const SellingHistoryPage({super.key});

  @override
  State<SellingHistoryPage> createState() => _SellingHistoryPageState();
}

class _SellingHistoryPageState extends State<SellingHistoryPage> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final MarketplaceService _marketplaceService = MarketplaceService();
  List<Map<String, dynamic>> _sellingHistory = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;
  String? _error;
  
  String _selectedFilter = 'all';
  final List<String> _filterOptions = [
    'all', 'active', 'sold_out', 'paused', 'removed'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _animationController.forward();
    _loadSellingHistory();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSellingHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Please login to view selling history';
          _isLoading = false;
        });
        return;
      }

      // Use MarketplaceService method
      final history = await _marketplaceService.getSellingHistoryByUser(user.uid);
      
      // Filter by selected filter
      List<Map<String, dynamic>> filteredHistory = history;
      if (_selectedFilter != 'all') {
        filteredHistory = history.where((item) => item['status'] == _selectedFilter).toList();
      }

      // Calculate summary
      final totalRevenue = history.fold<double>(
        0, (sum, item) => sum + ((item['totalRevenue'] ?? 0).toDouble())
      );
      final totalListings = history.length;
      final activeListings = history.where((item) => item['status'] == 'active').length;
      final soldOutListings = history.where((item) => item['status'] == 'sold_out').length;

      setState(() {
        _sellingHistory = filteredHistory;
        _summary = {
          'totalRevenue': totalRevenue,
          'totalListings': totalListings,
          'activeListings': activeListings,
          'soldOutListings': soldOutListings,
          'avgRevenuePerListing': totalListings > 0 ? totalRevenue / totalListings : 0.0,
        };
        _isLoading = false;
      });

    } catch (e) {
      print('Error loading selling history: $e');
      setState(() {
        _error = 'Failed to load selling history: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _showProductDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProductDetailsSheet(item),
    );
  }

  Widget _buildProductDetailsSheet(Map<String, dynamic> item) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item['productName'] ?? 'Product Details',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Product ID', item['productId'] ?? 'N/A'),
                  _buildDetailRow('Category', item['category'] ?? 'N/A'),
                  _buildDetailRow('Status', _getStatusText(item['status'] ?? 'unknown')),
                  _buildDetailRow('Initial Price', '₹${item['initialPrice']?.toString() ?? '0'}'),
                  _buildDetailRow('Current Price', '₹${item['currentPrice']?.toString() ?? '0'}'),
                  _buildDetailRow('Total Quantity', '${item['totalQuantity']?.toString() ?? '0'}'),
                  _buildDetailRow('Sold Quantity', '${item['soldQuantity']?.toString() ?? '0'}'),
                  _buildDetailRow('Available Quantity', '${item['availableQuantity']?.toString() ?? '0'}'),
                  _buildDetailRow('Total Revenue', '₹${item['totalRevenue']?.toString() ?? '0'}'),
                  _buildDetailRow('Total Views', '${item['totalViews']?.toString() ?? '0'}'),
                  _buildDetailRow('Total Inquiries', '${item['totalInquiries']?.toString() ?? '0'}'),
                  _buildDetailRow('Listed Date', _formatDate(item['listedDate'])),
                  if (item['lastSoldDate'] != null)
                    _buildDetailRow('Last Sold Date', _formatDate(item['lastSoldDate'])),
                  const SizedBox(height: 20),
                  _buildPerformanceMetrics(item),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(Map<String, dynamic> item) {
    final totalQuantity = (item['totalQuantity'] ?? 0).toDouble();
    final soldQuantity = (item['soldQuantity'] ?? 0).toDouble();
    final totalViews = (item['totalViews'] ?? 0).toDouble();
    final totalInquiries = (item['totalInquiries'] ?? 0).toDouble();

    final sellThroughRate = totalQuantity > 0 ? (soldQuantity / totalQuantity) * 100 : 0.0;
    final inquiryRate = totalViews > 0 ? (totalInquiries / totalViews) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Metrics',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 12),
          _buildMetricRow('Sell-through Rate', '${sellThroughRate.toStringAsFixed(1)}%'),
          _buildMetricRow('Inquiry Rate', '${inquiryRate.toStringAsFixed(1)}%'),
          _buildMetricRow('Revenue per Unit', totalQuantity > 0 
            ? '₹${((item['totalRevenue'] ?? 0) / totalQuantity).toStringAsFixed(2)}' 
            : '₹0.00'),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'sold_out':
        return 'Sold Out';
      case 'paused':
        return 'Paused';
      case 'removed':
        return 'Removed';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppTheme.success;
      case 'sold_out':
        return AppTheme.warning;
      case 'paused':
        return AppTheme.info;
      case 'removed':
        return AppTheme.error;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'active':
        return Icons.check_circle;
      case 'sold_out':
        return Icons.inventory_2;
      case 'paused':
        return Icons.pause_circle;
      case 'removed':
        return Icons.remove_circle;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('My Selling History'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadSellingHistory,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
              _loadSellingHistory();
            },
            itemBuilder: (context) => _filterOptions.map((filter) {
              return PopupMenuItem(
                value: filter,
                child: Row(
                  children: [
                    if (_selectedFilter == filter)
                      Icon(Icons.check, color: AppTheme.primaryGreen, size: 20)
                    else
                      const SizedBox(width: 20),
                    const SizedBox(width: 8),
                    Text(_getStatusText(filter)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildBody(),
      ),
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
            Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadSellingHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_sellingHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Products Listed Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start selling by adding your first product',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/add_product');
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSummaryCard(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadSellingHistory,
            color: AppTheme.primaryGreen,
            child: ListView.builder(
              padding: AppConstants.defaultPadding,
              itemCount: _sellingHistory.length,
              itemBuilder: (context, index) {
                final item = _sellingHistory[index];
                return _buildSellingHistoryCard(item);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: AppConstants.defaultPadding,
      child: Card(
        child: Padding(
          padding: AppConstants.defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Summary',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Total Revenue',
                      '₹${_summary['totalRevenue']?.toStringAsFixed(2) ?? '0.00'}',
                      Icons.currency_rupee,
                      AppTheme.success,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'Total Listings',
                      '${_summary['totalListings'] ?? 0}',
                      Icons.inventory,
                      AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Active',
                      '${_summary['activeListings'] ?? 0}',
                      Icons.check_circle,
                      AppTheme.success,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'Sold Out',
                      '${_summary['soldOutListings'] ?? 0}',
                      Icons.inventory_2,
                      AppTheme.warning,
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

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSellingHistoryCard(Map<String, dynamic> item) {
    final status = item['status'] ?? 'unknown';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showProductDetails(item),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item['productName'] ?? 'Unknown Product',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(status),
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item['category'] ?? 'Unknown Category',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoColumn(
                      'Price',
                      '₹${item['currentPrice']?.toString() ?? '0'}',
                      Icons.currency_rupee,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoColumn(
                      'Available',
                      '${item['availableQuantity']?.toString() ?? '0'}',
                      Icons.inventory,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoColumn(
                      'Revenue',
                      '₹${item['totalRevenue']?.toString() ?? '0'}',
                      Icons.trending_up,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.visibility, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${item['totalViews'] ?? 0} views',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.message, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${item['totalInquiries'] ?? 0} inquiries',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Listed ${_formatDate(item['listedDate'])}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
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

  Widget _buildInfoColumn(String title, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}