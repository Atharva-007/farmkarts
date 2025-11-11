import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/product_model.dart';
import '../services/marketplace_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final MarketplaceService _marketplaceService = MarketplaceService();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _messageController = TextEditingController();
  
  bool _isContactingSeller = false;
  int _selectedQuantity = 1;
  double _totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _animationController.forward();
    _calculateTotalPrice();
    
    _quantityController.addListener(_onQuantityChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _quantityController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onQuantityChanged() {
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    setState(() {
      _selectedQuantity = quantity;
      _calculateTotalPrice();
    });
  }

  void _calculateTotalPrice() {
    _totalPrice = widget.product.price * _selectedQuantity;
  }

  Future<void> _contactSeller() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorMessage('Please login to contact seller');
      return;
    }

    if (user.uid == widget.product.sellerId) {
      _showErrorMessage('You cannot contact yourself');
      return;
    }

    setState(() {
      _isContactingSeller = true;
    });

    try {
      final initialMessage = _messageController.text.trim().isNotEmpty
          ? _messageController.text.trim()
          : 'I am interested in your product: ${widget.product.name}. '
            'Quantity: $_selectedQuantity ${widget.product.unit}. '
            'Total: ₹${_totalPrice.toStringAsFixed(2)}';

      final conversationId = await _marketplaceService.contactSeller(
        product: widget.product,
        buyerName: user.displayName ?? 'Buyer',
        initialMessage: initialMessage,
      );

      if (mounted) {
        _showSuccessMessage('Message sent successfully!');
        _showConversationCreatedDialog(conversationId);
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Failed to contact seller: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isContactingSeller = false;
        });
      }
    }
  }

  void _showConversationCreatedDialog(String conversationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.success),
            const SizedBox(width: 8),
            const Text('Message Sent'),
          ],
        ),
        content: const Text(
          'Your message has been sent to the seller. They will be notified and can respond to you directly.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
            },
            child: const Text('Continue Shopping'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Navigate to conversations if implemented
              // Navigator.pushNamed(context, '/conversations');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('View Conversations'),
          ),
        ],
      ),
    );
  }

  void _showBuyDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildBuyDialog(),
    );
  }

  Widget _buildBuyDialog() {
    return AlertDialog(
      title: const Text('Purchase Product'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Are you sure you want to purchase:'),
          const SizedBox(height: 8),
          Text(
            widget.product.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Quantity:'),
              Text('$_selectedQuantity ${widget.product.unit}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Unit Price:'),
              Text('₹${widget.product.price.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${_totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                  fontSize: 16,
                ),
              ),
            ],
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
            _proceedToPurchase();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
          ),
          child: const Text('Proceed to Buy'),
        ),
      ],
    );
  }

  void _proceedToPurchase() {
    // In a real app, this would navigate to a payment page
    // For now, we'll show a placeholder
    _showInfoMessage('Purchase feature will be implemented in the next version. Please contact the seller directly for now.');
  }

  void _shareProduct() {
    // In a real app, this would use the share plugin
    _showInfoMessage('Share feature will be implemented soon');
  }

  void _addToWishlist() {
    // In a real app, this would save to wishlist
    _showSuccessMessage('Added to wishlist (feature coming soon)');
  }

  void _showSuccessMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.success,
      textColor: Colors.white,
    );
  }

  void _showErrorMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.error,
      textColor: Colors.white,
    );
  }

  void _showInfoMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.info,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isOwnProduct = user != null && widget.product.sellerId == user.uid;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(widget.product.name),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _shareProduct,
            icon: const Icon(Icons.share),
            tooltip: 'Share',
          ),
          if (!isOwnProduct)
            IconButton(
              onPressed: _addToWishlist,
              icon: const Icon(Icons.favorite_border),
              tooltip: 'Add to Wishlist',
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildProductHeader(),
              _buildProductInfo(),
              _buildSellerInfo(),
              if (!isOwnProduct) _buildPurchaseSection(),
              if (isOwnProduct) _buildOwnProductInfo(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: !isOwnProduct ? _buildBottomBar() : null,
    );
  }

  Widget _buildProductHeader() {
    return Container(
      width: double.infinity,
      padding: AppConstants.defaultPadding,
      color: AppTheme.primaryGreen.withOpacity(0.1),
      child: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: widget.product.imageUrls.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.product.imageUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                    ),
                  )
                : _buildPlaceholderImage(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.product.category,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.product.isOrganic)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.success),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.eco, size: 16, color: AppTheme.success),
                      const SizedBox(width: 4),
                      Text(
                        'Organic',
                        style: TextStyle(
                          color: AppTheme.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            size: 48,
            color: Colors.grey[500],
          ),
          const SizedBox(height: 8),
          Text(
            'No Image',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo() {
    return Container(
      margin: AppConstants.defaultPadding,
      child: Card(
        child: Padding(
          padding: AppConstants.defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Price', '₹${widget.product.price.toStringAsFixed(2)} per ${widget.product.unit}'),
              _buildInfoRow('Available Quantity', '${widget.product.quantity} ${widget.product.unit}'),
              _buildInfoRow('Location', widget.product.location),
              if (widget.product.tags.isNotEmpty)
                _buildInfoRow('Tags', widget.product.tags.join(', ')),
              const SizedBox(height: 16),
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.product.description,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerInfo() {
    return Container(
      margin: AppConstants.defaultPadding,
      child: Card(
        child: Padding(
          padding: AppConstants.defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seller Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryGreen,
                    child: Text(
                      widget.product.sellerName.isNotEmpty
                          ? widget.product.sellerName[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.sellerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.product.location,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseSection() {
    return Container(
      margin: AppConstants.defaultPadding,
      child: Card(
        child: Padding(
          padding: AppConstants.defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Purchase Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Quantity:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixText: widget.product.unit,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Price:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${_totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'Message to Seller (Optional)',
                  hintText: 'Add any specific requirements or questions...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOwnProductInfo() {
    return Container(
      margin: AppConstants.defaultPadding,
      child: Card(
        child: Container(
          padding: AppConstants.defaultPadding,
          decoration: BoxDecoration(
            color: AppTheme.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.info.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.info),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'This is your product',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'You can view this product as buyers see it. To edit or manage this product, go to your selling history.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/selling_history');
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('View Selling History'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.info,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isContactingSeller ? null : _contactSeller,
              icon: _isContactingSeller
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.message),
              label: Text(_isContactingSeller ? 'Sending...' : 'Contact Seller'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                side: BorderSide(color: AppTheme.primaryGreen),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _showBuyDialog,
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Buy Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}