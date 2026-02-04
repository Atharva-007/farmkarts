import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../services/marketplace_service.dart';
import 'fixed_product_detail_page.dart';
import '../../add_sell_item_page.dart';

/// Complete Functional Marketplace with Buying and Selling sections
class CompleteFunctionalMarketplace extends StatefulWidget {
  const CompleteFunctionalMarketplace({super.key});

  @override
  State<CompleteFunctionalMarketplace> createState() => _CompleteFunctionalMarketplaceState();
}

class _CompleteFunctionalMarketplaceState extends State<CompleteFunctionalMarketplace>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  late TabController _tabController;
  final MarketplaceService _marketplaceService = MarketplaceService();
  
  // State management
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _searchQuery = '';
  String _selectedCategory = 'All';
  
  final TextEditingController _searchController = TextEditingController();
  
  // Categories for filtering
  final List<String> _categories = [
    'All',
    'Vegetables',
    'Fruits', 
    'Grains',
    'Seeds',
    'Equipment',
    'Dairy',
    'Spices',
    'Fertilizers'
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeMarketplace();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Initialize marketplace data and error handling
  Future<void> _initializeMarketplace() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });
      
      await _loadProducts();
      
    } catch (e) {
      _handleError('Failed to initialize marketplace: ${e.toString()}');
    }
  }

  /// Load products with comprehensive error handling
  Future<void> _loadProducts() async {
    try {
      final products = await _marketplaceService.getProducts();
      
      if (mounted) {
        setState(() {
          _allProducts = products;
          _filteredProducts = products;
          _isLoading = false;
          _hasError = false;
        });
        
        _filterProducts();
      }
      
    } catch (e) {
      _handleError('Failed to load products: ${e.toString()}');
    }
  }

  /// Handle errors with user-friendly messages
  void _handleError(String message) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = message;
        _isLoading = false;
      });
      
      // Show user-friendly error message
      _showMessage(
        'Unable to load products. Please check your connection and try again.',
        isError: true,
      );
    }
  }

  /// Filter products based on search and category
  void _filterProducts() {
    if (!mounted) return;
    
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final searchMatch = _searchQuery.isEmpty ||
            product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.sellerName.toLowerCase().contains(_searchQuery.toLowerCase());
        
        final categoryMatch = _selectedCategory == 'All' || 
            product.category.toLowerCase() == _selectedCategory.toLowerCase();
        
        return searchMatch && categoryMatch && product.isAvailable;
      }).toList();
    });
  }

  /// Handle search input changes
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim();
    });
    _filterProducts();
  }

  /// Handle category selection
  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterProducts();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchAndFilterSection(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBuyingSection(),
                _buildMyProductsSection(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// Build app bar with proper theming
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'FarmKarts Marketplace',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: AppTheme.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: true,
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.shopping_cart),
            text: 'Buying',
          ),
          Tab(
            icon: Icon(Icons.store),
            text: 'My Products',
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadProducts,
          tooltip: 'Refresh Products',
        ),
      ],
    );
  }

  /// Build search and filter section
  Widget _buildSearchAndFilterSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search products, categories, sellers...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Category filters
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) => _onCategoryChanged(category),
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryGreen,
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build buying section (main products view)
  Widget _buildBuyingSection() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: AppTheme.primaryGreen,
      child: _buildProductGrid(_filteredProducts),
    );
  }

  /// Build my products section
  Widget _buildMyProductsSection() {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return _buildLoginPrompt();
    }

    if (_isLoading) {
      return _buildLoadingState();
    }

    final myProducts = _allProducts
        .where((product) => product.sellerId == user.uid)
        .toList();
    
    if (myProducts.isEmpty) {
      return _buildNoProductsState();
    }

    return _buildProductGrid(myProducts, isMyProducts: true);
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.primaryGreen,
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Loading products...',
            style: TextStyle(
              color: AppTheme.textGrey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to load products',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _searchQuery.isNotEmpty ? Icons.search_off : Icons.inventory_2_outlined,
                size: 64,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty ? 'No products found' : 'No products available',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'Try adjusting your search or filters'
                  : 'Be the first to add a product to the marketplace!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _navigateToAddProduct,
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build login prompt
  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.account_circle_outlined,
                size: 64,
                color: Colors.blue.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Login Required',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please login to view and manage your products.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _handleLoginRedirect,
              icon: const Icon(Icons.login),
              label: const Text('Login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build no products state for my products
  Widget _buildNoProductsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.store_outlined,
                size: 64,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No products listed yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start selling by adding your first product to the marketplace.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToAddProduct,
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build product grid
  Widget _buildProductGrid(List<Product> products, {bool isMyProducts = false}) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.isMobile(context) ? 2 : 
                       ResponsiveHelper.isTablet(context) ? 3 : 4,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => _buildProductCard(
        products[index],
        isMyProduct: isMyProducts,
      ),
    );
  }

  /// Build individual product card
  Widget _buildProductCard(Product product, {bool isMyProduct = false}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToProductDetail(product),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image section
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: _buildProductImage(product),
                    ),
                  ),
                  // Product badges
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _buildProductBadges(product),
                  ),
                  if (isMyProduct)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _buildMyProductActions(product),
                    ),
                ],
              ),
            ),
            
            // Product info section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textDark,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Category
                    Text(
                      product.category,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Price and availability
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '₹${product.price.toInt()}/${product.unit}',
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        _buildAvailabilityIndicator(product),
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

  /// Build product image with error handling
  Widget _buildProductImage(Product product) {
    if (product.imageUrls.isEmpty) {
      return _buildPlaceholderImage(product);
    }

    return CachedNetworkImage(
      imageUrl: product.imageUrls.first,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey.shade100,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryGreen,
            strokeWidth: 2,
          ),
        ),
      ),
      errorWidget: (context, url, error) => _buildPlaceholderImage(product),
    );
  }

  /// Build placeholder image
  Widget _buildPlaceholderImage(Product product) {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getCategoryIcon(product.category),
            size: 32,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 4),
          Text(
            product.category,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build product badges
  Widget _buildProductBadges(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product.isOrganic)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Organic',
              style: TextStyle(
                color: Colors.green,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  /// Build my product actions
  Widget _buildMyProductActions(Product product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 16),
        onSelected: (value) => _handleMyProductAction(value, product),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 16),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 16, color: Colors.red),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build availability indicator
  Widget _buildAvailabilityIndicator(Product product) {
    final isAvailable = product.quantity > 0;
    
    return Icon(
      isAvailable ? Icons.check_circle : Icons.error,
      size: 14,
      color: isAvailable ? Colors.green : Colors.red,
    );
  }

  /// Build floating action button
  Widget _buildFloatingActionButton() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: _navigateToAddProduct,
      backgroundColor: AppTheme.primaryGreen,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Sell Product'),
      elevation: 4,
    );
  }

  /// Get category icon
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables':
        return Icons.eco;
      case 'fruits':
        return Icons.local_florist;
      case 'grains':
        return Icons.grain;
      case 'seeds':
        return Icons.scatter_plot;
      case 'equipment':
        return Icons.agriculture;
      case 'dairy':
        return Icons.local_drink;
      case 'spices':
        return Icons.local_pizza;
      case 'fertilizers':
        return Icons.science;
      default:
        return Icons.category;
    }
  }

  /// Navigate to product detail
  void _navigateToProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FixedProductDetailPage(
          product: product,
          onContactSeller: () {
            _showMessage('Seller contacted successfully! 📞');
          },
        ),
      ),
    );
  }

  /// Navigate to add product
  void _navigateToAddProduct() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Please login to sell products', isError: true);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddSellItemPage(),
      ),
    ).then((_) {
      // Refresh products when returning from add product page
      _loadProducts();
    });
  }

  /// Handle login redirect
  void _handleLoginRedirect() {
    _showMessage('Login functionality will be implemented soon!');
  }

  /// Handle my product actions
  void _handleMyProductAction(String action, Product product) {
    switch (action) {
      case 'edit':
        _showMessage('Edit product functionality coming soon!');
        break;
      case 'delete':
        _showDeleteConfirmation(product);
        break;
    }
  }

  /// Show delete confirmation
  void _showDeleteConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(product);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Delete product
  void _deleteProduct(Product product) {
    _showMessage('Delete functionality will be implemented soon!');
  }

  /// Show message to user
  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: isError ? 4 : 3),
        action: isError && message.contains('connection')
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _loadProducts,
              )
            : null,
      ),
    );
  }
}