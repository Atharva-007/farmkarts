import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/product_model.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';
import 'chat_conversation_page.dart';
import 'buyer_details_dialog.dart';

/// Enhanced Product Detail Page with full functionality
/// Features: Contact seller, bid system, buyer details for sellers, ratings
class EnhancedProductDetailPage extends StatefulWidget {
  final Product product;

  const EnhancedProductDetailPage({
    super.key,
    required this.product,
  });

  @override
  State<EnhancedProductDetailPage> createState() => _EnhancedProductDetailPageState();
}

class _EnhancedProductDetailPageState extends State<EnhancedProductDetailPage>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final ChatService _chatService = ChatService();
  final NotificationService _notificationService = NotificationService();
  
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _bidAmountController = TextEditingController();
  final TextEditingController _bidQuantityController = TextEditingController(text: '1');
  final TextEditingController _bidNotesController = TextEditingController();
  
  bool _isContactingSeller = false;
  bool _isSendingBid = false;
  int _selectedQuantity = 1;
  double _totalPrice = 0.0;
  int _currentImageIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _pageController = PageController();
    
    _animationController.forward();
    _calculateTotalPrice();
    
    _quantityController.addListener(_onQuantityChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _quantityController.dispose();
    _messageController.dispose();
    _bidAmountController.dispose();
    _bidQuantityController.dispose();
    _bidNotesController.dispose();
    _pageController.dispose();
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
          : 'Hi! I am interested in your product: ${widget.product.name}. '
            'Quantity: $_selectedQuantity ${widget.product.unit}. '
            'Total: ₹${_totalPrice.toStringAsFixed(2)}';

      final conversationId = await _chatService.startConversation(
        product: widget.product,
        buyerName: user.displayName ?? user.email ?? 'Buyer',
        initialMessage: initialMessage,
      );

      if (mounted) {
        _showSuccessMessage('Message sent successfully!');
        
        // Navigate to chat
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatConversationPage(
              conversationId: conversationId,
              product: widget.product,
            ),
          ),
        );
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

  Future<void> _sendBidOffer() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorMessage('Please login to make a bid');
      return;
    }

    if (user.uid == widget.product.sellerId) {
      _showErrorMessage('You cannot bid on your own product');
      return;
    }

    final bidAmount = double.tryParse(_bidAmountController.text);
    final bidQuantity = int.tryParse(_bidQuantityController.text) ?? 1;

    if (bidAmount == null || bidAmount <= 0) {
      _showErrorMessage('Please enter a valid bid amount');
      return;
    }

    if (bidQuantity <= 0 || bidQuantity > widget.product.quantity) {
      _showErrorMessage('Please enter a valid quantity');
      return;
    }

    setState(() {
      _isSendingBid = true;
    });

    try {
      // First, start or get existing conversation
      final conversationId = await _chatService.startConversation(
        product: widget.product,
        buyerName: user.displayName ?? user.email ?? 'Buyer',
        initialMessage: 'I would like to make a bid on your product.',
      );

      // Send bid offer
      await _chatService.sendBidOffer(
        conversationId: conversationId,
        amount: bidAmount,
        quantity: bidQuantity,
        unit: widget.product.unit,
        notes: _bidNotesController.text.trim().isNotEmpty 
            ? _bidNotesController.text.trim() 
            : null,
      );

      if (mounted) {
        Navigator.pop(context); // Close bid dialog
        _showSuccessMessage('Bid sent successfully!');
        
        // Navigate to chat
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatConversationPage(
              conversationId: conversationId,
              product: widget.product,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Failed to send bid: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingBid = false;
        });
      }
    }
  }

  void _showBidDialog() {
    _bidAmountController.text = widget.product.price.toString();
    _bidQuantityController.text = '1';
    _bidNotesController.clear();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBidDialog(),
    );
  }

  Widget _buildBidDialog() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Make a Bid',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Info
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.product.imageUrls.isNotEmpty 
                              ? widget.product.imageUrls.first 
                              : 'https://via.placeholder.com/60x60?text=No+Image',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image),
                            );
                          },
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Current Price: ₹${widget.product.price}/${widget.product.unit}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Bid Amount
                  const Text(
                    'Your Bid Amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _bidAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      suffixText: '/${widget.product.unit}',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Enter your bid amount',
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Quantity
                  const Text(
                    'Quantity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _bidQuantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      suffixText: widget.product.unit,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Enter quantity',
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Notes
                  const Text(
                    'Additional Notes (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _bidNotesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Any specific requirements or notes...',
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Total calculation
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                      ),
                    ),
                    child: ValueListenableBuilder(
                      valueListenable: _bidAmountController,
                      builder: (context, value, child) {
                        final bidAmount = double.tryParse(_bidAmountController.text) ?? 0;
                        final bidQuantity = int.tryParse(_bidQuantityController.text) ?? 1;
                        final totalBid = bidAmount * bidQuantity;
                        
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Bid Amount:'),
                                Text('₹${bidAmount.toStringAsFixed(2)}/${widget.product.unit}'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Quantity:'),
                                Text('$bidQuantity ${widget.product.unit}'),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Bid:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '₹${totalBid.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSendingBid ? null : _sendBidOffer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSendingBid
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Send Bid Offer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _viewBuyerDetails() async {
    // Get conversations for this product to show buyer details
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BuyerDetailsDialog(product: widget.product),
    );
  }

  void _shareProduct() {
    _showInfoMessage('Share functionality will be implemented soon');
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildProductInfo(),
                    _buildSellerInfo(),
                    if (!isOwnProduct) _buildPurchaseSection(),
                    if (isOwnProduct) _buildSellerActions(),
                    const SizedBox(height: 100), // Space for bottom bar
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: !isOwnProduct ? _buildBottomBar() : null,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryGreen,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: _buildImageCarousel(),
      ),
      actions: [
        IconButton(
          onPressed: _shareProduct,
          icon: const Icon(Icons.share),
          tooltip: 'Share',
        ),
      ],
    );
  }

  Widget _buildImageCarousel() {
    if (widget.product.imageUrls.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 64, color: Colors.grey),
              SizedBox(height: 8),
              Text('No Image Available', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemCount: widget.product.imageUrls.length,
          itemBuilder: (context, index) {
            return Image.network(
              widget.product.imageUrls[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.error, size: 64, color: Colors.grey),
                  ),
                );
              },
            );
          },
        ),
        
        // Image indicators
        if (widget.product.imageUrls.length > 1)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.product.imageUrls.asMap().entries.map((entry) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == entry.key
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildProductInfo() {
    return Container(
      margin: AppConstants.defaultPadding,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: AppConstants.defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Name and Price
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
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
              
              const SizedBox(height: 16),
              
              // Price
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.currency_rupee,
                      color: AppTheme.primaryGreen,
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'per ${widget.product.unit}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Product Details
              _buildInfoRow('Available Quantity', '${widget.product.quantity} ${widget.product.unit}'),
              _buildInfoRow('Location', widget.product.location),
              if (widget.product.tags.isNotEmpty)
                _buildInfoRow('Tags', widget.product.tags.join(', ')),
              
              const SizedBox(height: 16),
              
              // Description
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.product.description,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
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
            width: 120,
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
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: AppConstants.defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Seller Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryGreen,
                    radius: 30,
                    child: Text(
                      widget.product.sellerName.isNotEmpty
                          ? widget.product.sellerName[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
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
                            fontSize: 18,
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
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.orange),
                            const SizedBox(width: 4),
                            const Text('4.5'),
                            const SizedBox(width: 8),
                            Text(
                              '(24 reviews)',
                              style: TextStyle(color: Colors.grey[600]),
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
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: AppConstants.defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Purchase Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Quantity selector
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
              
              // Total price display
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
              
              // Message to seller
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

  Widget _buildSellerActions() {
    return Container(
      margin: AppConstants.defaultPadding,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: AppConstants.defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.info),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'This is your product',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'You can view buyer interactions and manage your product from here.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _viewBuyerDetails,
                  icon: const Icon(Icons.people),
                  label: const Text('View Buyer Details & Chats'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _showBidDialog,
              icon: const Icon(Icons.local_offer),
              label: const Text('Make Bid'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}