import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../widgets/search_filter_bar.dart';
import '../../widgets/responsive_cards.dart';
import '../../utils/responsive_helper.dart';
import 'add_product_page.dart';

class EnhancedMarketplaceHome extends StatefulWidget {
  const EnhancedMarketplaceHome({super.key});

  @override
  State<EnhancedMarketplaceHome> createState() => _EnhancedMarketplaceHomeState();
}

class _EnhancedMarketplaceHomeState extends State<EnhancedMarketplaceHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseReference _productsRef = FirebaseDatabase.instance.ref('marketplace/products');
  
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
            _buildEnhancedHeader(),
            _buildResponsiveTabBar(),
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
      floatingActionButton: _buildResponsiveFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildEnhancedHeader() {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return Container(
      padding: ResponsiveHelper.getScreenPadding(context),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Icon(
                Icons.storefront,
                color: Colors.white,
                size: isDesktop ? 32 : 28,
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Expanded(
                child: Text(
                  'Marketplace',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveHelper.getFontSize(context, 24),
                  ),
                ),
              ),
              if (!isMobile) ...[
                _buildHeaderAction(Icons.shopping_cart, 'Cart', () {}),
                const SizedBox(width: 8),
                _buildHeaderAction(Icons.favorite, 'Favorites', () {}),
                const SizedBox(width: 8),
                _buildHeaderAction(Icons.notifications, 'Notifications', () {}),
              ],
            ],
          ),
          
          // Stats Row for larger screens
          if (!isMobile) ...[
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
          
          // Search and Filter
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
        color: Colors.white.withOpacity(0.2),
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

  Widget _buildResponsiveTabBar() {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    
    return Container(
      color: AppTheme.surfaceWhite,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryGreen,
        unselectedLabelColor: AppTheme.textGrey,
        indicatorColor: AppTheme.primaryGreen,
        labelStyle: TextStyle(
          fontSize: isDesktop ? 16 : 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: isDesktop ? 14 : 12,
          fontWeight: FontWeight.normal,
        ),
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

    final sampleProducts = [
      {'name': 'Fresh Tomatoes', 'price': '₹40/kg', 'seller': 'Farm Fresh Co.', 'isOrganic': true},
      {'name': 'Organic Wheat', 'price': '₹30/kg', 'seller': 'Organic Farms', 'isOrganic': true},
      {'name': 'Basmati Rice', 'price': '₹60/kg', 'seller': 'Premium Grains', 'isOrganic': false},
      {'name': 'Fresh Potatoes', 'price': '₹25/kg', 'seller': 'Local Farmers', 'isOrganic': false},
      {'name': 'Green Capsicum', 'price': '₹50/kg', 'seller': 'Green Valley', 'isOrganic': true},
      {'name': 'Red Onions', 'price': '₹35/kg', 'seller': 'Fresh Produce', 'isOrganic': false},
      {'name': 'Fresh Carrots', 'price': '₹45/kg', 'seller': 'Harvest Hub', 'isOrganic': true},
      {'name': 'Organic Spinach', 'price': '₹20/kg', 'seller': 'Organic Co.', 'isOrganic': true},
    ];

    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: AppTheme.primaryGreen,
      child: SingleChildScrollView(
        padding: ResponsiveHelper.getScreenPadding(context),
        child: Column(
          children: [
            // Featured Section for larger screens
            if (!ResponsiveHelper.isMobile(context))
              _buildFeaturedSection(),
            
            // Products Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(context),
                crossAxisSpacing: ResponsiveHelper.isDesktop(context) ? 20 : 16,
                mainAxisSpacing: ResponsiveHelper.isDesktop(context) ? 20 : 16,
                childAspectRatio: ResponsiveHelper.getCardAspectRatio(context),
              ),
              itemCount: sampleProducts.length,
              itemBuilder: (context, index) {
                final product = sampleProducts[index];
                return ResponsiveProductCard(
                  name: product['name'] as String,
                  price: product['price'] as String,
                  seller: product['seller'] as String,
                  isOrganic: product['isOrganic'] as bool,
                  onTap: () => _showBuyDialog(product['name'] as String),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
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
            '8 Products Available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellTab() {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getScreenPadding(context),
      child: Column(
        children: [
          _buildSellWelcomeCard(),
          const SizedBox(height: 20),
          _buildSellQuickStats(),
          const SizedBox(height: 20),
          _buildSellActionCards(),
          const SizedBox(height: 20),
          _buildSellTips(),
        ],
      ),
    );
  }

  Widget _buildSellWelcomeCard() {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    
    return EnhancedDashboardCard(
      title: 'Start Selling Today!',
      subtitle: 'Reach thousands of buyers and grow your agricultural business',
      icon: Icons.store,
      iconColor: AppTheme.primaryGreen,
      height: isDesktop ? 120 : 100,
      onTap: () => _navigateToAddProduct(),
    );
  }

  Widget _buildSellQuickStats() {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    
    final stats = [
      {'title': 'Total Sales', 'value': '₹25,000', 'icon': Icons.trending_up, 'color': AppTheme.success},
      {'title': 'Active Listings', 'value': '8', 'icon': Icons.list, 'color': AppTheme.primaryGreen},
      {'title': 'Orders', 'value': '23', 'icon': Icons.shopping_bag, 'color': AppTheme.accentOrange},
      {'title': 'Rating', 'value': '4.8', 'icon': Icons.star, 'color': AppTheme.sunshine},
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatGridCard(stats[0])),
              const SizedBox(width: 12),
              Expanded(child: _buildStatGridCard(stats[1])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatGridCard(stats[2])),
              const SizedBox(width: 12),
              Expanded(child: _buildStatGridCard(stats[3])),
            ],
          ),
        ],
      );
    } else {
      return Row(
        children: stats.map((stat) => 
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildStatGridCard(stat),
            ),
          ),
        ).toList(),
      );
    }
  }

  Widget _buildStatGridCard(Map<String, dynamic> stat) {
    return ResponsiveGridCard(
      title: stat['title'],
      value: stat['value'],
      icon: stat['icon'],
      color: stat['color'],
    );
  }

  Widget _buildSellActionCards() {
    final actions = [
      {'title': 'Add New Product', 'subtitle': 'List your products for sale', 'icon': Icons.add_circle, 'color': AppTheme.primaryGreen, 'action': _navigateToAddProduct},
      {'title': 'Bulk Upload', 'subtitle': 'Upload multiple products at once', 'icon': Icons.upload_file, 'color': AppTheme.accentOrange, 'action': _navigateToBulkUpload},
      {'title': 'Sales Analytics', 'subtitle': 'View your sales performance', 'icon': Icons.analytics, 'color': AppTheme.skyBlue, 'action': _navigateToAnalytics},
    ];

    return Column(
      children: actions.map((action) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: EnhancedDashboardCard(
            title: action['title'] as String,
            subtitle: action['subtitle'] as String,
            icon: action['icon'] as IconData,
            iconColor: action['color'] as Color,
            onTap: action['action'] as VoidCallback,
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textGrey),
          ),
        ),
      ).toList(),
    );
  }

  Widget _buildSellTips() {
    final tips = [
      'Take high-quality photos of your products',
      'Write detailed descriptions with specifications',
      'Set competitive prices based on market rates',
      'Respond quickly to buyer inquiries',
      'Maintain good seller ratings for better visibility',
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 16),
            ...tips.map((tip) => Padding(
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
            )),
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

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    
    return Center(
      child: Padding(
        padding: ResponsiveHelper.getScreenPadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isDesktop ? 100 : 80,
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

  Widget _buildResponsiveFloatingActionButton() {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    if (isMobile) {
      return FloatingActionButton.extended(
        onPressed: () => _navigateToAddProduct(),
        icon: const Icon(Icons.add),
        label: const Text(
          'Sell Product',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 6,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
      );
    } else {
      return FloatingActionButton(
        onPressed: () => _navigateToAddProduct(),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 6,
        tooltip: 'Add Product',
        child: const Icon(Icons.add, size: 28),
      );
    }
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
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
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