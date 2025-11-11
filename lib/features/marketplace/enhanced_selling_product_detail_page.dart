// Enhanced Selling Product Detail Page
// Shows comprehensive product details, selling track record, buyer queries, and bidding information

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../models/marketplace_models.dart';
import '../../services/enhanced_marketplace_service.dart';
import '../../services/product_service.dart';
import '../../utils/responsive_helper.dart';
import 'add_product_page.dart';

class EnhancedSellingProductDetailPage extends StatefulWidget {
  final Product product;

  const EnhancedSellingProductDetailPage({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  State<EnhancedSellingProductDetailPage> createState() => _EnhancedSellingProductDetailPageState();
}

class _EnhancedSellingProductDetailPageState extends State<EnhancedSellingProductDetailPage>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  final EnhancedMarketplaceService _marketplaceService = EnhancedMarketplaceService();
  final ProductService _productService = ProductService();

  // Data variables
  SellingHistoryItem? _sellingHistory;
  List<BuyerInterest> _buyerInterests = [];
  List<PriceOffer> _priceOffers = [];
  List<MarketplaceTransaction> _transactions = [];
  Map<String, dynamic> _analytics = {};
  
  bool _isLoading = true;
  bool _isOwner = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkOwnership();
    _loadProductData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkOwnership() {
    final user = FirebaseAuth.instance.currentUser;
    _isOwner = user?.uid == widget.product.sellerId;
  }

  Future<void> _loadProductData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Load all data in parallel
      final futures = [
        _loadSellingHistory(),
        _loadBuyerInterests(),
        _loadPriceOffers(),
        _loadTransactions(),
        _loadAnalytics(),
      ];

      await Future.wait(futures);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSellingHistory() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final query = await firestore
          .collection('selling_history')
          .where('productId', isEqualTo: widget.product.id)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        _sellingHistory = SellingHistoryItem.fromMap(query.docs.first.data());
      }
    } catch (e) {
      print('Error loading selling history: $e');
    }
  }

  Future<void> _loadBuyerInterests() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final query = await firestore
          .collection('buyer_interests')
          .where('productId', isEqualTo: widget.product.id)
          .orderBy('createdAt', descending: true)
          .get();

      _buyerInterests = query.docs
          .map((doc) => BuyerInterest.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error loading buyer interests: $e');
    }
  }

  Future<void> _loadPriceOffers() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final query = await firestore
          .collection('price_offers')
          .where('productId', isEqualTo: widget.product.id)
          .orderBy('createdAt', descending: true)
          .get();

      _priceOffers = query.docs
          .map((doc) => PriceOffer.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error loading price offers: $e');
    }
  }

  Future<void> _loadTransactions() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final query = await firestore
          .collection('marketplace_transactions')
          .where('productId', isEqualTo: widget.product.id)
          .orderBy('createdAt', descending: true)
          .get();

      _transactions = query.docs
          .map((doc) => MarketplaceTransaction.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error loading transactions: $e');
    }
  }

  Future<void> _loadAnalytics() async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Get product views
      final viewsQuery = await firestore
          .collection('product_views')
          .where('productId', isEqualTo: widget.product.id)
          .get();

      // Calculate analytics
      _analytics = {
        'totalViews': viewsQuery.docs.length,
        'totalInterests': _buyerInterests.length,
        'totalOffers': _priceOffers.length,
        'pendingOffers': _priceOffers.where((offer) => offer.status == 'pending').length,
        'acceptedOffers': _priceOffers.where((offer) => offer.status == 'accepted').length,
        'totalTransactions': _transactions.length,
        'totalRevenue': _transactions.fold(0.0, (sum, transaction) => sum + transaction.totalAmount),
        'averageOfferPrice': _priceOffers.isNotEmpty 
            ? _priceOffers.map((offer) => offer.offeredPrice).reduce((a, b) => a + b) / _priceOffers.length
            : 0.0,
      };
    } catch (e) {
      print('Error loading analytics: $e');
      _analytics = {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          widget.product.name,
          style: const TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        actions: [
          if (_isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editProduct,
            ),
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'pause',
                  child: Text('Pause Listing'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete Product'),
                ),
                const PopupMenuItem(
                  value: 'promote',
                  child: Text('Promote Product'),
                ),
              ],
            ),
          ],
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareProduct,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textGrey,
          indicatorColor: AppTheme.primaryGreen,
          tabs: const [
            Tab(
              icon: Icon(Icons.info_outline),
              text: 'Details',
            ),
            Tab(
              icon: Icon(Icons.analytics),
              text: 'Analytics',
            ),
            Tab(
              icon: Icon(Icons.people),
              text: 'Interests',
            ),
            Tab(
              icon: Icon(Icons.local_offer),
              text: 'Offers',
            ),
          ],
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDetailsTab(),
                    _buildAnalyticsTab(),
                    _buildInterestsTab(),
                    _buildOffersTab(),
                  ],
                ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductHeader(),
          const SizedBox(height: 20),
          _buildProductImages(),
          const SizedBox(height: 20),
          _buildProductInfo(),
          const SizedBox(height: 20),
          _buildSellerInfo(),
          const SizedBox(height: 20),
          if (_isOwner) _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalyticsOverview(),
          const SizedBox(height: 20),
          _buildPerformanceMetrics(),
          const SizedBox(height: 20),
          _buildRevenueChart(),
          const SizedBox(height: 20),
          _buildInteractionHistory(),
        ],
      ),
    );
  }

  Widget _buildInterestsTab() {
    return _buyerInterests.isEmpty
        ? _buildEmptyState('No buyer interests yet', Icons.people_outline)
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _buyerInterests.length,
            itemBuilder: (context, index) {
              return _buildInterestCard(_buyerInterests[index]);
            },
          );
  }

  Widget _buildOffersTab() {
    return _priceOffers.isEmpty
        ? _buildEmptyState('No price offers yet', Icons.local_offer_outlined)
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _priceOffers.length,
            itemBuilder: (context, index) {
              return _buildOfferCard(_priceOffers[index]);
            },
          );
  }

  Widget _buildProductHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      const SizedBox(height: 8),
                      Text(
                        widget.product.category,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.product.isAvailable 
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.product.isAvailable ? 'Available' : 'Sold Out',
                    style: TextStyle(
                      color: widget.product.isAvailable ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '₹${widget.product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                Text(
                  '/${widget.product.unit}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textGrey,
                  ),
                ),
                const Spacer(),
                if (widget.product.quantity > 0) ...[
                  const Icon(Icons.inventory, size: 16, color: AppTheme.textGrey),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.product.quantity} ${widget.product.unit}',
                    style: const TextStyle(color: AppTheme.textGrey),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImages() {
    return SizedBox(
      height: 250,
      child: widget.product.imageUrls.isEmpty
          ? Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.image,
                  size: 64,
                  color: AppTheme.textGrey,
                ),
              ),
            )
          : PageView.builder(
              itemCount: widget.product.imageUrls.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.product.imageUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppTheme.backgroundLight,
                        child: const Center(
                          child: Icon(Icons.error, color: AppTheme.textGrey),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProductInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              style: const TextStyle(fontSize: 16),
            ),
            if (widget.product.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Tags',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: widget.product.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(color: AppTheme.primaryGreen),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSellerInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 12),
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 12),
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
                      Text(
                        widget.product.location,
                        style: const TextStyle(color: AppTheme.textGrey),
                      ),
                    ],
                  ),
                ),
                if (!_isOwner)
                  ElevatedButton(
                    onPressed: _contactSeller,
                    child: const Text('Contact'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsOverview() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: ResponsiveHelper.isMobile(context) ? 2 : 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: [
                _buildAnalyticsCard('Views', _analytics['totalViews']?.toString() ?? '0', Icons.visibility),
                _buildAnalyticsCard('Interests', _analytics['totalInterests']?.toString() ?? '0', Icons.favorite),
                _buildAnalyticsCard('Offers', _analytics['totalOffers']?.toString() ?? '0', Icons.local_offer),
                _buildAnalyticsCard('Revenue', '₹${(_analytics['totalRevenue'] ?? 0).toStringAsFixed(0)}', Icons.monetization_on),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: AppTheme.primaryGreen),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    final daysListed = DateTime.now().difference(widget.product.timestamp).inDays;
    final conversionRate = _analytics['totalViews'] > 0 
        ? (_analytics['totalInterests'] / _analytics['totalViews'] * 100)
        : 0.0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem('Days Listed', daysListed.toString()),
                _buildMetricItem('Conversion Rate', '${conversionRate.toStringAsFixed(1)}%'),
                _buildMetricItem('Avg Offer Price', '₹${(_analytics['averageOfferPrice'] ?? 0).toStringAsFixed(0)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueChart() {
    // Placeholder for revenue chart
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Trend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Revenue Chart\n(Coming Soon)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textGrey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionHistory() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_transactions.isEmpty && _buyerInterests.isEmpty && _priceOffers.isEmpty)
              const Center(
                child: Text(
                  'No recent activity',
                  style: TextStyle(color: AppTheme.textGrey),
                ),
              )
            else
              ..._buildRecentActivityItems(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRecentActivityItems() {
    final activities = <Widget>[];
    
    // Add recent interests
    for (final interest in _buyerInterests.take(3)) {
      activities.add(ListTile(
        leading: const Icon(Icons.person, color: AppTheme.primaryGreen),
        title: Text('${interest.buyerName} showed interest'),
        subtitle: Text(interest.message),
        trailing: Text(_formatDate(interest.createdAt)),
      ));
    }
    
    // Add recent offers
    for (final offer in _priceOffers.take(3)) {
      activities.add(ListTile(
        leading: const Icon(Icons.local_offer, color: AppTheme.warning),
        title: Text('${offer.buyerName} made an offer'),
        subtitle: Text('₹${offer.offeredPrice}/unit for ${offer.quantity} units'),
        trailing: Text(_formatDate(offer.createdAt)),
      ));
    }
    
    return activities;
  }

  Widget _buildInterestCard(BuyerInterest interest) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(interest.buyerName[0].toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        interest.buyerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        interest.buyerEmail,
                        style: const TextStyle(color: AppTheme.textGrey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(interest.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    interest.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(interest.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              interest.message,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Quantity: ${interest.interestedQuantity} ${widget.product.unit}',
                  style: const TextStyle(color: AppTheme.textGrey),
                ),
                const Spacer(),
                Text(
                  _formatDate(interest.createdAt),
                  style: const TextStyle(color: AppTheme.textGrey),
                ),
              ],
            ),
            if (_isOwner && interest.status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _respondToInterest(interest, 'declined'),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _respondToInterest(interest, 'contacted'),
                      child: const Text('Contact'),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(offer.buyerName[0].toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.buyerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        offer.buyerEmail,
                        style: const TextStyle(color: AppTheme.textGrey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(offer.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    offer.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(offer.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Offered: ₹${offer.offeredPrice.toStringAsFixed(2)}/${widget.product.unit}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const Spacer(),
                Text(
                  'Qty: ${offer.quantity}',
                  style: const TextStyle(color: AppTheme.textGrey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Total: ₹${offer.totalValue.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (offer.message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(offer.message),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (offer.validUntil != null) ...[
                  Icon(
                    offer.isExpired ? Icons.schedule : Icons.schedule,
                    size: 16,
                    color: offer.isExpired ? Colors.red : AppTheme.textGrey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    offer.isExpired 
                        ? 'Expired'
                        : 'Valid until ${_formatDate(offer.validUntil!)}',
                    style: TextStyle(
                      color: offer.isExpired ? Colors.red : AppTheme.textGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  _formatDate(offer.createdAt),
                  style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
                ),
              ],
            ),
            if (_isOwner && offer.status == 'pending' && !offer.isExpired) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _respondToOffer(offer, 'rejected'),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _respondToOffer(offer, 'accepted'),
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

  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _updatePrice,
                  icon: const Icon(Icons.price_change),
                  label: const Text('Update Price'),
                ),
                ElevatedButton.icon(
                  onPressed: _updateQuantity,
                  icon: const Icon(Icons.inventory),
                  label: const Text('Update Stock'),
                ),
                ElevatedButton.icon(
                  onPressed: _promoteProduct,
                  icon: const Icon(Icons.trending_up),
                  label: const Text('Promote'),
                ),
                ElevatedButton.icon(
                  onPressed: _pauseProduct,
                  icon: const Icon(Icons.pause),
                  label: const Text('Pause'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppTheme.textGrey),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                color: AppTheme.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              'Error loading product details',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textGrey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProductData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'contacted':
        return Colors.green;
      case 'rejected':
      case 'declined':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return AppTheme.textGrey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _editProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductPage(),
      ),
    ).then((value) {
      if (value == true) {
        _loadProductData();
      }
    });
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'pause':
        _pauseProduct();
        break;
      case 'delete':
        _deleteProduct();
        break;
      case 'promote':
        _promoteProduct();
        break;
    }
  }

  void _shareProduct() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  void _contactSeller() {
    // Navigate to chat or contact page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact seller functionality coming soon')),
    );
  }

  void _updatePrice() {
    // Show price update dialog
    _showUpdateDialog('Update Price', 'Enter new price', (value) async {
      try {
        await _productService.updateProduct(widget.product.id, {'price': double.parse(value)});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Price updated successfully')),
        );
        _loadProductData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating price: $e')),
        );
      }
    });
  }

  void _updateQuantity() {
    // Show quantity update dialog
    _showUpdateDialog('Update Stock', 'Enter new quantity', (value) async {
      try {
        await _productService.updateProduct(widget.product.id, {'quantity': int.parse(value)});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock updated successfully')),
        );
        _loadProductData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating stock: $e')),
        );
      }
    });
  }

  void _showUpdateDialog(String title, String hint, Function(String) onSubmit) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                onSubmit(controller.text);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _promoteProduct() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product promotion feature coming soon')),
    );
  }

  void _pauseProduct() async {
    try {
      await _productService.updateProduct(widget.product.id, {'isAvailable': false});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product paused successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error pausing product: $e')),
      );
    }
  }

  void _deleteProduct() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                Navigator.pop(context);
                await _productService.deleteProduct(widget.product.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product deleted successfully')),
                );
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting product: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _respondToInterest(BuyerInterest interest, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('buyer_interests')
          .doc(interest.id)
          .update({'status': status});
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Interest $status successfully')),
      );
      _loadProductData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating interest: $e')),
      );
    }
  }

  Future<void> _respondToOffer(PriceOffer offer, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('price_offers')
          .doc(offer.id)
          .update({
            'status': status,
            'respondedAt': FieldValue.serverTimestamp(),
          });
      
      if (status == 'accepted') {
        // Create transaction record
        await FirebaseFirestore.instance
            .collection('marketplace_transactions')
            .add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'productId': widget.product.id,
          'sellerId': widget.product.sellerId,
          'buyerId': offer.buyerId,
          'offerId': offer.id,
          'quantity': offer.quantity,
          'pricePerUnit': offer.offeredPrice,
          'totalAmount': offer.totalValue,
          'status': 'confirmed',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Offer $status successfully')),
      );
      _loadProductData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating offer: $e')),
      );
    }
  }
}
