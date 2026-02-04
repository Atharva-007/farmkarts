import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/toast_helper.dart';
import '../../models/product_model.dart';
import '../../models/marketplace_models.dart';
import '../../models/chat_model.dart';
import '../../services/buyer_interaction_service.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';
import 'enhanced_functional_chat_page.dart';

/// Page to show buyer interests and offers for seller's products
class EnhancedFunctionalBuyerInterestsPage extends StatefulWidget {
  final Product product;
  final List<BuyerInterest> interests;
  final List<PriceOffer> offers;

  const EnhancedFunctionalBuyerInterestsPage({
    super.key,
    required this.product,
    required this.interests,
    required this.offers,
  });

  @override
  State<EnhancedFunctionalBuyerInterestsPage> createState() => _EnhancedFunctionalBuyerInterestsPageState();
}

class _EnhancedFunctionalBuyerInterestsPageState extends State<EnhancedFunctionalBuyerInterestsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BuyerInteractionService _buyerService = BuyerInteractionService();
  final ChatService _chatService = ChatService();
  
  List<BuyerInterest> _interests = [];
  List<PriceOffer> _offers = [];
  Map<String, Map<String, dynamic>> _buyerDetails = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _interests = List.from(widget.interests);
    _offers = List.from(widget.offers);
    _loadBuyerDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBuyerDetails() async {
    setState(() => _loading = true);
    
    final buyerIds = <String>{};
    buyerIds.addAll(_interests.map((i) => i.buyerId));
    buyerIds.addAll(_offers.map((o) => o.buyerId));

    for (final buyerId in buyerIds) {
      try {
        final details = await _chatService.getBuyerDetails(buyerId);
        _buyerDetails[buyerId] = details;
      } catch (e) {
        print('Error loading buyer details for $buyerId: $e');
      }
    }
    
    setState(() => _loading = false);
  }

  Future<void> _respondToInterest(BuyerInterest interest, String status) async {
    try {
      await _buyerService.respondToInterest(
        interest.id,
        status,
        response: status == 'accepted' 
            ? 'Thank you for your interest! I would like to discuss this further.'
            : 'Thank you for your interest, but I cannot proceed at this time.',
      );
      
      // Update local state
      setState(() {
        final index = _interests.indexWhere((i) => i.id == interest.id);
        if (index >= 0) {
          // Create updated interest (assuming we have a copyWith method or similar)
          _interests[index] = BuyerInterest(
            id: interest.id,
            productId: interest.productId,
            buyerId: interest.buyerId,
            buyerName: interest.buyerName,
            buyerEmail: interest.buyerEmail,
            message: interest.message,
            interestedQuantity: interest.interestedQuantity,
            contactPreference: interest.contactPreference,
            status: status,
            createdAt: interest.createdAt,
          );
        }
      });

      _showSuccessMessage(status == 'accepted' 
          ? 'Interest accepted! You can now chat with the buyer.'
          : 'Interest declined.');

      if (status == 'accepted') {
        _startChatWithBuyer(interest.buyerId, interest.buyerName);
      }
    } catch (e) {
      _showErrorMessage('Failed to respond: $e');
    }
  }

  Future<void> _respondToOffer(PriceOffer offer, String status) async {
    try {
      await _buyerService.respondToOffer(
        offer.id,
        status,
        response: status == 'accepted' 
            ? 'Offer accepted! Let\'s proceed with the transaction.'
            : 'Sorry, I cannot accept this offer at this time.',
      );
      
      // Update local state
      setState(() {
        final index = _offers.indexWhere((o) => o.id == offer.id);
        if (index >= 0) {
          _offers[index] = PriceOffer(
            id: offer.id,
            productId: offer.productId,
            buyerId: offer.buyerId,
            buyerName: offer.buyerName,
            buyerEmail: offer.buyerEmail,
            offeredPrice: offer.offeredPrice,
            quantity: offer.quantity,
            message: offer.message,
            status: status,
            validUntil: offer.validUntil,
            createdAt: offer.createdAt,
            respondedAt: DateTime.now(),
            response: status == 'accepted' 
                ? 'Offer accepted! Let\'s proceed with the transaction.'
                : 'Sorry, I cannot accept this offer at this time.',
          );
        }
      });

      _showSuccessMessage(status == 'accepted' 
          ? 'Offer accepted! Transaction will be created.'
          : 'Offer declined.');

      if (status == 'accepted') {
        _startChatWithBuyer(offer.buyerId, offer.buyerName);
      }
    } catch (e) {
      _showErrorMessage('Failed to respond: $e');
    }
  }

  Future<void> _startChatWithBuyer(String buyerId, String buyerName) async {
    try {
      final conversationId = await _chatService.startConversation(
        product: widget.product,
        buyerName: buyerName,
        initialMessage: 'Thank you for your interest in my product!',
      );
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EnhancedFunctionalChatPage(
            conversationId: conversationId,
            product: widget.product,
          ),
        ),
      );
    } catch (e) {
      _showErrorMessage('Failed to start chat: $e');
    }
  }

  void _viewBuyerProfile(String buyerId) {
    final details = _buyerDetails[buyerId];
    if (details == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Buyer Profile: ${details['name']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (details['profileImageUrl'] != null && details['profileImageUrl'].isNotEmpty)
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(details['profileImageUrl']),
                  ),
                ),
              const SizedBox(height: 16),
              _buildDetailRow('Name', details['name'] ?? 'Unknown'),
              _buildDetailRow('Email', details['email'] ?? 'Not provided'),
              _buildDetailRow('Phone', details['phone'] ?? 'Not provided'),
              _buildDetailRow('Location', details['location'] ?? 'Not provided'),
              _buildDetailRow('Rating', '${details['rating'].toStringAsFixed(1)} (${details['totalRatings']} reviews)'),
              _buildDetailRow('Member Since', '${(details['joinDate'] as DateTime).day}/${(details['joinDate'] as DateTime).month}/${(details['joinDate'] as DateTime).year}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startChatWithBuyer(buyerId, details['name']);
            },
            child: const Text('Start Chat'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: AppTheme.success,
      textColor: Colors.white,
    );
  }

  void _showErrorMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: AppTheme.error,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Buyer Interests'),
            Text(
              widget.product.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Interests (${_interests.length})'),
            Tab(text: 'Offers (${_offers.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInterestsTab(),
          _buildOffersTab(),
        ],
      ),
    );
  }

  Widget _buildInterestsTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_interests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No buyer interests yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Buyer interests will appear here',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _interests.length,
      itemBuilder: (context, index) {
        final interest = _interests[index];
        return _buildInterestCard(interest);
      },
    );
  }

  Widget _buildOffersTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_offers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No price offers yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Buyer offers will appear here',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _offers.length,
      itemBuilder: (context, index) {
        final offer = _offers[index];
        return _buildOfferCard(offer);
      },
    );
  }

  Widget _buildInterestCard(BuyerInterest interest) {
    final buyerDetails = _buyerDetails[interest.buyerId];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen,
                  child: Text(
                    interest.buyerName.isNotEmpty ? interest.buyerName[0].toUpperCase() : 'B',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              interest.buyerName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _viewBuyerProfile(interest.buyerId),
                            child: Icon(
                              Icons.info_outline,
                              color: AppTheme.primaryGreen,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      if (buyerDetails != null) ...[
                        Row(
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '${buyerDetails['rating'].toStringAsFixed(1)} (${buyerDetails['totalRatings']})',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getInterestStatusColor(interest.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    interest.status.toUpperCase(),
                    style: TextStyle(
                      color: _getInterestStatusColor(interest.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Interested in ${interest.interestedQuantity} ${widget.product.unit}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              interest.message,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Contact: ${interest.contactPreference}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Text(
              _formatDateTime(interest.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            if (interest.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _respondToInterest(interest, 'declined'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: BorderSide(color: AppTheme.error),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _respondToInterest(interest, 'accepted'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOfferCard(PriceOffer offer) {
    final buyerDetails = _buyerDetails[offer.buyerId];
    final totalValue = offer.offeredPrice * offer.quantity;
    final originalTotal = widget.product.price * offer.quantity;
    final discount = originalTotal - totalValue;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen,
                  child: Text(
                    offer.buyerName.isNotEmpty ? offer.buyerName[0].toUpperCase() : 'B',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              offer.buyerName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _viewBuyerProfile(offer.buyerId),
                            child: Icon(
                              Icons.info_outline,
                              color: AppTheme.primaryGreen,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      if (buyerDetails != null) ...[
                        Row(
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '${buyerDetails['rating'].toStringAsFixed(1)} (${buyerDetails['totalRatings']})',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getOfferStatusColor(offer.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    offer.status.toUpperCase(),
                    style: TextStyle(
                      color: _getOfferStatusColor(offer.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Offered Price:'),
                      Text(
                        '₹${offer.offeredPrice.toStringAsFixed(2)} per ${widget.product.unit}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quantity:'),
                      Text(
                        '${offer.quantity} ${widget.product.unit}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Offer:'),
                      Text(
                        '₹${totalValue.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  if (discount != 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('vs Your Price:'),
                        Text(
                          '₹${originalTotal.toStringAsFixed(2)} (${discount > 0 ? '-' : '+'}₹${discount.abs().toStringAsFixed(2)})',
                          style: TextStyle(
                            fontSize: 12,
                            color: discount > 0 ? AppTheme.error : AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (offer.message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Message:',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(offer.message),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Valid until: ',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  offer.validUntil != null 
                      ? _formatDateTime(offer.validUntil!)
                      : 'No expiry',
                  style: TextStyle(
                    fontSize: 12, 
                    color: offer.isExpired ? AppTheme.error : Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Offered: ${_formatDateTime(offer.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            if (offer.status == 'pending' && !offer.isExpired) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _respondToOffer(offer, 'rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: BorderSide(color: AppTheme.error),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _respondToOffer(offer, 'accepted'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getInterestStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.warning;
      case 'accepted':
      case 'contacted':
        return AppTheme.success;
      case 'declined':
        return AppTheme.error;
      default:
        return Colors.grey;
    }
  }

  Color _getOfferStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.warning;
      case 'accepted':
        return AppTheme.success;
      case 'rejected':
        return AppTheme.error;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
