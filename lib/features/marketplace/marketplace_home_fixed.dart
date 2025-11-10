import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../widgets/search_filter_bar.dart';
import '../../utils/app_constants.dart';
import '../../utils/responsive_helper.dart';
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
  
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<String> _categories = ['All', 'Vegetables', 'Fruits', 'Grains', 'Seeds', 'Equipment'];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;

  // Helper methods for responsive design
  bool get _isMobile => ResponsiveHelper.isMobile(context);
  bool get _isTablet => ResponsiveHelper.isTablet(context);
  bool get _isDesktop => ResponsiveHelper.isDesktop(context);
  
  int get _gridCrossAxisCount => ResponsiveHelper.getGridCrossAxisCount(context);
  double get _cardAspectRatio => ResponsiveHelper.getCardAspectRatio(context);
  EdgeInsets get _screenPadding => ResponsiveHelper.getScreenPadding(context);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _loadProducts(),
      _loadCategories(),
    ]);
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _productsRef.orderByChild('timestamp').once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;
      
      if (data != null) {
        _products = data.entries
            .map((entry) => Product.fromMap(Map<String, dynamic>.from(entry.value)))
            .toList();
        setState(() {
          _filteredProducts = _products;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load products: $e');
    }
  }

  Future<void> _loadProducts() async {
    try {
      final snapshot = await _productsRef.orderByChild('timestamp').once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;
      
      if (data != null) {
        final products = data.entries
            .map((entry) => Product.fromMap(Map<String, dynamic>.from(entry.value)))
            .toList();
        
        setState(() {
          _products = products;
          _filteredProducts = products;
          _isLoading = false;
        });
      } else {
        setState(() {
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
      // Use default categories if loading fails
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterProducts();
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterProducts();
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products.where((product) {
        final matchesSearch = _searchQuery.isEmpty ||
            product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.description.toLowerCase().contains(_searchQuery.toLowerCase());
        
        final matchesCategory = _selectedCategory == 'All' ||
            product.category == _selectedCategory;
        
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        _buildHeaderSliver(),
        _buildSearchBarSliver(),
        _buildTabBarSliver(),
        _buildContentSliver(),
      ],
    );
  }

  Widget _buildHeaderSliver() {
    return SliverAppBar(
      expandedHeight: _isDesktop ? 200 : 160,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.primaryGreen,
      flexibleSpace: FlexibleSpaceBar(
        background: _buildWelcomeSection(),
        collapseMode: CollapseMode.parallax,
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen,
            AppTheme.primaryGreen.withOpacity(0.8),
          ],
        ),
      ),
      padding: _screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Icon(
                Icons.storefront,
                size: _isDesktop ? 32 : 28,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Marketplace',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: _isDesktop ? 24 : 20,
                      ),
                    ),
                    if (!_isMobile) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Connect with farmers and buyers across the region',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatsRow(),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    if (!_isMobile) {
      return Row(
        children: [
          Expanded(child: _buildStatChip('1,234 Products', Icons.inventory)),
          const SizedBox(width: 16),
          Expanded(child: _buildStatChip('456 Sellers', Icons.store)),
          const SizedBox(width: 16),
          Expanded(child: _buildStatChip('24/7 Support', Icons.support_agent)),
        ],
      );
    }
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatChip('1,234 Products', Icons.inventory)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatChip('456 Sellers', Icons.store)),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatChip('24/7 Support', Icons.support_agent),
      ],
    );
  }

  Widget _buildStatChip(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.all(_isDesktop ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: _isDesktop ? 20 : 18,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: _isDesktop ? 12 : 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBarSliver() {
    return SliverToBoxAdapter(
      child: Container(
        color: AppTheme.backgroundLight,
        padding: _screenPadding,
        child: SearchFilterBar(
          searchQuery: _searchQuery,
          onSearchChanged: _onSearchChanged,
          categories: _categories,
          selectedCategory: _selectedCategory,
          onCategoryChanged: _onCategoryChanged,
        ),
      ),
    );
  }

  Widget _buildTabBarSliver() {
    return SliverToBoxAdapter(
      child: Container(
        color: AppTheme.backgroundLight,
        child: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textGrey,
          indicatorColor: AppTheme.primaryGreen,
          tabs: const [
            Tab(text: 'All Products'),
            Tab(text: 'Featured'),
            Tab(text: 'New Arrivals'),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSliver() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.textGrey,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredProducts.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: AppTheme.textGrey,
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty 
                    ? 'No products found for "$_searchQuery"'
                    : 'No products available',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (_searchQuery.isNotEmpty) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                    _filterProducts();
                  },
                  child: const Text('Clear Search'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SliverRefreshControl(
      onRefresh: _initializeData,
      child: SliverPadding(
        padding: _screenPadding,
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isMobile) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Products',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_filteredProducts.length} Products Found',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _gridCrossAxisCount,
                  crossAxisSpacing: _isDesktop ? 20 : 16,
                  mainAxisSpacing: _isDesktop ? 20 : 16,
                  childAspectRatio: _cardAspectRatio,
                ),
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  return _buildProductCard(product);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      elevation: _isDesktop ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showProductDetails(product),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _buildProductImage(product),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductInfo(product),
                    const Spacer(),
                    _buildProductActions(product),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    if (product.imageUrls.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: Image.network(
          product.imageUrls.first,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(product),
        ),
      );
    }
    return _buildPlaceholderImage(product);
  }

  Widget _buildPlaceholderImage(Product product) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        color: AppTheme.backgroundLight,
      ),
      child: Center(
        child: Icon(
          _getCategoryIcon(product.category),
          size: _isDesktop ? 40 : 32,
          color: AppTheme.primaryGreen,
        ),
      ),
    );
  }

  Widget _buildProductInfo(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: _isDesktop ? 16 : 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          product.category,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textGrey,
            fontSize: _isDesktop ? 12 : 10,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.currency_rupee,
              size: _isDesktop ? 16 : 14,
              color: AppTheme.primaryGreen,
            ),
            Text(
              '${product.price}/${product.unit}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: _isDesktop ? 17 : 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductActions(Product product) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _showBuyDialog(product),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.primaryGreen),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart,
                  size: _isDesktop ? 20 : 18,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(width: 4),
                Text(
                  'Buy',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: _isDesktop ? 14 : 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _navigateToAddProduct,
      backgroundColor: AppTheme.primaryGreen,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        _isMobile ? 'Add' : 'Add Product',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables':
        return Icons.eco;
      case 'fruits':
        return Icons.apple;
      case 'grains':
        return Icons.grain;
      case 'seeds':
        return Icons.spa;
      case 'equipment':
        return Icons.build;
      default:
        return Icons.category;
    }
  }

  void _navigateToAddProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductPage(
          onProductAdded: _refreshData,
        ),
      ),
    );
  }

  void _showProductDetails(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => _buildProductDetailsSheet(
          product,
          scrollController,
        ),
      ),
    );
  }

  Widget _buildProductDetailsSheet(Product product, ScrollController scrollController) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.imageUrls.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        product.imageUrls.first,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                            _buildPlaceholderImage(product),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.category,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.currency_rupee,
                        color: AppTheme.primaryGreen,
                      ),
                      Text(
                        '${product.price}/${product.unit}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showBuyDialog(product),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Buy Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBuyDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Buy ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price: ₹${product.price}/${product.unit}'),
            const SizedBox(height: 8),
            Text('Seller: ${product.sellerId}'),
            const SizedBox(height: 16),
            const Text('This feature will be available soon!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackBar('Purchase request sent!');
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class SliverRefreshControl extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const SliverRefreshControl({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: child,
    );
  }
}