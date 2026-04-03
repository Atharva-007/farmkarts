import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../services/marketplace_service.dart';
import '../services/product_service.dart';
import '../services/user_state_service.dart';
import '../services/conversation_service.dart';
import '../services/image_optimization_service.dart';
import '../services/performance_service.dart';
import '../services/wishlist_service.dart';
import '../services/cart_service.dart';
import '../utils/app_constants.dart';
import '../utils/responsive_helper.dart';
import '../widgets/universal_header.dart';
import '../widgets/universal_drawer.dart';
import '../widgets/connection_status_widget.dart';
import '../features/profile/profile_dashboard.dart';
import 'orders_page.dart';
import 'add_product_page.dart';
import 'selling_history_page.dart';
import 'buying_list_page.dart';
import 'cart_page.dart';
import 'enhanced_product_detail_page.dart';

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
  final ImageOptimizationService _imageOptimizationService = ImageOptimizationService();
  
  List<Product> _sellingProducts = [];
  List<Product> _buyingProducts = [];
  List<String> _categories = ['All'];
  final ValueNotifier<String> _selectedCategory = ValueNotifier<String>('All');
  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');
  bool _isLoading = true;
  bool _loadingBuy = false;
  bool _loadingSell = false;
  String? _error;
  UserRole? _userRole;
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set initial tab to 0 (Buy Products) as requested
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _loadData();
    
    // Phase 3: Track screen load performance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PerformanceService>(context, listen: false).startScreenTrace('Marketplace');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _selectedCategory.dispose();
    _searchQuery.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('CompleteMarketplacePage: Loading marketplace data...');

      // Phase 3: Track data load performance
      final perfService = Provider.of<PerformanceService>(context, listen: false);
      
      await perfService.trackOperation(
        operationName: 'load_marketplace_data',
        operation: () async {
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
            }
          }

          // Load categories
          _categories = ['All', ...(await _productService.getCategories())];
          
          // Load products
          await _loadProducts();
          return null;
        },
      );
      
    } catch (e) {
      print('CompleteMarketplacePage: Error loading data: $e');
      if (mounted) {
        setState(() {
          _error = 'Error loading data: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        Provider.of<PerformanceService>(context, listen: false).stopScreenTrace('Marketplace');
      }
    }
  }

  Future<void> _loadProducts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      if (!mounted) return;
      print('CompleteMarketplacePage: Loading products for user ${user.uid}');
      
      // Load selling products
      setState(() => _loadingSell = true);
      final sellingFuture = _productService.getProducts(
        sellerId: user.uid,
        isAvailable: null,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      );

      // Load buying products
      if (mounted) setState(() => _loadingBuy = true);
      final buyingFuture = _productService.getProducts(
        category: _selectedCategory.value == 'All' ? null : _selectedCategory.value,
        excludeSeller: user.uid,
        isAvailable: true,
        sortBy: 'createdAt',
        sortOrder: 'desc',
        limit: 50,
      );


      final results = await Future.wait([sellingFuture, buyingFuture]);
      
      if (mounted) {
        setState(() {
          _sellingProducts = results[0];
          _buyingProducts = results[1];
          _loadingSell = false;
          _loadingBuy = false;
        });
        _filterProducts();
      }
    } catch (e) {
      print('CompleteMarketplacePage: Error loading products: $e');
      if (mounted) {
        setState(() {
          if (e.toString().contains('network') || e.toString().contains('unavailable')) {
            _error = '🌐 Network error. Please check your internet connection. You can still view cached products.';
          } else {
            _error = 'Error loading products: $e';
          }
          _loadingSell = false;
          _loadingBuy = false;
        });
      }
    }
  }

  void _filterProducts() {
    if (mounted) {
      setState(() {});
    }
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
                  _sortProducts('date_desc');
                },
              ),
              ListTile(
                title: const Text('Price: Low to High'),
                leading: const Icon(Icons.arrow_upward),
                onTap: () {
                  Navigator.pop(context);
                  _sortProducts('price_asc');
                },
              ),
              ListTile(
                title: const Text('Price: High to Low'),
                leading: const Icon(Icons.arrow_downward),
                onTap: () {
                  Navigator.pop(context);
                  _sortProducts('price_desc');
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ConnectionStatusWidget(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        drawer: const UniversalDrawer(currentPage: 'marketplace'),
        body: CustomScrollView(
          slivers: [
          // Universal Header like other pages
          UniversalHeader(
            title: 'Marketplace',
            subtitle: user != null ? 'Buy and Sell Agricultural Products' : 'Sign in to access marketplace',
            icon: Icons.store,
            actions: [
              if (user != null) ...[
                _buildCartAction(),
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.white),
                  tooltip: 'Selling History',
                  onPressed: () => _navigateToSellingHistory(),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
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
                          const Text('Refresh'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'sort',
                      child: Row(
                        children: [
                          Icon(Icons.sort),
                          SizedBox(width: 8),
                          const Text('Sort'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
            bottom: user != null ? PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: isDark ? AppTheme.getPrimaryAccent(context) : Colors.white,
                  ),
                  labelColor: isDark ? Colors.white : AppTheme.getPrimaryAccent(context),
                  unselectedLabelColor: Colors.white.withOpacity(0.7),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(text: 'BUY PRODUCT'),
                    Tab(text: 'MY PRODUCT'),
                  ],
                ),
              ),
            ) : null,
          ),
          
          // Error Banner
          if (_error != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
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
            ),
          
          // Content
          SliverFillRemaining(
            child: user == null 
                ? _buildGuestView() 
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBuyingTab(),
                      _buildSellingTab(),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: user != null 
          ? Container(
              margin: const EdgeInsets.only(bottom: 80), // Position above bottom nav
              child: FloatingActionButton(
                heroTag: 'marketplace_fab_complete',
                onPressed: _navigateToAddProduct,
                backgroundColor: AppTheme.getPrimaryAccent(context),
                elevation: 4,
                child: const Icon(Icons.add, color: Colors.white, size: 30),
              ),
            )
          : null,
    ),
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
            color: AppTheme.getSecondaryTextColor(context).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome to Marketplace',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.getPrimaryAccent(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please log in to buy and sell products',
            style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.getPrimaryAccent(context),
              foregroundColor: Colors.white,
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildSellingTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Please login to see your products'));

    return StreamBuilder<List<Product>>(
      stream: _productService.getSellerProductsStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading products: ${snapshot.error}'));
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return _buildEmptyState('You haven\'t added any products yet', 'Add Product');
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductCard(product, isSellingMode: true);
            },
          ),
        );
      },
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
        controller: _searchController,
        style: TextStyle(color: AppTheme.getTextColor(context)),
        decoration: InputDecoration(
          hintText: 'Search products...', 
          hintStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
          prefixIcon: Icon(Icons.search, color: AppTheme.getSecondaryTextColor(context)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.getBorderColor(context).withOpacity(0.5)),
          ),
          filled: true,
          fillColor: Theme.of(context).cardColor,
        ),
        onChanged: (value) {
          _searchQuery.value = value;
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
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ValueListenableBuilder<String>(
              valueListenable: _selectedCategory,
              builder: (context, selected, _) {
                final isSelected = category == selected;
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: AppTheme.getPrimaryAccent(context).withOpacity(0.2),
                  checkmarkColor: AppTheme.getPrimaryAccent(context),
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.getPrimaryAccent(context) : AppTheme.getSecondaryTextColor(context),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    _selectedCategory.value = category;
                    _loadProducts();
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBuyingProductsList() {
    if (_loadingBuy && _buyingProducts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_buyingProducts.isEmpty) {
      return _buildEmptyState('No products available', 'Refresh');
    }

    // Phase 3: High-Performance Granular Rebuild Grid
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ValueListenableBuilder<String>(
        valueListenable: _searchQuery,
        builder: (context, query, _) {
          final filtered = _buyingProducts.where((p) {
            return p.name.toLowerCase().contains(query.toLowerCase()) ||
                   p.category.toLowerCase().contains(query.toLowerCase());
          }).toList();

          if (filtered.isEmpty) {
            return const Center(child: Text('No matching products found'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemCount: filtered.length,
            cacheExtent: 1000,
            itemBuilder: (context, index) {
              final product = filtered[index];
              return _buildProductCard(product, isSellingMode: false);
            },
          );
        },
      ),
    );
  }

  Widget _buildNearbyProductsList() {
    if (_loadingBuy && _buyingProducts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_buyingProducts.isEmpty) {
      return _buildEmptyState('No products nearby', 'Refresh');
    }

    // Phase 3: Optimized Swipeable List
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _buyingProducts.length,
        itemBuilder: (context, index) {
          final product = _buyingProducts[index];
          
          return Dismissible(
            key: Key('nearby_${product.id}'),
            background: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            secondaryBackground: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.green,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('BUY NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.shopping_cart, color: Colors.white),
                ],
              ),
            ),
            onDismissed: (direction) {
              if (direction == DismissDirection.endToStart) {
                // Swipe Left (Secondary) -> Buy
                _contactSeller(product);
              }
              setState(() {
                _buyingProducts.removeAt(index);
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: _buildProductRowCard(product),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductRowCard(Product product) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _viewProductDetails(product),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: SizedBox(
                width: 100,
                height: 100,
                child: product.imageUrls.isNotEmpty
                    ? _imageOptimizationService.optimizedImage(
                        context: context,
                        imageUrl: product.imageUrls.first,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: AppTheme.getIconBackgroundColor(context),
                        child: Icon(Icons.image, color: AppTheme.getPrimaryAccent(context)),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${product.price} / ${product.unit}',
                      style: TextStyle(color: AppTheme.getPrimaryAccent(context), fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Seller: ${product.sellerName}',
                      style: TextStyle(fontSize: 12, color: AppTheme.getSecondaryTextColor(context)),
                    ),
                  ],
                ),
              ),
            ),
            Icon(Icons.swipe, color: AppTheme.getSecondaryTextColor(context), size: 20),
            const SizedBox(width: 8),
          ],
        ),
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
            color: AppTheme.getSecondaryTextColor(context).withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: AppTheme.getSecondaryTextColor(context)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.getPrimaryAccent(context),
              foregroundColor: Colors.white,
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildCartAction() {
    return StreamBuilder<QuerySnapshot>(
      stream: CartService.getCartStream(),
      builder: (context, snapshot) {
        final cartCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
        
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              onPressed: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const CartPage())
              ),
              tooltip: 'Shopping Cart',
            ),
            if (cartCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$cartCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _addToCart(Product product) async {
    final success = await CartService.addToCart(product.id);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to cart!'),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const CartPage())
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add to cart')),
        );
      }
    }
  }

  Widget _buildProductCard(Product product, {required bool isSellingMode}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 2,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDark ? BorderSide(color: AppTheme.getBorderColor(context)) : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _viewProductDetails(product),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phase 3: Optimized Image Loading with Wishlist Button
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: isSellingMode ? 2.2 : 1.3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: product.imageUrls.isNotEmpty
                        ? _imageOptimizationService.optimizedImage(
                            context: context,
                            imageUrl: product.imageUrls.first,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )

                        : Container(
                            color: AppTheme.getIconBackgroundColor(context),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(Icons.image, color: AppTheme.getPrimaryAccent(context).withOpacity(0.5), size: 40),
                                if (isSellingMode)
                                  Positioned(
                                    bottom: 8,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _addPhotoToProduct(product),
                                      icon: const Icon(Icons.add_a_photo, size: 16),
                                      label: const Text('Add Photo', style: TextStyle(fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.getPrimaryAccent(context),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        minimumSize: const Size(0, 30),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                  ),
                ),
                // Wishlist button (only in buying mode)
                if (!isSellingMode)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _buildWishlistButton(product.id),
                  ),
              ],
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 14,
                        color: AppTheme.getTextColor(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${product.price} / ${product.unit}',
                      style: TextStyle(
                        color: AppTheme.getPrimaryAccent(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    if (isSellingMode) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _editProduct(product),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                visualDensity: VisualDensity.compact,
                                minimumSize: const Size(0, 28),
                                side: BorderSide(color: AppTheme.getPrimaryAccent(context).withOpacity(0.5)),
                              ),
                              child: Text('Edit', style: TextStyle(fontSize: 11, color: AppTheme.getPrimaryAccent(context))),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _viewOrders(product),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                visualDensity: VisualDensity.compact,
                                minimumSize: const Size(0, 28),
                                side: BorderSide(color: AppTheme.getPrimaryAccent(context).withOpacity(0.5)),
                              ),
                              child: Text('Orders', style: TextStyle(fontSize: 11, color: AppTheme.getPrimaryAccent(context))),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _addToCart(product),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.getPrimaryAccent(context),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                minimumSize: const Size(0, 32),
                              ),
                              child: const Icon(Icons.add_shopping_cart, size: 18),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () => _contactSeller(product),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? AppTheme.darkHighlight : Colors.white,
                                foregroundColor: AppTheme.getPrimaryAccent(context),
                                side: BorderSide(color: AppTheme.getPrimaryAccent(context)),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                minimumSize: const Size(0, 32),
                              ),
                              child: const Text('Contact', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                        ],
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

  Widget _buildWishlistButton(String productId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return FutureBuilder<bool>(
      future: WishlistService.isInWishlist(productId),
      builder: (context, snapshot) {
        final isInWishlist = snapshot.data ?? false;
        
        return Container(
          decoration: BoxDecoration(
            color: (isDark ? AppTheme.darkSurface : Colors.white).withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              isInWishlist ? Icons.favorite : Icons.favorite_border,
              color: isInWishlist ? Colors.red : AppTheme.getSecondaryTextColor(context),
              size: 20,
            ),
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            onPressed: () => _toggleWishlist(productId),
          ),
        );
      },
    );
  }

  Future<void> _toggleWishlist(String productId) async {
    final success = await WishlistService.toggleWishlist(productId);
    
    if (mounted) {
      if (success) {
        final isInWishlist = await WishlistService.isInWishlist(productId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isInWishlist ? 'Added to wishlist' : 'Removed from wishlist'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Refresh the UI
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update wishlist'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _navigateToAddProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProductPage()),
    );
    if (result == true) _loadData();
  }

  void _viewProductDetails(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedProductDetailPage(product: product),
      ),
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductPage(product: product),
      ),
    );
    if (result == true) _loadData();
  }

  void _viewOrders(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OrdersPage(initialFilter: 'all'),
      ),
    );
  }

  Future<void> _addPhotoToProduct(Product product) async {
    final ImagePicker picker = ImagePicker();
    
    // Show selection dialog
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryGreen),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryGreen),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1024,
      );

      if (image == null) return;

      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryGreen),
                  SizedBox(height: 16),
                  Text('Uploading photo...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('products/${product.id}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      final uploadTask = await storageRef.putFile(File(image.path));
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Update product in Firestore
      await _productService.updateProduct(product.id, {
        'imageUrls': [downloadUrl],
      });

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo added successfully!'),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadData(); // Refresh data to show new image
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context); // Close loading if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photo: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
      }
    });
  }
}
