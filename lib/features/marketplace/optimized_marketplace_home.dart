import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../services/marketplace_service.dart';
import '../../services/user_state_service.dart';
import '../../widgets/search_filter_bar.dart';
import '../../utils/responsive_helper.dart';
import 'add_product_page.dart';
import 'product_detail_page.dart';

class OptimizedMarketplaceHome extends StatefulWidget {
  const OptimizedMarketplaceHome({super.key});

  @override
  State<OptimizedMarketplaceHome> createState() => _OptimizedMarketplaceHomeState();
}

class _OptimizedMarketplaceHomeState extends State<OptimizedMarketplaceHome>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  // Keep alive to prevent rebuild when switching tabs
  @override
  bool get wantKeepAlive => true;

  late TabController _tabController;
  final MarketplaceService _marketplaceService = MarketplaceService();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  UserRole? _userRole;

  // Debounce timer for search
  Timer? _searchDebounce;
  
  // Animation controller for smooth transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Get user role for filtering
    final userStateService = Provider.of<UserStateService>(context, listen: false);
    _userRole = userStateService.userRole;
    
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _refreshController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load categories and products in parallel
      final futures = await Future.wait([
        _loadCategories(),
        _loadProducts(),
      ]);
      
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = 'Failed to load marketplace data: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _marketplaceService.getCategories();
      setState(() {
        _categories = ['All', ...categories];
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _loadProducts({bool loadMore = false}) async {
    if (loadMore && _isLoadingMore) return;
    
    if (loadMore) {
      setState(() => _isLoadingMore = true);
    }

    try {
      final products = await _marketplaceService.getProducts(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        userRole: _userRole,
        loadMore: loadMore,
      );

      setState(() {
        if (loadMore) {
          _products.addAll(products);
        } else {
          _products = products;
        }
        _isLoadingMore = false;
      });
      
      _filterProductsLocally();
      
    } catch (e) {
      setState(() {
        _error = 'Failed to load products: ${e.toString()}';
        _isLoadingMore = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
      _filterProductsLocally();
    });
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadProducts(); // Reload products for new category
  }

  void _filterProductsLocally() {
    setState(() {
      _filteredProducts = _products.where((product) {
        final matchesSearch = _searchQuery.isEmpty || 
            product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
        return matchesSearch;
      }).toList();
    });
  }

  void _onRefresh() async {
    try {
      // Clear cache and reload
      _marketplaceService.clearCache();
      await _loadProducts();
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
    }
  }

  void _onLoading() async {
    try {
      if (_marketplaceService.hasMoreData) {
        await _loadProducts(loadMore: true);
        _refreshController.loadComplete();
      } else {
        _refreshController.loadNoData();
      }
    } catch (e) {
      _refreshController.loadFailed();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: _screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeaderRow(),
              if (!_isMobile) ...[
                const SizedBox(height: 16),
                Text(
                  'Discover fresh products from local farmers',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SearchFilterBar(
                categories: _categories,
                selectedCategory: _selectedCategory,
                searchQuery: _searchQuery,
                onCategoryChanged: _onCategoryChanged,
                onSearchChanged: _onSearchChanged,
              ),
              const SizedBox(height: 16),
              if (!_isMobile) _buildStatsRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        Hero(
          tag: 'marketplace_icon',
          child: Icon(
            Icons.storefront,
            color: Colors.white,
            size: _isMobile ? 28 : 32,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Marketplace',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: _isDesktop ? 24 : 20,
            ),
          ),
        ),
        if (!_isMobile) ...[
          _buildHeaderAction(
            icon: Icons.favorite_border,
            onTap: () => _showComingSoon('Favorites'),
          ),
          const SizedBox(width: 12),
          _buildHeaderAction(
            icon: Icons.shopping_cart_outlined,
            onTap: () => _showComingSoon('Cart'),
          ),
        ],
      ],
    );
  }

  Widget _buildHeaderAction({required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatChip('${_products.length} Products', Icons.inventory)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatChip('456 Sellers', Icons.store)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatChip('24/7 Support', Icons.support_agent)),
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
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: _isDesktop ? 14 : 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: _isDesktop ? 1200 : double.infinity,
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'All Products'),
                Tab(text: 'Featured'),
                Tab(text: 'New Arrivals'),
              ],
              labelColor: AppTheme.primaryGreen,
              unselectedLabelColor: AppTheme.textGrey,
              indicatorColor: AppTheme.primaryGreen,
            ),
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProductGrid(),
                  _buildProductGrid(), // Featured products
                  _buildProductGrid(), // New arrivals
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryGreen),
          SizedBox(height: 16),
          Text(
            'Loading fresh products...',
            style: TextStyle(
              color: AppTheme.textGrey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: _screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: _isDesktop ? 80 : 64,
              color: AppTheme.textGrey,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_filteredProducts.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }

    return SmartRefresher(
      controller: _refreshController,
      enablePullDown: true,
      enablePullUp: _marketplaceService.hasMoreData,
      onRefresh: _onRefresh,
      onLoading: _onLoading,
      header: const WaterDropMaterialHeader(
        backgroundColor: AppTheme.primaryGreen,
        color: Colors.white,
      ),
      footer: const ClassicFooter(
        textStyle: TextStyle(color: AppTheme.textGrey),
      ),
      child: Padding(
        padding: _screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isMobile) ...[
              const SizedBox(height: 16),
              _buildProductsHeader(),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _gridCrossAxisCount,
                  crossAxisSpacing: _isDesktop ? 20 : 16,
                  mainAxisSpacing: _isDesktop ? 20 : 16,
                  childAspectRatio: _cardAspectRatio,
                ),
                itemCount: _filteredProducts.length + (_isLoadingMore ? 2 : 0),
                itemBuilder: (context, index) {
                  if (index >= _filteredProducts.length) {
                    return _buildLoadingCard();
                  }
                  
                  final product = _filteredProducts[index];
                  return _buildOptimizedProductCard(product, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: _isDesktop ? 80 : 64,
            color: AppTheme.textGrey,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty 
                ? 'No products found for "$_searchQuery"'
                : 'No products available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                });
                _filterProductsLocally();
              },
              child: const Text('Clear Search'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductsHeader() {
    return Row(
      children: [
        Text(
          'Products',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Text(
          '${_filteredProducts.length} Products Found',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildOptimizedProductCard(Product product, int index) {
    return Hero(
      tag: 'product_${product.id}',
      child: Card(
        elevation: _isDesktop ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _navigateToProductDetail(product),
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
                      Expanded(child: _buildProductInfo(product)),
                      _buildProductActions(product),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    if (product.imageUrls.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: CachedNetworkImage(
          imageUrl: product.imageUrls.first,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => _buildImagePlaceholder(),
          errorWidget: (context, url, error) => _buildPlaceholderImage(product),
          memCacheWidth: 300, // Optimize memory usage
          memCacheHeight: 200,
        ),
      );
    }
    return _buildPlaceholderImage(product);
  }

  Widget _buildImagePlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          color: Colors.white,
        ),
      ),
    );
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
            const Icon(
              Icons.currency_rupee,
              size: 16,
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
              side: const BorderSide(color: AppTheme.primaryGreen),
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

  Widget _buildLoadingCard() {
    return Card(
      elevation: _isDesktop ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 100,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 20,
                      width: 120,
                      color: Colors.white,
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

  Widget? _buildFAB() {
    // Show FAB only for vendors/addats
    if (_userRole == UserRole.addat) {
      return FloatingActionButton.extended(
        onPressed: () => _navigateToAddProduct(),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(_isMobile ? 'Add' : 'Add Product'),
      );
    }
    return null;
  }

  void _navigateToProductDetail(Product product) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProductDetailPage(product: product),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;
          
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  void _navigateToAddProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductPage(),
      ),
    );
  }

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
            Text('Available: ${product.quantity} ${product.unit}'),
            const SizedBox(height: 16),
            const Text('Select quantity:'),
            const SizedBox(height: 8),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Quantity (${product.unit})',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
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

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: AppTheme.primaryGreen,
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
}