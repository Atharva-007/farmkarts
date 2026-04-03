import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/toast_helper.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/app_constants.dart';
import '../../services/marketplace_service.dart';
import '../../services/order_service.dart';
import '../chat/conversation_list_page.dart';
import '../../pages/enhanced_order_tracking_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final VoidCallback? onContactSeller;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.onContactSeller,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _selectedImageIndex = 0;
  int _quantity = 1;
  bool _isFavorite = false;

  bool get _isMobile => ResponsiveHelper.isMobile(context);
  bool get _isDesktop => ResponsiveHelper.isDesktop(context);
  EdgeInsets get _screenPadding => ResponsiveHelper.getScreenPadding(context);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(widget.product.name),
      backgroundColor: AppTheme.getPrimaryAccent(context),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.red : Colors.white,
          ),
          onPressed: _toggleFavorite,
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _shareProduct,
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isDesktop) {
      return _buildDesktopLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  Widget _buildMobileLayout() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: _screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductImageSection(),
              const SizedBox(height: 20),
              _buildProductInfoSection(),
              const SizedBox(height: 20),
              _buildSellerInfoSection(),
              const SizedBox(height: 20),
              _buildDescriptionSection(),
              const SizedBox(height: 20),
              _buildQuantitySelector(),
              const SizedBox(height: 100), // Space for bottom bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: _screenPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildProductImageSection(),
              ),
              const SizedBox(width: 40),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductInfoSection(),
                    const SizedBox(height: 20),
                    _buildSellerInfoSection(),
                    const SizedBox(height: 20),
                    _buildDescriptionSection(),
                    const SizedBox(height: 20),
                    _buildQuantitySelector(),
                    const SizedBox(height: 20),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImageSection() {
    final images = widget.product.imageUrls.isNotEmpty 
        ? widget.product.imageUrls 
        : ['https://via.placeholder.com/400x300?text=No+Image'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: _isMobile ? 300 : 400,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkHighlight : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: images[_selectedImageIndex],
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => Container(
                  color: isDark ? Colors.black26 : Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: isDark ? Colors.black26 : Colors.grey[200],
                  child: const Icon(Icons.error, size: 50),
                ),
              ),
            ),
          ),
          if (images.length > 1) _buildImageThumbnails(images),
        ],
      ),
    );
  }

  Widget _buildImageThumbnails(List<String> images) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 80,
      padding: const EdgeInsets.all(8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => setState(() => _selectedImageIndex = index),
            child: Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: index == _selectedImageIndex 
                      ? AppTheme.getPrimaryAccent(context) 
                      : (isDark ? Colors.white10 : Colors.grey[300]!),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: isDark ? Colors.black26 : Colors.grey[200],
                    child: const Icon(Icons.image, size: 20),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: isDark ? Colors.black26 : Colors.grey[200],
                    child: const Icon(Icons.error, size: 20),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductInfoSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.product.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
              ),
              if (widget.product.isOrganic)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.eco, color: AppTheme.success, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Organic',
                        style: TextStyle(
                          color: AppTheme.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.product.category,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '₹${widget.product.price.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getPrimaryAccent(context),
                ),
              ),
              Text(
                ' / ${widget.product.unit}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.getSecondaryTextColor(context),
                ),
              ),
            ],
          ),
          if (widget.product.quantity > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Available: ${widget.product.quantity} ${widget.product.unit}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.getSecondaryTextColor(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSellerInfoSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seller Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.getPrimaryAccent(context),
                child: Text(
                  widget.product.sellerName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.sellerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '4.5 (120 reviews)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _contactSeller,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.getPrimaryAccent(context).withOpacity(0.1),
                  foregroundColor: AppTheme.getPrimaryAccent(context),
                  elevation: 0,
                ),
                child: const Text('Contact'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.product.description.isNotEmpty
                ? widget.product.description
                : 'No description available.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.getSecondaryTextColor(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.getBorderColor(context)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                      icon: const Icon(Icons.remove),
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _quantity.toString(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _quantity++),
                      icon: const Icon(Icons.add),
                      color: AppTheme.getPrimaryAccent(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.product.unit,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.getSecondaryTextColor(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _addToCart,
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Add to Cart'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.getPrimaryAccent(context).withOpacity(0.1),
              foregroundColor: AppTheme.getPrimaryAccent(context),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: AppTheme.getPrimaryAccent(context)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _buyNow,
            icon: const Icon(Icons.flash_on),
            label: const Text('Buy Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.getPrimaryAccent(context),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    if (_isDesktop) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: _buildActionButtons(),
      ),
    );
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite ? 'Added to favorites' : 'Removed from favorites',
        ),
        backgroundColor: AppTheme.getPrimaryAccent(context),
      ),
    );
  }

  void _shareProduct() {
    Share.share(
      'Check out this amazing ${widget.product.name} for ₹${widget.product.price}/${widget.product.unit}!',
      subject: 'FarmKarts - ${widget.product.name}',
    );
  }

  void _contactSeller() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ToastHelper.showError(context, 'Please login to contact seller');
        return;
      }

      if (user.uid == widget.product.sellerId) {
        ToastHelper.showError(context, 'You cannot contact yourself');
        return;
      }

      final marketplaceService = MarketplaceService();
      await marketplaceService.contactSeller(
        product: widget.product,
        buyerName: user.displayName ?? user.email?.split('@')[0] ?? 'Buyer',
        initialMessage: 'Hi! I\'m interested in your ${widget.product.name}.',
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ConversationListPage(),
        ),
      );

      ToastHelper.showSuccess(context, 'Conversation started with seller');
    } catch (e) {
      ToastHelper.showError(context, 'Failed to contact seller: $e');
    }
  }

  void _addToCart() {
    ToastHelper.showSuccess(context, 'Added $_quantity ${widget.product.unit} to cart');
  }

  void _buyNow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ToastHelper.showError(context, 'Please login to place order');
      return;
    }

    if (user.uid == widget.product.sellerId) {
      ToastHelper.showError(context, 'You cannot buy your own product');
      return;
    }

    // Show order placement dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return OrderPlacementDialog(
          product: widget.product,
          quantity: _quantity,
        );
      },
    );
  }
}

// Order Placement Dialog
class OrderPlacementDialog extends StatefulWidget {
  final Product product;
  final int quantity;

  const OrderPlacementDialog({
    super.key,
    required this.product,
    required this.quantity,
  });

  @override
  State<OrderPlacementDialog> createState() => _OrderPlacementDialogState();
}

class _OrderPlacementDialogState extends State<OrderPlacementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  
  DeliveryType _deliveryType = DeliveryType.pickup;
  bool _isPlacingOrder = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = widget.product.price * widget.quantity;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: AppTheme.getCardColor(context),
      title: Text('Place Order', style: TextStyle(color: AppTheme.getTextColor(context))),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.getPrimaryAccent(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.getPrimaryAccent(context),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.agriculture, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.name,
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.getTextColor(context)),
                            ),
                            Text(
                              '${widget.quantity} ${widget.product.unit} × ₹${widget.product.price}',
                              style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                            ),
                            Text(
                              'Total: ₹${totalAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: AppTheme.getPrimaryAccent(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Phone Number
                TextFormField(
                  controller: _phoneController,
                  style: TextStyle(color: AppTheme.getTextColor(context)),
                  decoration: InputDecoration(
                    labelText: 'Phone Number *',
                    labelStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                    prefixIcon: Icon(Icons.phone, color: AppTheme.getPrimaryAccent(context)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Phone number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Delivery Type
                Text(
                  'Delivery Option',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.getTextColor(context)),
                ),
                const SizedBox(height: 8),
                Column(
                  children: DeliveryType.values.map((type) {
                    return RadioListTile<DeliveryType>(
                      title: Text(_getDeliveryTypeLabel(type), style: TextStyle(color: AppTheme.getTextColor(context), fontSize: 14)),
                      subtitle: Text(_getDeliveryTypeDescription(type), style: TextStyle(color: AppTheme.getSecondaryTextColor(context), fontSize: 12)),
                      value: type,
                      groupValue: _deliveryType,
                      activeColor: AppTheme.getPrimaryAccent(context),
                      onChanged: (value) {
                        setState(() => _deliveryType = value!);
                      },
                      contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),

                // Address (if delivery selected)
                if (_deliveryType == DeliveryType.delivery) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _addressController,
                    style: TextStyle(color: AppTheme.getTextColor(context)),
                    decoration: InputDecoration(
                      labelText: 'Delivery Address *',
                      labelStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                      prefixIcon: Icon(Icons.location_on, color: AppTheme.getPrimaryAccent(context)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (_deliveryType == DeliveryType.delivery &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Address is required for delivery';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  style: TextStyle(color: AppTheme.getTextColor(context)),
                  decoration: InputDecoration(
                    labelText: 'Additional Notes (Optional)',
                    labelStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                    prefixIcon: Icon(Icons.note, color: AppTheme.getPrimaryAccent(context)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.getBorderColor(context))),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isPlacingOrder ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isPlacingOrder ? null : _placeOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.getPrimaryAccent(context),
            foregroundColor: Colors.white,
          ),
          child: _isPlacingOrder
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Place Order'),
        ),
      ],
    );
  }

  String _getDeliveryTypeLabel(DeliveryType type) {
    switch (type) {
      case DeliveryType.pickup:
        return 'Pickup';
      case DeliveryType.delivery:
        return 'Home Delivery';
      case DeliveryType.courierDelivery:
        return 'Courier Delivery';
    }
  }

  String _getDeliveryTypeDescription(DeliveryType type) {
    switch (type) {
      case DeliveryType.pickup:
        return 'Collect from seller location';
      case DeliveryType.delivery:
        return 'Delivered to your address';
      case DeliveryType.courierDelivery:
        return 'Via courier service';
    }
  }

  void _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPlacingOrder = true);

    try {
      final orderService = OrderService();
      
      final orderId = await orderService.createOrder(
        product: widget.product,
        quantity: widget.quantity,
        buyerPhone: _phoneController.text.trim(),
        buyerAddress: _addressController.text.trim(),
        deliveryType: _deliveryType,
        deliveryAddress: _deliveryType == DeliveryType.delivery 
            ? _addressController.text.trim() 
            : null,
        notes: _notesController.text.trim().isNotEmpty 
            ? _notesController.text.trim() 
            : null,
        paymentMethod: 'Cash on Delivery',
      );

      Navigator.pop(context);
      
      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.getCardColor(context),
          title: Text('Order Placed Successfully!', style: TextStyle(color: AppTheme.getTextColor(context))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: AppTheme.success, size: 48),
              const SizedBox(height: 16),
              Text(
                'Your order has been placed successfully. The seller will contact you soon.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.getTextColor(context)),
              ),
              const SizedBox(height: 8),
              Text(
                'Order ID: ${orderId.substring(0, 8)}...',
                style: TextStyle(
                  color: AppTheme.getSecondaryTextColor(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EnhancedOrderTrackingPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.getPrimaryAccent(context),
                foregroundColor: Colors.white,
              ),
              child: const Text('Track Order'),
            ),
          ],
        ),
      );

    } catch (e) {
      ToastHelper.showError(context, 'Failed to place order: $e');
    } finally {
      setState(() => _isPlacingOrder = false);
    }
  }
}
