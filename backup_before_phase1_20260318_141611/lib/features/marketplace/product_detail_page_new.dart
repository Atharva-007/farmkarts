import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/product_service.dart';
import '../../models/product_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';
import '../orders/order_detail_page.dart';

class ProductDetailPageNew extends StatefulWidget {
  final String productId;
  
  const ProductDetailPageNew({Key? key, required this.productId}) : super(key: key);

  @override
  State<ProductDetailPageNew> createState() => _ProductDetailPageNewState();
}

class _ProductDetailPageNewState extends State<ProductDetailPageNew> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final ProductService _productService = ProductService();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _messageController = TextEditingController();
  
  Product? _product;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _selectedImageIndex = 0;
  bool _showBuyDialog = false;
  int _selectedQuantity = 1;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadProduct();
  }

  void _setupAnimations() {
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
  }

  Future<void> _loadProduct() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final product = await _productService.getProductById(widget.productId);
      
      if (mounted) {
        if (product != null) {
          setState(() {
            _product = product;
            _isLoading = false;
          });
          _animationController.forward();
        } else {
          setState(() {
            _hasError = true;
            _errorMessage = 'Product not found';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading product: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showBuyBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildBuyBottomSheet(),
    );
  }

  void _showContactSellerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Seller'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Write your message to the seller...',
                border: OutlineInputBorder(),
              ),
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
              // Implement contact seller functionality
              Navigator.pop(context);
              _showSuccessSnackBar('Message sent to seller!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _processBuyRequest() {
    // Implement buy request processing
    Navigator.pop(context); // Close bottom sheet
    _showSuccessSnackBar('Buy request sent successfully!');
    
    // Navigate to order tracking or confirmation page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OrderDetailPage(orderId: 'temp_order_id'),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _quantityController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: _buildBody(),
      bottomNavigationBar: _product != null && !_isCurrentUserProduct() 
          ? _buildBottomActionBar() 
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingWidget();
    }
    
    if (_hasError || _product == null) {
      return _buildErrorWidget();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: AppConstants.defaultPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductHeader(),
                  const SizedBox(height: 16),
                  _buildPriceSection(),
                  const SizedBox(height: 16),
                  _buildDescriptionSection(),
                  const SizedBox(height: 16),
                  _buildDetailsSection(),
                  const SizedBox(height: 16),
                  _buildSellerSection(),
                  const SizedBox(height: 16),
                  if (_product!.tags.isNotEmpty) _buildTagsSection(),
                  const SizedBox(height: 100), // Extra space for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryGreen),
          SizedBox(height: 16),
          Text('Loading product details...', style: TextStyle(color: AppTheme.textGrey)),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: AppConstants.defaultPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.error),
              const SizedBox(height: 16),
              Text(
                'Product Not Found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textGrey,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppTheme.primaryGreen,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: _buildImageCarousel(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // Implement share functionality
            _showSuccessSnackBar('Product link copied to clipboard!');
          },
        ),
      ],
    );
  }

  Widget _buildImageCarousel() {
    final images = _product!.imageUrls;
    
    if (images.isEmpty) {
      return Container(
        color: AppTheme.lightGreen.withAlpha(100),
        child: const Center(
          child: Icon(
            Icons.agriculture,
            size: 80,
            color: AppTheme.primaryGreen,
          ),
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: (index) {
            setState(() {
              _selectedImageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return Image.network(
              images[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppTheme.lightGreen.withAlpha(100),
                  child: const Center(
                    child: Icon(Icons.image, size: 60, color: AppTheme.textGrey),
                  ),
                );
              },
            );
          },
        ),
        
        // Image indicators
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: images.asMap().entries.map((entry) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedImageIndex == entry.key 
                        ? Colors.white 
                        : Colors.white.withAlpha(100),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildProductHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _product!.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_product!.isOrganic)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.success.withAlpha(100),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.eco, size: 16, color: AppTheme.success),
                    const SizedBox(width: 4),
                    Text(
                      'ORGANIC',
                      style: TextStyle(
                        color: AppTheme.success,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${_product!.category} • Available: ${_product!.quantity} ${_product!.unit}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Row(
          children: [
            Icon(Icons.currency_rupee, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            Text(
              '₹${_product!.price.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
            Text(
              '/${_product!.unit}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textGrey,
              ),
            ),
            const Spacer(),
            Text(
              _product!.quantity > 0 ? 'In Stock' : 'Out of Stock',
              style: TextStyle(
                color: _product!.quantity > 0 ? AppTheme.success : AppTheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _product!.description.isNotEmpty 
                  ? _product!.description 
                  : 'No description available.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Category', _product!.category),
            _buildDetailRow('Unit', _product!.unit),
            _buildDetailRow('Available Quantity', '${_product!.quantity} ${_product!.unit}'),
            if (_product!.location.isNotEmpty)
              _buildDetailRow('Location', _product!.location),
            _buildDetailRow('Listed', _formatDate(_product!.timestamp)),
            _buildDetailRow('Organic', _product!.isOrganic ? 'Yes' : 'No'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textGrey,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerSection() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seller Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen,
                  child: Text(
                    _product!.sellerName.isNotEmpty 
                        ? _product!.sellerName[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _product!.sellerName.isNotEmpty 
                            ? _product!.sellerName 
                            : 'Unknown Seller',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_product!.location.isNotEmpty)
                        Text(
                          _product!.location,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textGrey,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!_isCurrentUserProduct())
                  TextButton(
                    onPressed: _showContactSellerDialog,
                    child: const Text('Contact'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tags',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _product!.tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  backgroundColor: AppTheme.lightGreen.withAlpha(100),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: AppConstants.defaultPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showContactSellerDialog,
              icon: const Icon(Icons.chat),
              label: const Text('Contact'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                side: BorderSide(color: AppTheme.primaryGreen),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _product!.quantity > 0 ? _showBuyBottomSheet : null,
              icon: const Icon(Icons.shopping_cart),
              label: Text(_product!.quantity > 0 ? 'Buy Now' : 'Out of Stock'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _product!.quantity > 0 ? AppTheme.primaryGreen : AppTheme.textGrey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyBottomSheet() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: AppConstants.defaultPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buy ${_product!.name}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Quantity Selection
            Row(
              children: [
                Text(
                  'Quantity:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _selectedQuantity > 1 
                      ? () {
                          setState(() {
                            _selectedQuantity--;
                            _quantityController.text = _selectedQuantity.toString();
                          });
                        }
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _quantityController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final quantity = int.tryParse(value) ?? 1;
                      setState(() {
                        _selectedQuantity = quantity.clamp(1, _product!.quantity);
                      });
                    },
                  ),
                ),
                IconButton(
                  onPressed: _selectedQuantity < _product!.quantity 
                      ? () {
                          setState(() {
                            _selectedQuantity++;
                            _quantityController.text = _selectedQuantity.toString();
                          });
                        }
                      : null,
                  icon: const Icon(Icons.add),
                ),
                Text(
                  _product!.unit,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Total Price
            Row(
              children: [
                Text(
                  'Total: ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '₹${(_product!.price * _selectedQuantity).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _processBuyRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Confirm Purchase'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isCurrentUserProduct() {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && currentUser.uid == _product?.sellerId;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}