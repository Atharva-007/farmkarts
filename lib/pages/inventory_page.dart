import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';
import '../utils/toast_helper.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Production-ready Inventory Management Page
class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TabController _tabController;
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  String _sortBy = 'date_desc';

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];

  // Statistics
  int _totalProducts = 0;
  int _activeProducts = 0;
  int _lowStockProducts = 0;
  double _totalValue = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInventory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load inventory asynchronously
  Future<void> _loadInventory() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final products = snapshot.docs
          .map((doc) => Product.fromMap(doc.data()))
          .toList();

      if (mounted) {
        setState(() {
          _allProducts = products;
          _filteredProducts = products;
          _calculateStatistics();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ToastHelper.showError(context, 'Failed to load inventory: $e');
      }
    }
  }

  /// Calculate inventory statistics
  void _calculateStatistics() {
    _totalProducts = _allProducts.length;
    _activeProducts = _allProducts.where((p) => p.isAvailable).length;
    _lowStockProducts =
        _allProducts.where((p) => p.quantity < 10).length;
    _totalValue = _allProducts.fold(
      0,
      (sum, p) => sum + (p.price * p.quantity),
    );
  }

  /// Filter and search products
  void _applyFiltersAndSearch() {
    var filtered = List<Product>.from(_allProducts);

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.category.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply filter
    switch (_selectedFilter) {
      case 'active':
        filtered = filtered.where((p) => p.isAvailable).toList();
        break;
      case 'inactive':
        filtered = filtered.where((p) => !p.isAvailable).toList();
        break;
      case 'low_stock':
        filtered = filtered.where((p) => p.quantity < 10).toList();
        break;
      case 'out_of_stock':
        filtered = filtered.where((p) => p.quantity == 0).toList();
        break;
    }

    // Apply sorting
    switch (_sortBy) {
      case 'date_desc':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'date_asc':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'name_asc':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'name_desc':
        filtered.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'price_asc':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'stock_asc':
        filtered.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case 'stock_desc':
        filtered.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
    }

    setState(() => _filteredProducts = filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.inventory_2, size: 20)),
            Tab(text: 'Active', icon: Icon(Icons.check_circle, size: 20)),
            Tab(text: 'Low Stock', icon: Icon(Icons.warning, size: 20)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics, size: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddProduct(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllProductsTab(),
                _buildActiveProductsTab(),
                _buildLowStockTab(),
                _buildAnalyticsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddProduct(),
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  Widget _buildAllProductsTab() {
    return Column(
      children: [
        _buildSearchBar(),
        _buildStatisticsCards(),
        Expanded(
          child: _filteredProducts.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadInventory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      return _buildProductCard(_filteredProducts[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildActiveProductsTab() {
    final activeProducts =
        _filteredProducts.where((p) => p.isAvailable).toList();

    return activeProducts.isEmpty
        ? _buildEmptyState(message: 'No active products')
        : RefreshIndicator(
            onRefresh: _loadInventory,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activeProducts.length,
              itemBuilder: (context, index) {
                return _buildProductCard(activeProducts[index]);
              },
            ),
          );
  }

  Widget _buildLowStockTab() {
    final lowStockProducts =
        _filteredProducts.where((p) => p.quantity < 10).toList();

    return Column(
      children: [
        if (lowStockProducts.isNotEmpty)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${lowStockProducts.length} products running low on stock',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: lowStockProducts.isEmpty
              ? _buildEmptyState(message: 'All products well stocked!')
              : RefreshIndicator(
                  onRefresh: _loadInventory,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: lowStockProducts.length,
                    itemBuilder: (context, index) {
                      return _buildProductCard(lowStockProducts[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return RefreshIndicator(
      onRefresh: _loadInventory,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnalyticsCard(
              'Total Products',
              _totalProducts.toString(),
              Icons.inventory_2,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildAnalyticsCard(
              'Active Products',
              _activeProducts.toString(),
              Icons.check_circle,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildAnalyticsCard(
              'Low Stock Alerts',
              _lowStockProducts.toString(),
              Icons.warning,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildAnalyticsCard(
              'Total Inventory Value',
              '₹${_totalValue.toStringAsFixed(2)}',
              Icons.attach_money,
              Colors.purple,
            ),
            const SizedBox(height: 24),
            const Text(
              'Category Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildCategoryBreakdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _applyFiltersAndSearch();
        },
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() => _searchQuery = '');
                    _applyFiltersAndSearch();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildStatCard('Total', _totalProducts, Colors.blue),
          _buildStatCard('Active', _activeProducts, Colors.green),
          _buildStatCard('Low Stock', _lowStockProducts, Colors.orange),
          _buildStatCard(
            'Value',
            '₹${(_totalValue / 1000).toStringAsFixed(1)}K',
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, dynamic value, Color color) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final stockColor = product.quantity == 0
        ? Colors.red
        : product.quantity < 10
            ? Colors.orange
            : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showProductDetails(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrls.isNotEmpty
                      ? product.imageUrls[0]
                      : '',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: product.isAvailable
                                ? Colors.green.shade50
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.isAvailable ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: product.isAvailable
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.currency_rupee,
                            size: 16, color: Colors.grey[600]),
                        Text(
                          product.price.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: stockColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2,
                                  size: 14, color: stockColor),
                              const SizedBox(width: 4),
                              Text(
                                '${product.quantity} ${product.unit}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: stockColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action Buttons
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _editProduct(product),
                    color: Colors.blue,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => _deleteProduct(product),
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
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

  Widget _buildCategoryBreakdown() {
    final categoryMap = <String, int>{};
    for (var product in _allProducts) {
      categoryMap[product.category] =
          (categoryMap[product.category] ?? 0) + 1;
    }

    return Column(
      children: categoryMap.entries.map((entry) {
        final percentage =
            (_allProducts.isEmpty ? 0 : (entry.value / _totalProducts) * 100);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey[200],
                  color: AppTheme.primaryGreen,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState({String message = 'No products found'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddProduct(),
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter & Sort'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Filter by:'),
            RadioListTile(
              title: const Text('All'),
              value: 'all',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                _applyFiltersAndSearch();
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('Active'),
              value: 'active',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                _applyFiltersAndSearch();
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('Inactive'),
              value: 'inactive',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                _applyFiltersAndSearch();
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('Low Stock'),
              value: 'low_stock',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                _applyFiltersAndSearch();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetails(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.category,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildDetailChip(
                    '₹${product.price}',
                    Icons.currency_rupee,
                    Colors.green,
                  ),
                  const SizedBox(width: 12),
                  _buildDetailChip(
                    '${product.quantity} ${product.unit}',
                    Icons.inventory_2,
                    Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(product.description),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _editProduct(product);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _toggleAvailability(product);
                      },
                      icon: Icon(
                        product.isAvailable
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      label: Text(
                        product.isAvailable ? 'Deactivate' : 'Activate',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: product.isAvailable
                            ? Colors.orange
                            : AppTheme.primaryGreen,
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

  Widget _buildDetailChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAvailability(Product product) async {
    try {
      await _firestore.collection('products').doc(product.id).update({
        'isAvailable': !product.isAvailable,
      });
      
      if (mounted) {
        ToastHelper.showSuccess(
          context,
          product.isAvailable
              ? 'Product deactivated'
              : 'Product activated',
        );
        _loadInventory();
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Failed to update product: $e');
      }
    }
  }

  void _navigateToAddProduct() {
    // Navigate to add product page
    ToastHelper.showInfo(context, 'Add product page');
  }

  void _editProduct(Product product) {
    // Navigate to edit product page
    ToastHelper.showInfo(context, 'Edit product: ${product.name}');
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _firestore.collection('products').doc(product.id).delete();
        
        if (mounted) {
          ToastHelper.showSuccess(context, 'Product deleted successfully');
          _loadInventory();
        }
      } catch (e) {
        if (mounted) {
          ToastHelper.showError(context, 'Failed to delete product: $e');
        }
      }
    }
  }
}
