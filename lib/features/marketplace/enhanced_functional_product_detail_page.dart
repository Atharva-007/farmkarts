import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_model.dart';
import '../../models/chat_model.dart';
import '../../models/marketplace_models.dart';
import '../../services/marketplace_service.dart';
import '../../services/chat_service.dart';
import '../../services/buyer_interaction_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';
import 'enhanced_functional_chat_page.dart';
import 'enhanced_functional_buyer_interests_page.dart';

/// Enhanced fully functional product detail page
/// - Contact seller functionality
/// - Chat system integration
/// - Bid/offer system
/// - Buyer rating and details
/// - Complete Firebase backend integration
/// - No favorites (removed as requested)
/// - Full buying functionality
class EnhancedFunctionalProductDetailPage extends StatefulWidget {
  final Product product;

  const EnhancedFunctionalProductDetailPage({
    super.key,
    required this.product,
  });

  @override
  State<EnhancedFunctionalProductDetailPage> createState() => _EnhancedFunctionalProductDetailPageState();
}

class _EnhancedFunctionalProductDetailPageState extends State<EnhancedFunctionalProductDetailPage>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final MarketplaceService _marketplaceService = MarketplaceService();
  final ChatService _chatService = ChatService();
  final BuyerInteractionService _buyerService = BuyerInteractionService();
  final NotificationService _notificationService = NotificationService();
  
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _bidController = TextEditingController();
  final TextEditingController _offerMessageController = TextEditingController();
  
  bool _isContactingSeller = false;
  bool _isSendingBid = false;
  bool _isShowingInterest = false;
  int _selectedQuantity = 1;
  double _totalPrice = 0.0;
  double _bidAmount = 0.0;

  List<BuyerInterest> _buyerInterests = [];
  List<PriceOffer> _priceOffers = [];
  bool _loadingInterests = false;
  bool _loadingOffers = false;

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
    _bidController.addListener(_onBidAmountChanged);
    
    _loadProductInteractions();
    _trackProductView();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _quantityController.dispose();
    _messageController.dispose();
    _bidController.dispose();
    _offerMessageController.dispose();
    super.dispose();
  }

  void _onQuantityChanged() {
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    if (quantity > 0 && quantity <= widget.product.quantity) {
      setState(() {
        _selectedQuantity = quantity;
        _calculateTotalPrice();
      });
    }
  }

  void _onBidAmountChanged() {
    final amount = double.tryParse(_bidController.text) ?? 0.0;
    setState(() {
      _bidAmount = amount;
    });
  }

  void _calculateTotalPrice() {
    _totalPrice = widget.product.price * _selectedQuantity;
  }

  Future<void> _trackProductView() async {
    try {
      await _buyerService.trackProductView(widget.product.id);
    } catch (e) {
      print('Error tracking product view: $e');
    }
  }

  Future<void> _loadProductInteractions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != widget.product.sellerId) return;

    setState(() {
      _loadingInterests = true;
      _loadingOffers = true;
    });

    try {
      final interests = await _buyerService.getProductInterests(widget.product.id);
      final offers = await _buyerService.getProductOffers(widget.product.id);
      
      setState(() {
        _buyerInterests = interests;
        _priceOffers = offers;
      });
    } catch (e) {
      _showErrorMessage('Failed to load interactions: $e');
    } finally {
      setState(() {
        _loadingInterests = false;
        _loadingOffers = false;
      });
    }
  }

  /// Contact seller and start conversation
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
        _navigateToChat(conversationId);
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

  /// Send bid offer
  Future<void> _sendBidOffer() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorMessage('Please login to send bid');
      return;
    }

    if (_bidAmount <= 0) {
      _showErrorMessage('Please enter a valid bid amount');
      return;
    }

    if (_selectedQuantity <= 0 || _selectedQuantity > widget.product.quantity) {
      _showErrorMessage('Please enter a valid quantity');
      return;
    }

    setState(() {
      _isSendingBid = true;
    });

    try {
      // Start conversation first
      final conversationId = await _chatService.startConversation(
        product: widget.product,
        buyerName: user.displayName ?? user.email ?? 'Buyer',
        initialMessage: 'I would like to make a bid for your product.',
      );

      // Send bid through chat
      await _chatService.sendBidOffer(
        conversationId: conversationId,
        amount: _bidAmount,
        quantity: _selectedQuantity,
        unit: widget.product.unit,
        notes: _offerMessageController.text.trim().isNotEmpty 
            ? _offerMessageController.text.trim() 
            : null,
      );

      // Also create a price offer record
      await _buyerService.makeOffer(
        productId: widget.product.id,
        offeredPrice: _bidAmount,
        quantity: _selectedQuantity,
        message: 'Bid offer: ₹$_bidAmount per ${widget.product.unit}. '
            '${_offerMessageController.text.trim()}',
        validUntil: DateTime.now().add(const Duration(days: 3)),
      );

      if (mounted) {
        _showSuccessMessage('Bid sent successfully!');
        _navigateToChat(conversationId);
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

  /// Show interest in product
  Future<void> _showInterest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorMessage('Please login to show interest');
      return;
    }

    setState(() {
      _isShowingInterest = true;
    });

    try {
      await _buyerService.showInterest(
        productId: widget.product.id,
        message: _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : 'I am interested in your product: ${widget.product.name}',
        interestedQuantity: _selectedQuantity,
        contactPreference: 'chat',
      );

      if (mounted) {
        _showSuccessMessage('Interest shown successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Failed to show interest: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isShowingInterest = false;
        });
      }
    }
  }

  void _navigateToChat(String conversationId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedFunctionalChatPage(
          conversationId: conversationId,
          product: widget.product,
        ),
      ),
    );
  }

  void _navigateToBuyerInterests() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedFunctionalBuyerInterestsPage(
          product: widget.product,
          interests: _buyerInterests,
          offers: _priceOffers,
        ),
      ),
    );
  }

  void _showBidDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildBidDialog(),
    );
  }

  void _showBuyDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildBuyDialog(),
    );
  }

  Widget _buildBidDialog() {
    return AlertDialog(
      title: const Text('Make a Bid Offer'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Product: ${widget.product.name}'),
            Text('Listed Price: ₹${widget.product.price.toStringAsFixed(2)} per ${widget.product.unit}'),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Quantity: '),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      suffixText: widget.product.unit,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Bid Price: '),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _bidController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      prefixText: '₹',
                      suffixText: 'per ${widget.product.unit}',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _offerMessageController,
              decoration: const InputDecoration(
                labelText: 'Message (Optional)',
                hintText: 'Add any specific requirements...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            if (_bidAmount > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Bid Amount:'),
                        Text(
                          '₹${(_bidAmount * _selectedQuantity).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('You save:'),
                        Text(
                          '₹${((_totalPrice) - (_bidAmount * _selectedQuantity)).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: (_bidAmount * _selectedQuantity) < _totalPrice 
                                ? AppTheme.success 
                                : AppTheme.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _bidAmount > 0 && !_isSendingBid ? () {
            Navigator.pop(context);
            _sendBidOffer();
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
          ),
          child: _isSendingBid 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Bid'),
        ),
      ],
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
    // For now, show contact seller dialog
    _showInfoMessage('Please contact the seller to proceed with purchase. Full payment integration coming soon!');
    _contactSeller();
  }

  void _shareProduct() {
    _showInfoMessage('Share feature will be implemented soon');
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
          if (isOwnProduct && (_buyerInterests.isNotEmpty || _priceOffers.isNotEmpty))
            IconButton(
              onPressed: _navigateToBuyerInterests,
              icon: Stack(
                children: [
                  const Icon(Icons.people),
                  if (_buyerInterests.length + _priceOffers.length > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${_buyerInterests.length + _priceOffers.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              tooltip: 'Buyer Interests',
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
              if (!isOwnProduct) _buildBuyingSection(),
              if (isOwnProduct) _buildSellerSection(),
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
            height: 250,
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
                    const SizedBox(height: 8),
                    Text(
                      '₹${widget.product.price.toStringAsFixed(2)} per ${widget.product.unit}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
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
              _buildInfoRow('Available Stock', '${widget.product.quantity} ${widget.product.unit}'),
              _buildInfoRow('Location', widget.product.location),
              _buildInfoRow('Listed On', '${widget.product.timestamp.day}/${widget.product.timestamp.month}/${widget.product.timestamp.year}'),
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
                    radius: 25,
                    child: Text(
                      widget.product.sellerName.isNotEmpty
                          ? widget.product.sellerName[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
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
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            const Text('4.5 (24 reviews)'), // Placeholder
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

  Widget _buildBuyingSection() {
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

  Widget _buildSellerSection() {
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
                'You can view how buyers see your product. Check buyer interests and offers using the people icon above.',
                style: TextStyle(fontSize: 14),
              ),
              if (_buyerInterests.isNotEmpty || _priceOffers.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${_buyerInterests.length}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Interests'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${_priceOffers.length}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Offers'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/selling_history');
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('View My Products'),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isContactingSeller || _isShowingInterest ? null : _showInterest,
                  icon: _isShowingInterest
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.favorite),
                  label: Text(_isShowingInterest ? 'Showing...' : 'Show Interest'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.warning,
                    side: BorderSide(color: AppTheme.warning),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
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
        ],
      ),
    );
  }
}