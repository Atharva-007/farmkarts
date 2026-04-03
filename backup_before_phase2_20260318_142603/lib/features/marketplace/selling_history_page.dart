import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/product_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';

class SellingHistoryPage extends StatefulWidget {
  const SellingHistoryPage({Key? key}) : super(key: key);

  @override
  State<SellingHistoryPage> createState() => _SellingHistoryPageState();
}

class _SellingHistoryPageState extends State<SellingHistoryPage> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final ProductService _productService = ProductService();
  final ScrollController _scrollController = ScrollController();
  
  List<dynamic> _sellingHistory = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String? _selectedStatus;
  String? _selectedCategory;
  
  final List<String> _statusFilters = [
    'All',
    'active',
    'sold_out',
    'expired', 
    'removed',
    'paused'
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadSellingHistory();
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
      curve: Curves.easeIn,
    ));
    _animationController.forward();
  }

  Future<void> _loadSellingHistory() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final result = await _productService.getSellingHistoryByUser(user.uid);
      
      if (mounted) {
        setState(() {
          _sellingHistory = result['history'] ?? [];
          _summary = result['summary'] ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading selling history: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> _getFilteredHistory() {
    List<dynamic> filtered = List.from(_sellingHistory);
    
    if (_selectedStatus != null && _selectedStatus != 'All') {
      filtered = filtered.where((item) => item['status'] == _selectedStatus).toList();
    }
    
    if (_selectedCategory != null && _selectedCategory != 'All') {
      filtered = filtered.where((item) => item['category'] == _selectedCategory).toList();
    }
    
    return filtered;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('My Products'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSellingHistory,
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
      return _buildLoadingWidget();
    }
    
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (_sellingHistory.isEmpty) {
      return _buildEmptyStateWidget();
    }

    return RefreshIndicator(
      onRefresh: _loadSellingHistory,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 16),
            _buildFiltersCard(),
            const SizedBox(height: 16),
            _buildHistoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.primaryGreen,
          ),
          SizedBox(height: 16),
          Text(
            'Loading your products...',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load selling history',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textGrey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadSellingHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return Center(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 96,
              color: AppTheme.textGrey,
            ),
            const SizedBox(height: 24),
            Text(
              'No Products Listed',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t listed any products yet.\nStart by adding your first product!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textGrey,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to add product page
                // This should be handled by parent widget or navigation
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Product'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
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
                    Icons.attach_money,
                    AppTheme.success,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Total Products',
                    '${_summary['totalListings'] ?? 0}',
                    Icons.inventory,
                    AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Active',
                    '${_summary['activeListings'] ?? 0}',
                    Icons.trending_up,
                    AppTheme.primaryGreen,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Sold Out',
                    '${_summary['soldOutListings'] ?? 0}',
                    Icons.check_circle,
                    AppTheme.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersCard() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _statusFilters.map((status) {
                      return DropdownMenuItem(
                        value: status == 'All' ? null : status,
                        child: Text(status == 'All' ? 'All Statuses' : status.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Categories')),
                      ...['Vegetables', 'Fruits', 'Grains', 'Seeds', 'Equipment', 'Dairy', 'Spices', 'Other']
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    final filteredHistory = _getFilteredHistory();
    
    if (filteredHistory.isEmpty) {
      return Card(
        child: Padding(
          padding: AppConstants.defaultPadding,
          child: Center(
            child: Text(
              'No products match the selected filters',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textGrey,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Products (${filteredHistory.length})',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...filteredHistory.map((item) => _buildHistoryItem(item)),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final performanceMetrics = item['performanceMetrics'] ?? {};
    final status = item['status'] ?? 'unknown';
    final statusColor = _getStatusColor(status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Product Image or Placeholder
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppTheme.lightGreen.withAlpha(100),
                  ),
                  child: item['imageUrl'] != null && item['imageUrl'].isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item['imageUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.image, color: AppTheme.textGrey);
                            },
                          ),
                        )
                      : const Icon(Icons.agriculture, color: AppTheme.primaryGreen, size: 30),
                ),
                const SizedBox(width: 12),
                
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['productName'] ?? 'Unknown Product',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item['category']} • ₹${item['currentPrice']?.toStringAsFixed(2)}/unit',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Performance Metrics
            Row(
              children: [
                _buildMetricChip(
                  'Views',
                  '${performanceMetrics['totalViews'] ?? 0}',
                  Icons.visibility,
                ),
                const SizedBox(width: 8),
                _buildMetricChip(
                  'Inquiries',
                  '${performanceMetrics['totalInquiries'] ?? 0}',
                  Icons.question_answer,
                ),
                const SizedBox(width: 8),
                _buildMetricChip(
                  'Revenue',
                  '₹${performanceMetrics['totalRevenue']?.toStringAsFixed(0) ?? '0'}',
                  Icons.currency_rupee,
                ),
                const SizedBox(width: 8),
                _buildMetricChip(
                  'Days Listed',
                  '${performanceMetrics['daysListed'] ?? 0}',
                  Icons.calendar_today,
                ),
              ],
            ),
            
            // Progress Bar for Sold Quantity
            if (item['originalQuantity'] != null && item['originalQuantity'] > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Sold: ${item['soldQuantity'] ?? 0}/${item['originalQuantity']}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textGrey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (item['soldQuantity'] ?? 0) / item['originalQuantity'],
                      backgroundColor: AppTheme.lightGreen.withAlpha(100),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        performanceMetrics['sellThroughRate'] != null && 
                        performanceMetrics['sellThroughRate'] > 80
                            ? AppTheme.success
                            : AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${performanceMetrics['sellThroughRate']?.toStringAsFixed(0) ?? '0'}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.lightGreen.withAlpha(50),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.primaryGreen),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppTheme.success;
      case 'sold_out':
        return AppTheme.warning;
      case 'expired':
        return AppTheme.error;
      case 'removed':
        return AppTheme.textGrey;
      case 'paused':
        return AppTheme.primaryBlue;
      default:
        return AppTheme.textGrey;
    }
  }
}