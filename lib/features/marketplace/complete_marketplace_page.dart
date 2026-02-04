import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../services/marketplace_service.dart';
import '../../services/product_service.dart';
import '../../services/user_state_service.dart';
import '../../services/conversation_service.dart';
import '../../utils/app_constants.dart';
import 'add_product_page.dart';
import 'selling_history_page.dart';
import 'buying_list_page.dart';
import '../../pages/enhanced_product_detail_page.dart';

class CompleteMarketplacePage extends StatefulWidget {
  const CompleteMarketplacePage({super.key});

  @override
  State<CompleteMarketplacePage> createState() => _CompleteMarketplacePageState();
}

class _CompleteMarketplacePageState extends State<CompleteMarketplacePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MarketplaceService _marketplaceService = MarketplaceService();
  final ProductService _productService = ProductService();
  final ConversationService _conversationService = ConversationService();
  
  List<Product> _sellingProducts = [];
  List<Product> _buyingProducts = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _loadingBuy = false;
  bool _loadingSell = false;
  String? _error;
  UserRole? _userRole;
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('CompleteMarketplacePage: Loading marketplace data...');

      // Get user role
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          if (userDoc.exists) {
            final userData = UserModel.fromMap(userDoc.data()!);
            _userRole = userData.role;
            print('CompleteMarketplacePage: User role: $_userRole');
          }
        } catch (e) {
          print('CompleteMarketplacePage: Warning - Could not load user role: $e');
          // Continue without user role
        }
      }

      // Load categories from ProductService
      _categories = ['All', ...(await _productService.getCategories())];
      print('CompleteMarketplacePage: Loaded ${_categories.length} categories');
      
      // Load products
      await _loadProducts();
      
    } catch (e) {
      print('CompleteMarketplacePage: Error loading data: $e');
      setState(() {
        _error = 'Error loading data: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProducts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      print('CompleteMarketplacePage: Loading products for user ${user.uid}');
      
      // Load selling products (current user's products) in parallel
      setState(() => _loadingSell = true);
      final sellingFuture = _productService.getProducts(
        sellerId: user.uid,
        isAvailable: null, // Get all user's products regardless of availability
        sortBy: 'createdAt',
        sortOrder: 'desc',
      );

      // Load buying products (other users' products) in parallel
      setState(() => _loadingBuy = true);
      final buyingFuture = _productService.getProducts(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        excludeSeller: user.uid, // Exclude current user's products
        isAvailable: true, // Only get available products for buying
        sortBy: 'createdAt',
        sortOrder: 'desc',
        limit: 50,
      );

      // Wait for both to complete
      final results = await Future.wait([sellingFuture, buyingFuture]);
      
      setState(() {
        _sellingProducts = results[0];
        _buyingProducts = results[1];
        _loadingSell = false;
        _loadingBuy = false;
      });

      print('CompleteMarketplacePage: Loaded ${_sellingProducts.length} selling products and ${_buyingProducts.length} buying products');

      _filterProducts();
    } catch (e) {
      print('CompleteMarketplacePage: Error loading products: $e');
      setState(() {
        _error = 'Error loading products: $e';
        _loadingSell = false;
        _loadingBuy = false;
      });
    }
  }

  void _filterProducts() {
    setState(() {
      // No need to filter here as the products are already loaded properly
      // The search will be handled in the UI widgets
    });
  }

  void _navigateToSellingHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SellingHistoryPage(),
      ),
    );
  }

  void _navigateToBuyingList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BuyingListPage(),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sort Products',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Latest First'),
                leading: const Icon(Icons.access_time),
                onTap: () {
                  Navigator.pop(context);
                  // Implement sorting logic
                },
              ),
              ListTile(
                title: const Text('Price: Low to High'),
                leading: const Icon(Icons.arrow_upward),
                onTap: () {
                  Navigator.pop(context);
                  // Implement sorting logic
                },
              ),
              ListTile(
                title: const Text('Price: High to Low'),
                leading: const Icon(Icons.arrow_downward),
                onTap: () {
                  Navigator.pop(context);
                  // Implement sorting logic
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          if (FirebaseAuth.instance.currentUser != null) ...[
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Selling History',
              onPressed: () => _navigateToSellingHistory(),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'refresh':
                    _loadData();
                    break;
                  case 'sort':
                    _showSortOptions();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 8),
                      Text('Refresh'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'sort',
                  child: Row(
                    children: [
                      Icon(Icons.sort),
                      SizedBox(width: 8),
                      Text('Sort'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'My Products'),
                  Tab(text: 'Buy Products'),
                ],
              ),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red[100],
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.red),
                        onPressed: _loadData,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      body: user == null 
          ? _buildGuestView() 
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSellingTab(),
                _buildBuyingTab(),
              ],
            ),
      floatingActionButton: user != null && _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _navigateToAddProduct,
              backgroundColor: AppTheme.primaryGreen,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome to Marketplace',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please log in to buy and sell products',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildSellingTab() {
    // Return the enhanced selling products list directly
    return const EnhancedSellingProductsList();
  }

  Widget _buildSellingControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('Selling History'),
              onPressed: _navigateToSellingHistory,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                side: const BorderSide(color: AppTheme.primaryGreen),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.analytics),
              label: const Text('Analytics'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Analytics feature coming soon!')),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.info,
                side: const BorderSide(color: AppTheme.info),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyingTab() {
    return Column(
      children: [
        _buildSearchBar(),
        _buildCategoryFilter(),
        Expanded(child: _buildBuyingProductsList()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search products...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _filterProducts();
        },
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ['All', ..._categories].length,
        itemBuilder: (context, index) {
          final category = ['All', ..._categories][index];
          final isSelected = category == _selectedCategory;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
                _loadProducts();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSellingProductsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sellingProducts.isEmpty) {
      return _buildEmptyState('You haven\'t added any products yet', 'Add Product');
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sellingProducts.length,
        itemBuilder: (context, index) {
          final product = _sellingProducts[index];
          return _buildProductCard(product, isSellingMode: true);
        },
      ),
    );
  }

  Widget _buildBuyingProductsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_buyingProducts.isEmpty) {
      return _buildEmptyState('No products available', 'Refresh');
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: _buyingProducts.length,
        itemBuilder: (context, index) {
          final product = _buyingProducts[index];
          return _buildProductCard(product, isSellingMode: false);
        },
      ),
    );
  }

  Widget _buildEmptyState(String message, String buttonText) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, {required bool isSellingMode}) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _viewProductDetails(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: isSellingMode ? 120 : 140,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                color: Colors.grey[200],
              ),
              child: product.imageUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      child: Image.network(
                        product.imageUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                            Icon(Icons.image_not_supported, size: 40, color: Colors.grey[400]),
                      ),
                    )
                  : Icon(Icons.image, size: 40, color: Colors.grey[400]),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: isSellingMode ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${product.price}/${product.unit}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    if (!isSellingMode) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              product.sellerName,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Spacer(),
                    
                    // Action Buttons
                    if (isSellingMode) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _editProduct(product),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.primaryGreen),
                              ),
                              child: const Text('Edit', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _viewOrders(product),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.blue),
                              ),
                              child: const Text('Orders', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _contactSeller(product),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Contact Seller', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Navigation and action methods
  void _navigateToAddProduct() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AddProductPage(),
        ),
      );
      if (result == true && mounted) {
        _loadData(); // Refresh the data
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      print('Error navigating to add product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening add product page: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _viewProductDetails(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedProductDetailPage(product: product),
      ),
    );
    }
  }

  void _contactSeller(Product product) async {
    try {
      final conversationId = await _conversationService.contactSeller(
        sellerId: product.sellerId,
        productId: product.id,
        productName: product.name,
        sellerName: product.sellerName,
      );

      if (mounted) {
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: {
            'conversationId': conversationId,
            'otherUserId': product.sellerId,
            'otherUserName': product.sellerName,
            'productName': product.name,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error contacting seller: $e')),
        );
      }
    }
  }

  void _editProduct(Product product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductPage(product: product),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _viewOrders(Product product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Orders for ${product.name} - Coming Soon!'),
        backgroundColor: AppTheme.info,
      ),
    );
  }

  void _sortProducts(String sortBy) {
    setState(() {
      switch (sortBy) {
        case 'price_asc':
          _sellingProducts.sort((a, b) => a.price.compareTo(b.price));
          _buyingProducts.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'price_desc':
          _sellingProducts.sort((a, b) => b.price.compareTo(a.price));
          _buyingProducts.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'date_desc':
          _sellingProducts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          _buyingProducts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          break;
        case 'quantity_desc':
          _sellingProducts.sort((a, b) => b.quantity.compareTo(a.quantity));
          _buyingProducts.sort((a, b) => b.quantity.compareTo(a.quantity));
          break;
      }
    });
  }
}