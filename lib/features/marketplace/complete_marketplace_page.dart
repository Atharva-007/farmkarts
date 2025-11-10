import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../services/marketplace_service.dart';
import '../../services/user_state_service.dart';
import '../../services/conversation_service.dart';
import '../../utils/app_constants.dart';

class CompleteMarketplacePage extends StatefulWidget {
  const CompleteMarketplacePage({super.key});

  @override
  State<CompleteMarketplacePage> createState() => _CompleteMarketplacePageState();
}

class _CompleteMarketplacePageState extends State<CompleteMarketplacePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MarketplaceService _marketplaceService = MarketplaceService();
  final ConversationService _conversationService = ConversationService();
  
  List<Product> _sellingProducts = [];
  List<Product> _buyingProducts = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;
  UserRole? _userRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get user role
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final userData = UserModel.fromMap(userDoc.data()!);
          _userRole = userData.role;
        }
      }

      // Load categories
      _categories = await _marketplaceService.getCategories();
      
      // Load products
      await _loadProducts();
      
    } catch (e) {
      setState(() {
        _error = 'Error loading data: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProducts() async {
    try {
      // Load selling products (current user's products)
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _sellingProducts = await _marketplaceService.getProductsBySeller(user.uid);
      }

      // Load buying products (other users' products)
      _buyingProducts = await _marketplaceService.getProducts(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        userRole: _userRole,
        excludeCurrentUser: true,
      );

      _filterProducts();
    } catch (e) {
      setState(() {
        _error = 'Error loading products: $e';
      });
    }
  }

  void _filterProducts() {
    setState(() {
      // Filter selling products
      if (_searchQuery.isNotEmpty) {
        _sellingProducts = _sellingProducts.where((product) =>
            product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

        _buyingProducts = _buyingProducts.where((product) =>
            product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.sellerName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
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
    return Column(
      children: [
        _buildSearchBar(),
        _buildCategoryFilter(),
        Expanded(child: _buildSellingProductsList()),
      ],
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
    final result = await Navigator.pushNamed(context, '/add-product');
    if (result == true) {
      _loadData(); // Refresh the data
    }
  }

  void _viewProductDetails(Product product) {
    Navigator.pushNamed(
      context,
      '/product-detail',
      arguments: product,
    );
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
    final result = await Navigator.pushNamed(
      context,
      '/edit-product',
      arguments: product,
    );
    if (result == true) {
      _loadData();
    }
  }

  void _viewOrders(Product product) {
    Navigator.pushNamed(
      context,
      '/product-orders',
      arguments: product.id,
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Price: Low to High'),
              onTap: () {
                Navigator.pop(context);
                _sortProducts('price_asc');
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_down),
              title: const Text('Price: High to Low'),
              onTap: () {
                Navigator.pop(context);
                _sortProducts('price_desc');
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Recently Added'),
              onTap: () {
                Navigator.pop(context);
                _sortProducts('date_desc');
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Quantity Available'),
              onTap: () {
                Navigator.pop(context);
                _sortProducts('quantity_desc');
              },
            ),
          ],
        ),
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