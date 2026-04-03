// Enhanced Selling Products List Widget
// Displays user's selling products with analytics and quick actions

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../models/marketplace_models.dart';
import '../../services/enhanced_marketplace_service.dart';
import '../../services/product_service.dart';
import '../../utils/responsive_helper.dart';
import 'enhanced_selling_product_detail_page.dart';
import 'add_product_page.dart';

class EnhancedSellingProductsList extends StatefulWidget {
  const EnhancedSellingProductsList({Key? key}) : super(key: key);

  @override
  State<EnhancedSellingProductsList> createState() => _EnhancedSellingProductsListState();
}

class _EnhancedSellingProductsListState extends State<EnhancedSellingProductsList> {
  final ProductService _productService = ProductService();
  final EnhancedMarketplaceService _marketplaceService = EnhancedMarketplaceService();
  
  List<Product> _products = [];
  List<SellingHistoryItem> _sellingHistory = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';

  final List<Map<String, dynamic>> _filters = [
    {'value': 'all', 'label': 'All Products', 'icon': Icons.inventory},
    {'value': 'active', 'label': 'Active', 'icon': Icons.trending_up},
    {'value': 'sold_out', 'label': 'Sold Out', 'icon': Icons.check_circle},
    {'value': 'paused', 'label': 'Paused', 'icon': Icons.pause_circle},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Load user's products and selling history in parallel
      final futures = await Future.wait([
        _productService.getProducts(sellerId: user.uid),
        _marketplaceService.getSellingHistory(user.uid),
      ]);

      setState(() {
        _products = futures[0] as List<Product>;
        _sellingHistory = futures[1] as List<SellingHistoryItem>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Product> get _filteredProducts {
    switch (_selectedFilter) {
      case 'active':
        return _products.where((p) => p.isAvailable && p.quantity > 0).toList();
      case 'sold_out':
        return _products.where((p) => !p.isAvailable || p.quantity == 0).toList();
      case 'paused':
        return _products.where((p) => !p.isAvailable).toList();
      default:
        return _products;
    }
  }

  SellingHistoryItem? _getSellingHistory(String productId) {
    try {
      return _sellingHistory.firstWhere((h) => h.productId == productId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorWidget()
                    : _filteredProducts.isEmpty
                        ? _buildEmptyState()
                        : _buildProductsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewProduct,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.store, color: AppTheme.primaryGreen, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Products',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_products.length} products listed',
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter['value'];
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter['icon'],
                    size: 16,
                    color: isSelected ? Colors.white : AppTheme.primaryGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(filter['label']),
                ],
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter['value'];
                });
              },
              selectedColor: AppTheme.primaryGreen,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.primaryGreen,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ResponsiveHelper.isMobile(context)
          ? _buildMobileList()
          : _buildGridView(),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        return _buildProductCard(_filteredProducts[index]);
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        return _buildProductCard(_filteredProducts[index]);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    final sellingHistory = _getSellingHistory(product.id);
    final statusColor = _getStatusColor(product);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToDetails(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: product.imageUrls.isNotEmpty
                        ? Image.network(
                            product.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppTheme.backgroundLight,
                                child: const Center(
                                  child: Icon(Icons.image, color: AppTheme.textGrey),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: AppTheme.backgroundLight,
                            child: const Center(
                              child: Icon(Icons.agriculture, color: AppTheme.primaryGreen, size: 32),
                            ),
                          ),
                  ),
                  // Status Badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(product),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category,
                      style: const TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '₹${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        Text(
                          '/${product.unit}',
                          style: const TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${product.quantity}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Analytics Row
                    if (sellingHistory != null) ...[
                      Row(
                        children: [
                          _buildMetricChip(
                            Icons.visibility,
                            sellingHistory.totalViews.toString(),
                            Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          _buildMetricChip(
                            Icons.people,
                            sellingHistory.totalInquiries.toString(),
                            Colors.orange,
                          ),
                          const Spacer(),
                          Text(
                            '₹${sellingHistory.totalRevenue.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          _buildMetricChip(Icons.visibility, '0', Colors.blue),
                          const SizedBox(width: 4),
                          _buildMetricChip(Icons.people, '0', Colors.orange),
                          const Spacer(),
                          const Text(
                            '₹0',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 8),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _editProduct(product),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                            ),
                            child: const Text('Edit', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _navigateToDetails(product),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              backgroundColor: AppTheme.primaryGreen,
                            ),
                            child: const Text('View', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedFilter == 'all' ? Icons.inventory_2_outlined : Icons.filter_list,
              size: 64,
              color: AppTheme.textGrey,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'all'
                  ? 'No Products Listed'
                  : 'No ${_filters.firstWhere((f) => f['value'] == _selectedFilter)['label']} Products',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'all'
                  ? 'Start selling by adding your first product'
                  : 'Try changing the filter or add new products',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textGrey,
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedFilter == 'all')
              ElevatedButton.icon(
                onPressed: _addNewProduct,
                icon: const Icon(Icons.add),
                label: const Text('Add Your First Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Products',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textGrey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(Product product) {
    if (!product.isAvailable) return Colors.red;
    if (product.quantity == 0) return Colors.orange;
    return Colors.green;
  }

  String _getStatusText(Product product) {
    if (!product.isAvailable) return 'PAUSED';
    if (product.quantity == 0) return 'SOLD OUT';
    return 'ACTIVE';
  }

  void _navigateToDetails(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedSellingProductDetailPage(product: product),
      ),
    ).then((value) {
      if (value == true) {
        _loadData();
      }
    });
  }

  void _editProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductPage(product: product),
      ),
    ).then((value) {
      if (value == true) {
        _loadData();
      }
    });
  }

  void _addNewProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductPage(),
      ),
    ).then((value) {
      if (value == true) {
        _loadData();
      }
    });
  }
}
