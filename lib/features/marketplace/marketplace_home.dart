import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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
  
  List<String> _categories = ['All', 'Vegetables', 'Fruits', 'Grains', 'Seeds', 'Equipment'];
  String _selectedCategory = 'All';
  bool _isLoading = true;

  // Helper methods for responsive design
  bool get _isMobile => MediaQuery.of(context).size.width < 768;
  bool get _isTablet => MediaQuery.of(context).size.width >= 768 && MediaQuery.of(context).size.width < 1200;
  bool get _isDesktop => MediaQuery.of(context).size.width >= 1200;
  
  int get _gridCrossAxisCount {
    if (_isDesktop) return 4;
    if (_isTablet) return 3;
    return 2;
  }
  
  double get _cardAspectRatio {
    if (_isDesktop) return 0.85;
    if (_isTablet) return 0.9;
    return 1.0;
  }
  
  EdgeInsets get _screenPadding {
    if (_isDesktop) return const EdgeInsets.symmetric(horizontal: 64, vertical: 32);
    if (_isTablet) return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }

  void _filterProducts() {
    setState(() {
      // Update the _allProducts list directly since we're not using _filteredProducts
      // The actual filtering will be done in the UI when needed
    });
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
          // Products loaded but using sample data for display
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
      // Use default categories
    }
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterProducts();
  }

  void _onSearchChanged(String query) {
    // Search functionality would be implemented here
    // Currently using sample data so no actual filtering needed
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundLight,
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: _isDesktop ? 1200 : double.infinity,
          ),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: _screenPadding,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Header Row
          Row(
            children: [
              const Icon(
                Icons.storefront,
                color: Colors.white,
                size: 28,
              ),
              SizedBox(width: _isMobile ? 8 : 12),
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
                _buildHeaderAction(Icons.shopping_cart, 'Cart', () {}),
                const SizedBox(width: 8),
                _buildHeaderAction(Icons.favorite, 'Favorites', () {}),
                const SizedBox(width: 8),
                _buildHeaderAction(Icons.notifications, 'Notifications', () {}),
              ],
            ],
          ),
          
          // Statistics Row (Desktop/Tablet only)
          if (!_isMobile) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatChip('1,234 Products', Icons.inventory),
                const SizedBox(width: 12),
                _buildStatChip('456 Sellers', Icons.store),
                const SizedBox(width: 12),
                _buildStatChip('24/7 Support', Icons.support_agent),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Enhanced Search Filter Bar
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

  Widget _buildHeaderAction(IconData icon, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
        splashRadius: 20,
      ),
    );
  }

  Widget _buildStatChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
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

    // Show sample products with improved responsive design
    final sampleProducts = [
      {'name': 'Fresh Tomatoes', 'price': '40', 'unit': 'kg', 'image': 'tomatoes', 'seller': 'Farm Fresh Co.'},
      {'name': 'Organic Wheat', 'price': '30', 'unit': 'kg', 'image': 'wheat', 'seller': 'Organic Farms'},
      {'name': 'Basmati Rice', 'price': '60', 'unit': 'kg', 'image': 'rice', 'seller': 'Premium Grains'},
      {'name': 'Fresh Potatoes', 'price': '25', 'unit': 'kg', 'image': 'potatoes', 'seller': 'Local Farmers'},
      {'name': 'Green Capsicum', 'price': '50', 'unit': 'kg', 'image': 'capsicum', 'seller': 'Green Valley'},
      {'name': 'Red Onions', 'price': '35', 'unit': 'kg', 'image': 'onions', 'seller': 'Fresh Produce'},
      {'name': 'Fresh Carrots', 'price': '45', 'unit': 'kg', 'image': 'carrots', 'seller': 'Harvest Hub'},
      {'name': 'Organic Spinach', 'price': '20', 'unit': 'kg', 'image': 'spinach', 'seller': 'Organic Co.'},
    ];

    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: AppTheme.primaryGreen,
      child: Padding(
        padding: _screenPadding,
        child: Column(
          children: [
            // Featured Products Header
            if (!_isMobile) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Featured Products',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${sampleProducts.length} Products Available',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Products Grid
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _gridCrossAxisCount,
                  crossAxisSpacing: _isDesktop ? 20 : 16,
                  mainAxisSpacing: _isDesktop ? 20 : 16,
                  childAspectRatio: _cardAspectRatio,
                ),
                itemCount: sampleProducts.length,
                itemBuilder: (context, index) {
                  final product = sampleProducts[index];
                  return _buildEnhancedProductCard(product);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedProductCard(Map<String, String> product) {
    return Card(
      elevation: _isDesktop ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showBuyDialog(product['name']!),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image/Icon Section
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.lightGreen.withValues(alpha: 0.1),
                      AppTheme.primaryGreen.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        _getProductIcon(product['image']!),
                        size: _isDesktop ? 80 : (_isTablet ? 70 : 60),
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    // Quality Badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.success,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Fresh',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _isDesktop ? 10 : 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Product Information Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(_isDesktop ? 16 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product Name
                    Text(
                      product['name']!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: _isDesktop ? 15 : 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Seller Info
                    if (product['seller'] != null)
                      Text(
                        'by ${product['seller']!}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textGrey,
                          fontSize: _isDesktop ? 12 : 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    // Price and Action Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₹${product['price']}/${product['unit']}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: _isDesktop ? 17 : 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.add_shopping_cart,
                            color: AppTheme.primaryGreen,
                            size: _isDesktop ? 20 : 18,
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

  IconData _getProductIcon(String imageType) {
    switch (imageType.toLowerCase()) {
      case 'tomatoes':
        return Icons.circle;
      case 'wheat':
        return Icons.grain;
      case 'rice':
        return Icons.rice_bowl;
      case 'potatoes':
        return Icons.circle_outlined;
      case 'capsicum':
        return Icons.local_florist;
      case 'onions':
        return Icons.circle;
      case 'carrots':
        return Icons.local_dining;
      case 'spinach':
        return Icons.eco;
      default:
        return Icons.agriculture;
    }
  }

  Widget _buildSellTab() {
    return Padding(
      padding: _screenPadding,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Container(
              padding: EdgeInsets.all(_isDesktop ? 24 : 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGreen.withValues(alpha: 0.1),
                    AppTheme.lightGreen.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.store,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Selling Today!',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                            fontSize: _isDesktop ? 22 : 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reach thousands of buyers and grow your agricultural business',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textGrey,
                            fontSize: _isDesktop ? 15 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: _isDesktop ? 24 : 16),
            
            // Quick Stats
            _buildSellQuickStats(),
            
            SizedBox(height: _isDesktop ? 24 : 16),
            
            // Action Cards
            _buildSellActionCards(),
            
            SizedBox(height: _isDesktop ? 24 : 16),
            
            // Selling Tips
            _buildSellTips(),
            
            const SizedBox(height: 20),
          ],
        ),
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
    if (_isMobile) {
      return Column(
        children: [
          Row(
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
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Orders',
                  '23',
                  Icons.shopping_bag,
                  AppTheme.accentOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Rating',
                  '4.8',
                  Icons.star,
                  AppTheme.sunshine,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
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
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Rating',
              '4.8',
              Icons.star,
              AppTheme.sunshine,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(_isDesktop ? 20 : 16),
        child: Column(
          children: [
            Icon(icon, color: color, size: _isDesktop ? 36 : 32),
            SizedBox(height: _isDesktop ? 12 : 8),
            Text(
              value,
              style: TextStyle(
                fontSize: _isDesktop ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: _isDesktop ? 13 : 12,
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
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(_isDesktop ? 20 : 16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(_isDesktop ? 16 : 12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: _isDesktop ? 28 : 24),
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
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(_isDesktop ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: AppTheme.sunshine),
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
            decoration: const BoxDecoration(
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
      child: Padding(
        padding: _screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: _isDesktop ? 100 : 80,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.shopping_cart,
              color: AppTheme.primaryGreen,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Buy $productName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Would you like to contact the seller for this product? You can also add it to your cart for later purchase.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Added to cart!'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            child: const Text('Add to Cart'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Seller contacted successfully!'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            child: const Text(
              'Contact Seller',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

}