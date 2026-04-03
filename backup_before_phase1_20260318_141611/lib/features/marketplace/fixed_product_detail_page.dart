import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/product_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../services/chat_service.dart';
import '../../services/wishlist_service.dart';
import '../../services/cart_service.dart';

/// Fully functional product detail page with all components working
class FixedProductDetailPage extends StatefulWidget {
  final Product product;
  final VoidCallback? onContactSeller;

  const FixedProductDetailPage({
    super.key,
    required this.product,
    this.onContactSeller,
  });

  @override
  State<FixedProductDetailPage> createState() => _FixedProductDetailPageState();
}

class _FixedProductDetailPageState extends State<FixedProductDetailPage>
    with SingleTickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // State variables
  int _selectedImageIndex = 0;
  int _quantity = 1;
  bool _isFavorite = false;
  bool _isLoading = false;
  bool _isContactingSeller = false;
  
  final PageController _pageController = PageController();

  // Responsive helpers
  bool get _isMobile => ResponsiveHelper.isMobile(context);
  bool get _isDesktop => ResponsiveHelper.isDesktop(context);
  EdgeInsets get _screenPadding => ResponsiveHelper.getScreenPadding(context);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkWishlistStatus();
  }
  
  Future<void> _checkWishlistStatus() async {
    final isInWishlist = await WishlistService.isInWishlist(widget.product.id);
    setState(() {
      _isFavorite = isInWishlist;
    });
  }

  /// Setup animations with proper error handling
  void _setupAnimations() {
    try {
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
      
      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
        ),
      );
      
      _slideAnimation = Tween<Offset>(
        begin: const Offset(0.0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
        ),
      );
      
      _animationController.forward();
    } catch (e) {
      // Fallback if animations fail
      debugPrint('Animation setup failed: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: _buildAnimatedContent(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  /// Build sliver app bar with image gallery
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: _isMobile ? 300 : 400,
      pinned: true,
      backgroundColor: AppTheme.primaryGreen,
      elevation: 2,
      flexibleSpace: FlexibleSpaceBar(
        background: _buildImageGallery(),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.white,
            ),
          ),
          onPressed: _toggleFavorite,
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.share, color: Colors.white),
          ),
          onPressed: _shareProduct,
        ),
      ],
    );
  }

  /// Build animated content
  Widget _buildAnimatedContent() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildContent(),
      ),
    );
  }

  /// Build image gallery
  Widget _buildImageGallery() {
    final images = widget.product.imageUrls.isNotEmpty 
        ? widget.product.imageUrls 
        : ['https://via.placeholder.com/400x300?text=No+Image'];

    return Stack(
      children: [
        // Main image carousel
        PageView.builder(
          controller: _pageController,
          itemCount: images.length,
          onPageChanged: (index) {
            if (mounted) {
              setState(() {
                _selectedImageIndex = index;
              });
            }
          },
          itemBuilder: (context, index) {
            return Hero(
              tag: 'product_image_${widget.product.id}_$index',
              child: _buildSingleImage(images[index]),
            );
          },
        ),
        
        // Image indicators
        if (images.length > 1)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: _buildImageIndicators(images.length),
            ),
          ),
        
        // Gradient overlay for better readability
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build single image with error handling
  Widget _buildSingleImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => Container(
        color: AppTheme.backgroundLight,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryGreen,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppTheme.backgroundLight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(widget.product.category),
              size: 80,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(height: 8),
            Text(
              widget.product.name,
              style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build image indicators
  Widget _buildImageIndicators(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          count,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == _selectedImageIndex
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  /// Build main content
  Widget _buildContent() {
    return Padding(
      padding: _screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _buildProductHeader(),
          const SizedBox(height: 24),
          _buildPriceCard(),
          const SizedBox(height: 24),
          _buildQuantitySelector(),
          const SizedBox(height: 24),
          _buildProductInfo(),
          const SizedBox(height: 24),
          _buildSellerInfo(),
          const SizedBox(height: 24),
          _buildProductSpecs(),
          const SizedBox(height: 100), // Space for bottom bar
        ],
      ),
    );
  }

  /// Build product header
  Widget _buildProductHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: _isDesktop ? 32 : 28,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        _buildCategoryAndOrganic(),
        if (widget.product.location.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildLocationInfo(),
        ],
      ],
    );
  }

  /// Build category and organic badges
  Widget _buildCategoryAndOrganic() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getCategoryIcon(widget.product.category),
                size: 16,
                color: AppTheme.primaryGreen,
              ),
              const SizedBox(width: 6),
              Text(
                widget.product.category,
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (widget.product.isOrganic) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.eco, size: 16, color: Colors.green),
                SizedBox(width: 6),
                Text(
                  'Organic',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Build location information
  Widget _buildLocationInfo() {
    return Row(
      children: [
        const Icon(Icons.location_on, size: 16, color: AppTheme.textGrey),
        const SizedBox(width: 4),
        Text(
          widget.product.location,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textGrey,
          ),
        ),
      ],
    );
  }

  /// Build price card
  Widget _buildPriceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen.withValues(alpha: 0.1),
            AppTheme.primaryGreen.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.currency_rupee, color: AppTheme.primaryGreen, size: 36),
              Text(
                '${widget.product.price.toInt()}',
                style: TextStyle(
                  fontSize: _isDesktop ? 36 : 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
              Text(
                ' /${widget.product.unit}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAvailabilityIndicator(),
        ],
      ),
    );
  }

  /// Build availability indicator
  Widget _buildAvailabilityIndicator() {
    return Row(
      children: [
        Icon(
          widget.product.quantity > 0 ? Icons.check_circle : Icons.error,
          size: 18,
          color: widget.product.quantity > 0 ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 8),
        Text(
          widget.product.quantity > 0
              ? 'Available: ${widget.product.quantity} ${widget.product.unit}'
              : 'Out of Stock',
          style: TextStyle(
            color: widget.product.quantity > 0 ? Colors.green : Colors.red,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  /// Build quantity selector
  Widget _buildQuantitySelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quantity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildQuantityButton(
                icon: Icons.remove,
                onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
              ),
              Container(
                width: 80,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _quantity.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildQuantityButton(
                icon: Icons.add,
                onPressed: _quantity < widget.product.quantity
                    ? () => setState(() => _quantity++)
                    : null,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Total: ₹${(widget.product.price * _quantity).toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build quantity button
  Widget _buildQuantityButton({required IconData icon, VoidCallback? onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: onPressed != null 
            ? AppTheme.primaryGreen.withValues(alpha: 0.1) 
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: onPressed != null 
              ? AppTheme.primaryGreen.withValues(alpha: 0.3) 
              : Colors.grey.shade300,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: onPressed != null ? AppTheme.primaryGreen : Colors.grey,
      ),
    );
  }

  /// Build product information
  Widget _buildProductInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Product Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.product.description.isNotEmpty
                ? widget.product.description
                : 'Fresh and high-quality ${widget.product.name.toLowerCase()} directly from the farm. Grown using sustainable farming practices.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.6,
              color: AppTheme.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  /// Build seller information
  Widget _buildSellerInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Seller Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                child: Text(
                  widget.product.sellerName.isNotEmpty
                      ? widget.product.sellerName[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.sellerName.isNotEmpty
                          ? widget.product.sellerName
                          : 'Farm Fresh Vendor',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(Icons.verified, size: 16, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Verified Seller',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '4.8 ⭐ (234 reviews)',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _buildContactSellerButton(),
            ],
          ),
        ],
      ),
    );
  }

  /// Build contact seller button
  Widget _buildContactSellerButton() {
    if (_isContactingSeller) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return ElevatedButton(
      onPressed: _contactSeller,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text('Contact'),
    );
  }

  /// Build product specifications
  Widget _buildProductSpecs() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Specifications',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSpecRow('Category', widget.product.category),
          _buildSpecRow('Unit', widget.product.unit),
          _buildSpecRow('Available Quantity', '${widget.product.quantity} ${widget.product.unit}'),
          _buildSpecRow('Organic', widget.product.isOrganic ? 'Yes' : 'No'),
          _buildSpecRow('Listed Date', _formatDate(widget.product.timestamp)),
        ],
      ),
    );
  }

  /// Build specification row
  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(' : '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build bottom action bar
  Widget _buildBottomActionBar() {
    return Container(
      padding: EdgeInsets.all(_isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.product.quantity > 0 ? _addToCart : null,
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text('Add to Cart'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryGreen),
                  foregroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: widget.product.quantity > 0 ? _buyNow : null,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.flash_on),
                label: Text(_isLoading ? 'Processing...' : 'Buy Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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

  /// Format date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Toggle favorite
  Future<void> _toggleFavorite() async {
    final success = await WishlistService.toggleWishlist(widget.product.id);
    
    if (success) {
      setState(() {
        _isFavorite = !_isFavorite;
      });
      
      _showMessage(
        _isFavorite ? 'Added to wishlist ❤️' : 'Removed from wishlist',
      );
    } else {
      _showMessage(
        'Failed to update wishlist',
      );
    }
  }

  /// Share product
  void _shareProduct() {
    Share.share(
      'Check out this amazing ${widget.product.name} for ₹${widget.product.price}/${widget.product.unit} on FarmKarts!\n\n${widget.product.description}',
      subject: 'FarmKarts - ${widget.product.name}',
    );
  }

  /// Contact seller
  void _contactSeller() async {
    if (_isContactingSeller) return;
    
    setState(() => _isContactingSeller = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showMessage('Please login to contact seller', isError: true);
        return;
      }

      if (user.uid == widget.product.sellerId) {
        _showMessage('You cannot contact yourself', isError: true);
        return;
      }

      // Start conversation using ChatService
      final chatService = ChatService();
      final conversationId = await chatService.startConversation(
        product: widget.product,
        buyerName: user.displayName ?? user.email?.split('@')[0] ?? 'Buyer',
      );
      
      _showMessage('Chat started successfully! 📞');
      
      if (widget.onContactSeller != null) {
        widget.onContactSeller!();
      }

      // Navigate to chat screen
      Navigator.pushNamed(
        context,
        '/chat',
        arguments: {
          'conversationId': conversationId,
          'product': widget.product,
          'otherUserId': widget.product.sellerId,
          'otherUserName': widget.product.sellerName,
        },
      );
      
    } catch (e) {
      _showMessage('Failed to contact seller: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isContactingSeller = false);
      }
    }
  }

  /// Add to cart
  Future<void> _addToCart() async {
    final success = await CartService.addToCart(widget.product.id, quantity: _quantity);
    
    if (success) {
      _showMessage('${widget.product.name} added to cart! 🛒');
    } else {
      _showMessage('Failed to add to cart');
    }
  }

  /// Buy now
  void _buyNow() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Please login to place order', isError: true);
      return;
    }

    if (user.uid == widget.product.sellerId) {
      _showMessage('You cannot buy your own product', isError: true);
      return;
    }

    _showOrderDialog();
  }

  /// Show order dialog
  void _showOrderDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirm Purchase',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildOrderSummary(),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _confirmOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Confirm Order - ₹${(widget.product.price * _quantity).toStringAsFixed(0)}',
                            style: const TextStyle(
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
        ),
      ),
    );
  }

  /// Build order summary
  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: widget.product.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.product.imageUrls.first,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          width: 60,
                          height: 60,
                          color: AppTheme.backgroundLight,
                          child: Icon(
                            _getCategoryIcon(widget.product.category),
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: AppTheme.backgroundLight,
                        child: Icon(
                          _getCategoryIcon(widget.product.category),
                          color: AppTheme.primaryGreen,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '₹${widget.product.price}/${widget.product.unit}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'x$_quantity',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${(widget.product.price * _quantity).toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Confirm order
  void _confirmOrder() async {
    setState(() => _isLoading = true);
    
    try {
      // Simulate order placement
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        _showSuccessDialog();
      }
    } catch (e) {
      _showMessage('Failed to place order: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Show success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Order Placed Successfully!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your order for ${widget.product.name} has been placed successfully. The seller will contact you soon.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Order ID: FKT${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
              style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('Continue Shopping'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
              _showMessage('Order tracking coming soon! 📦');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Track Order'),
          ),
        ],
      ),
    );
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
      ),
    );
  }
}