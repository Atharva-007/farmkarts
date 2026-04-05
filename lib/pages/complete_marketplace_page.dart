import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../services/product_service.dart';
import '../services/performance_service.dart';
import '../services/cart_service.dart';
import '../services/wishlist_service.dart';
import '../utils/toast_helper.dart';
import '../widgets/universal_drawer.dart';
import '../widgets/universal_header.dart';
import '../widgets/connection_status_widget.dart';
import '../widgets/premium_fab.dart';
import 'add_product_page.dart';
import 'selling_history_page.dart';
import 'cart_page.dart';
import 'enhanced_product_detail_page.dart';

class CompleteMarketplacePage extends StatefulWidget {
  const CompleteMarketplacePage({super.key});

  @override
  State<CompleteMarketplacePage> createState() =>
      _CompleteMarketplacePageState();
}

class _CompleteMarketplacePageState extends State<CompleteMarketplacePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  final ProductService _productService = ProductService();
  StreamSubscription? _productUpdateSubscription;

  List<Product> _sellingProducts = [];
  List<Product> _buyingProducts = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _loadingBuy = false;
  bool _loadingSell = false;
  UserRole? _userRole;
  String? _currentUserId;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadData();

    _productUpdateSubscription = _productService.onProductsUpdated.listen((_) {
      if (mounted) _loadData(isSilent: true);
    });

    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PerformanceService>(context, listen: false)
          .startScreenTrace('Marketplace');
    });
  }

  @override
  void dispose() {
    _productUpdateSubscription?.cancel();
    _tabController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool isSilent = false}) async {
    try {
      if (!isSilent && mounted) setState(() => _isLoading = true);

      if (_userRole == null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            if (mounted) {
              setState(() {
                final roleStr = userData['role'] ?? 'farmer';
                _userRole = UserRole.values.firstWhere(
                    (e) => e.toString().split('.').last == roleStr,
                    orElse: () => UserRole.farmer);
              });
            }
          }
        }
      }

      final categories = await _productService.getCategories();
      if (mounted) setState(() => _categories = ['All', ...categories]);

      await _fetchBuyingProducts();
      if (_userRole == UserRole.farmer || _userRole == UserRole.addat) {
        await _fetchSellingProducts();
      }

      if (mounted) {
        if (!isSilent) setState(() => _isLoading = false);
        _animationController.forward(from: 0.0);
      }
    } catch (e) {
      if (mounted && !isSilent) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBuyingProducts() async {
    if (mounted && !_isLoading) setState(() => _loadingBuy = true);
    try {
      final products = await _productService.getProducts(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (mounted)
        setState(() {
          _buyingProducts = products;
          _loadingBuy = false;
        });
    } catch (e) {
      if (mounted) setState(() => _loadingBuy = false);
    }
  }

  Future<void> _fetchSellingProducts() async {
    if (_currentUserId == null) return;

    if (mounted && !_isLoading) setState(() => _loadingSell = true);
    try {
      final products = await _productService.getSellerProducts(_currentUserId!);
      if (mounted)
        setState(() {
          _sellingProducts = products;
          _loadingSell = false;
        });
    } catch (e) {
      if (mounted) setState(() => _loadingSell = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConnectionStatusWidget(
      child: Scaffold(
        backgroundColor: AppTheme.getBackgroundColor(context),
        drawer: const UniversalDrawer(currentPage: 'marketplace'),
        body: _isLoading
            ? _buildLoadingState()
            : Stack(
                children: [
                  CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      UniversalHeader(
                        title: 'Marketplace',
                        subtitle: 'Direct from farm to you',
                        icon: Icons.storefront_rounded,
                        showProfile: true,
                        actions: [
                          if (_currentUserId != null) ...[
                            _buildCartAction(),
                            IconButton(
                              icon: const Icon(Icons.history_rounded,
                                  color: Colors.white),
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const SellingHistoryPage())),
                              tooltip: 'Selling History',
                            ),
                          ],
                        ],
                        bottom: TabBar(
                          controller: _tabController,
                          labelColor: Colors.white,
                          unselectedLabelColor:
                              Colors.white.withValues(alpha: 0.6),
                          indicatorColor: Colors.white,
                          indicatorWeight: 3,
                          tabs: const [
                            Tab(text: 'Buy Produce'),
                            Tab(text: 'My Listings'),
                          ],
                        ),
                      ),
                      SliverFillRemaining(
                        child: TabBarView(
                          controller: _tabController,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildBuyingTab(),
                            _buildSellingTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: PremiumFAB(
                        onPressed: () async {
                          final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const AddProductPage()));
                          if (result == true) _loadData(isSilent: true);
                        },
                        label: 'Add Product',
                        icon: Icons.add_circle_rounded,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.getPrimaryAccent(context)),
          const SizedBox(height: 24),
          const Text('Opening Marketplace...',
              style:
                  TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _buildBuyingTab() {
    return Column(
      children: [
        _buildFiltersSection(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchBuyingProducts,
            color: AppTheme.getPrimaryAccent(context),
            child: _loadingBuy
                ? Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.getPrimaryAccent(context)))
                : _buyingProducts.isEmpty
                    ? _buildEmptyState(
                        'No fresh produce found', Icons.search_off_rounded)
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio:
                              0.68, // Adjusted for Add to Cart button
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _buyingProducts.length,
                        itemBuilder: (context, index) {
                          return FadeTransition(
                            opacity: _animationController,
                            child: EnhancedProductCard(
                              product: _buyingProducts[index],
                              currentUserId: _currentUserId,
                            ),
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildSellingTab() {
    if (_currentUserId == null)
      return _buildEmptyState('Sign in to sell products', Icons.login_rounded,
          buttonText: 'Sign In');

    return RefreshIndicator(
      onRefresh: _fetchSellingProducts,
      color: AppTheme.getPrimaryAccent(context),
      child: _loadingSell
          ? Center(
              child: CircularProgressIndicator(
                  color: AppTheme.getPrimaryAccent(context)))
          : _sellingProducts.isEmpty
              ? _buildEmptyState('You haven\'t listed any products',
                  Icons.inventory_2_outlined,
                  buttonText: 'List Now')
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75, // Slightly taller for better fit
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _sellingProducts.length,
                  itemBuilder: (context, index) {
                    return FadeTransition(
                      opacity: _animationController,
                      child: EnhancedProductCard(
                        product: _sellingProducts[index],
                        currentUserId: _currentUserId,
                        isSellingTab: true,
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
        boxShadow: AppTheme.getPremiumShadow(context),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.getLayerColor(context).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: AppTheme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Search fresh produce...',
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppTheme.getPrimaryAccent(context)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onChanged: (v) {
                setState(() => _searchQuery = v);
                _fetchBuyingProducts();
              },
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _categories
                  .map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: _selectedCategory == cat,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = cat);
                              _fetchBuyingProducts();
                            }
                          },
                          selectedColor: AppTheme.getPrimaryAccent(context)
                              .withValues(alpha: 0.2),
                          checkmarkColor: AppTheme.getPrimaryAccent(context),
                          labelStyle: TextStyle(
                            color: _selectedCategory == cat
                                ? AppTheme.getPrimaryAccent(context)
                                : AppTheme.getSecondaryTextColor(context),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          backgroundColor: AppTheme.getLayerColor(context),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(
                              color: _selectedCategory == cat
                                  ? AppTheme.getPrimaryAccent(context)
                                  : Colors.transparent),
                        ),
                      ))
                  .toList(),
            ),
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
              icon:
                  const Icon(Icons.shopping_cart_rounded, color: Colors.white),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const CartPage())),
            ),
            if (cartCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                  constraints:
                      const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Text('$cartCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(String text, IconData icon, {String? buttonText}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
                color:
                    AppTheme.getPrimaryAccent(context).withValues(alpha: 0.05),
                shape: BoxShape.circle),
            child: Icon(icon,
                size: 64,
                color:
                    AppTheme.getPrimaryAccent(context).withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 20),
          Text(text,
              style: TextStyle(
                  color: AppTheme.getSecondaryTextColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          if (buttonText != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.getPrimaryAccent(context),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(buttonText,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}

class EnhancedProductCard extends StatefulWidget {
  final Product product;
  final String? currentUserId;
  final bool isSellingTab;

  const EnhancedProductCard({
    super.key,
    required this.product,
    this.currentUserId,
    this.isSellingTab = false,
  });

  @override
  State<EnhancedProductCard> createState() => _EnhancedProductCardState();
}

class _EnhancedProductCardState extends State<EnhancedProductCard> {
  bool _isInWishlist = false;
  bool _checkingWishlist = true;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    _checkWishlist();
  }

  Future<void> _checkWishlist() async {
    if (widget.currentUserId == null) return;
    final inList = await WishlistService.isInWishlist(widget.product.id);
    if (mounted) {
      setState(() {
        _isInWishlist = inList;
        _checkingWishlist = false;
      });
    }
  }

  Future<void> _toggleWishlist() async {
    if (widget.currentUserId == null) {
      ToastHelper.showInfo(context, 'Please login to add to wishlist');
      return;
    }

    setState(() => _isInWishlist = !_isInWishlist); // Optimistic UI
    final success = await WishlistService.toggleWishlist(widget.product.id);

    if (!success && mounted) {
      setState(() => _isInWishlist = !_isInWishlist); // Revert on failure
      ToastHelper.showError(context, 'Failed to update wishlist');
    } else if (mounted) {
      ToastHelper.showSuccess(context,
          _isInWishlist ? 'Added to favorites!' : 'Removed from favorites');
    }
  }

  Future<void> _addToCart() async {
    if (widget.currentUserId == null) {
      ToastHelper.showInfo(context, 'Please login to add to cart');
      return;
    }

    setState(() => _isAddingToCart = true);
    final success = await CartService.addToCart(widget.product.id, quantity: 1);

    if (mounted) {
      setState(() => _isAddingToCart = false);
      if (success) {
        ToastHelper.showSuccess(
            context, '${widget.product.name} added to cart!');
      } else {
        ToastHelper.showError(context, 'Failed to add to cart');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isOwnProduct = widget.product.sellerId == widget.currentUserId;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppTheme.getBorderColor(context)
                .withValues(alpha: isDark ? 0.1 : 0.5)),
        boxShadow: AppTheme.getPremiumShadow(context),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    EnhancedProductDetailPage(product: widget.product))),
        borderRadius: BorderRadius.circular(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.25,
                    child: widget.product.imageUrls.isNotEmpty
                        ? Image.network(widget.product.imageUrls.first,
                            fit: BoxFit.cover)
                        : Container(
                            color: AppTheme.getPrimaryAccent(context)
                                .withValues(alpha: 0.05),
                            child: Icon(Icons.agriculture_rounded,
                                size: 48,
                                color: AppTheme.getPrimaryAccent(context)
                                    .withValues(alpha: 0.2)),
                          ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.product.category,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  if (isOwnProduct)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4)
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_pin_rounded,
                                color: Colors.white, size: 10),
                            SizedBox(width: 4),
                            Text(
                              'OWN',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!isOwnProduct && !_checkingWishlist)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: _toggleWishlist,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4)
                            ],
                          ),
                          child: Icon(
                              _isInWishlist
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 16,
                              color: _isInWishlist ? Colors.red : Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.getTextColor(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '₹${widget.product.price.toInt()}',
                          style: TextStyle(
                              color: AppTheme.getPrimaryAccent(context),
                              fontWeight: FontWeight.w900,
                              fontSize: 16),
                        ),
                        Text(
                          '/${widget.product.unit}',
                          style: TextStyle(
                              color: AppTheme.getSecondaryTextColor(context),
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // LOCATION ROW
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 12,
                            color: AppTheme.getSecondaryTextColor(context)
                                .withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.product.location,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.getSecondaryTextColor(context),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // QUICK ACTIONS (Only for Buying tab)
                    if (!widget.isSellingTab && !isOwnProduct)
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton.icon(
                          onPressed: _isAddingToCart ? null : _addToCart,
                          icon: _isAddingToCart
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.add_shopping_cart_rounded,
                                  size: 14),
                          label: const Text('ADD CART',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      )
                    else if (isOwnProduct && !widget.isSellingTab)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.getLayerColor(context)
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text('MANAGE LISTING',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color:
                                      AppTheme.getSecondaryTextColor(context),
                                  letterSpacing: 0.5)),
                        ),
                      )
                    else
                      // Selling tab specific info
                      Row(
                        children: [
                          Icon(Icons.inventory_rounded,
                              size: 12,
                              color: AppTheme.getSecondaryTextColor(context)),
                          const SizedBox(width: 4),
                          Text(
                            'Stock: ${widget.product.quantity}',
                            style: TextStyle(
                                color: AppTheme.getSecondaryTextColor(context),
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
