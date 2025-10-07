import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../widgets/search_filter_bar.dart';
import 'add_product_page.dart';

class MarketplaceHome extends StatefulWidget {
  const MarketplaceHome({super.key});

  @override
  State<MarketplaceHome> createState() => _MarketplaceHomeState();
}

class _MarketplaceHomeState extends State<MarketplaceHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseReference _productsRef = FirebaseDatabase.instance.ref('marketplace/products');
  final DatabaseReference _categoriesRef = FirebaseDatabase.instance.ref('marketplace/categories');
  
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<String> _categories = ['All', 'Vegetables', 'Fruits', 'Grains', 'Seeds', 'Equipment'];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProducts();
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    
    try {
      final snapshot = await _productsRef.orderByChild('timestamp').once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;
      
      if (data != null) {
        final products = <Product>[];
        data.forEach((key, value) {
          products.add(Product.fromMap(key, value));
        });
        
        setState(() {
          _allProducts = products.reversed.toList();
          _filterProducts();
          _isLoading = false;
        });
      } else {
        setState(() {
          _allProducts = [];
          _filteredProducts = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load products: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await _categoriesRef.once();
      final data = snapshot.snapshot.value as List<dynamic>?;
      
      if (data != null) {
        setState(() {
          _categories = ['All', ...data.cast<String>()];
        });
      }
    } catch (e) {
      // Use default categories
    }
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final matchesCategory = _selectedCategory == 'All' || 
                               product.category == _selectedCategory;
        final matchesSearch = _searchQuery.isEmpty ||
                            product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            product.description.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterProducts();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterProducts();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBuyTab(),
                  _buildSellTab(),
                  _buildMyListingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddProduct(),
        icon: const Icon(Icons.add),
        label: const Text('Sell Product'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: AppConstants.defaultPadding,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        boxShadow: AppTheme.defaultShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.storefront,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Marketplace',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {
                  // Navigate to cart
                },
              ),
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.white),
                onPressed: () {
                  // Navigate to favorites
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          SearchFilterBar(
            categories: _categories,
            selectedCategory: _selectedCategory,
            onCategoryChanged: _onCategoryChanged,
            onSearchChanged: _onSearchChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surfaceWhite,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryGreen,
        unselectedLabelColor: AppTheme.textGrey,
        indicatorColor: AppTheme.primaryGreen,
        tabs: const [
          Tab(text: 'Buy', icon: Icon(Icons.shopping_cart)),
          Tab(text: 'Sell', icon: Icon(Icons.sell)),
          Tab(text: 'My Listings', icon: Icon(Icons.list)),
        ],
      ),
    );
  }

  Widget _buildBuyTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      );
    }

    // Show sample products for now
    final sampleProducts = [
      {'name': 'Fresh Tomatoes', 'price': '40', 'unit': 'kg', 'image': 'tomato'},
      {'name': 'Organic Wheat', 'price': '30', 'unit': 'kg', 'image': 'wheat'},
      {'name': 'Basmati Rice', 'price': '60', 'unit': 'kg', 'image': 'rice'},
      {'name': 'Fresh Potatoes', 'price': '25', 'unit': 'kg', 'image': 'potato'},
      {'name': 'Green Capsicum', 'price': '50', 'unit': 'kg', 'image': 'capsicum'},
      {'name': 'Red Onions', 'price': '35', 'unit': 'kg', 'image': 'onion'},
    ];

    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: AppTheme.primaryGreen,
      child: GridView.builder(
        padding: AppConstants.defaultPadding,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: sampleProducts.length,
        itemBuilder: (context, index) {
          final product = sampleProducts[index];
          return _buildSampleProductCard(product);
        },
      ),
    );
  }

  Widget _buildSampleProductCard(Map<String, String> product) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.lightGreen.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppConstants.borderRadius),
                ),
              ),
              child: Icon(
                Icons.agriculture,
                size: 60,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product['name']!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${product['price']}/${product['unit']}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.shopping_cart_outlined),
                        color: AppTheme.primaryGreen,
                        onPressed: () => _showBuyDialog(product['name']!),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellTab() {
    return Padding(
      padding: AppConstants.defaultPadding,
      child: Column(
        children: [
          _buildSellQuickStats(),
          const SizedBox(height: 20),
          _buildSellActionCards(),
          const SizedBox(height: 20),
          _buildSellTips(),
        ],
      ),
    );
  }

  Widget _buildMyListingsTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildEmptyState(
        'Please login',
        'You need to be logged in to view your listings',
        Icons.login,
      );
    }

    return _buildEmptyState(
      'No listings yet',
      'Start selling your products to see them here',
      Icons.add_box,
    );
  }

  Widget _buildSellQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Sales',
            '₹25,000',
            Icons.trending_up,
            AppTheme.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Active Listings',
            '8',
            Icons.list,
            AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Orders',
            '23',
            Icons.shopping_bag,
            AppTheme.accentOrange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
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
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellActionCards() {
    return Column(
      children: [
        _buildActionCard(
          'Add New Product',
          'List your products for sale',
          Icons.add_circle,
          AppTheme.primaryGreen,
          () => _navigateToAddProduct(),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          'Bulk Upload',
          'Upload multiple products at once',
          Icons.upload_file,
          AppTheme.accentOrange,
          () => _navigateToBulkUpload(),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          'Sales Analytics',
          'View your sales performance',
          Icons.analytics,
          AppTheme.skyBlue,
          () => _navigateToAnalytics(),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: AppConstants.defaultPadding,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textGrey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSellTips() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: AppTheme.sunshine),
                const SizedBox(width: 8),
                Text(
                  'Selling Tips',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTipItem('Take high-quality photos of your products'),
            _buildTipItem('Write detailed descriptions with specifications'),
            _buildTipItem('Set competitive prices based on market rates'),
            _buildTipItem('Respond quickly to buyer inquiries'),
            _buildTipItem('Maintain good seller ratings for better visibility'),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppTheme.textGrey,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navigateToAddProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductPage(
          onProductAdded: _loadProducts,
        ),
      ),
    );
  }

  void _navigateToProductDetail(Map<String, dynamic> product) {
    // Navigate to simple product detail for now
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product['productName'] ?? 'Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price: ₹${product['price']}/${product['unit']}'),
            const SizedBox(height: 8),
            Text('Description: ${product['description']}'),
            const SizedBox(height: 8),
            Text('Seller: ${product['sellerName']}'),
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
              _addToCart(product);
            },
            child: const Text('Buy'),
          ),
        ],
      ),
    );
  }

  void _addToCart(Map<String, dynamic> product) {
    // Simple buy request for now
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Buy ${product['productName']}'),
        content: const Text('Would you like to contact the seller for this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Seller contacted successfully!')),
              );
            },
            child: const Text('Contact Seller'),
          ),
        ],
      ),
    );
  }

  void _navigateToBulkUpload() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk upload feature coming soon!')),
    );
  }

  void _navigateToAnalytics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sales analytics coming soon!')),
    );
  }

  void _showBuyDialog(String productName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Buy $productName'),
        content: const Text('Would you like to contact the seller for this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Seller contacted successfully!')),
              );
            },
            child: const Text('Contact Seller'),
          ),
        ],
      ),
    );
  }
}