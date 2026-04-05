// Enhanced Selling History Page
// Shows detailed selling analytics, buyer interests, and price offers

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../models/marketplace_models.dart';
import '../../services/enhanced_marketplace_service.dart';
import 'buyer_interests_page.dart';
import 'price_offers_page.dart';

class EnhancedSellingHistoryPage extends StatefulWidget {
  const EnhancedSellingHistoryPage({super.key});

  @override
  State<EnhancedSellingHistoryPage> createState() =>
      _EnhancedSellingHistoryPageState();
}

class _EnhancedSellingHistoryPageState extends State<EnhancedSellingHistoryPage>
    with TickerProviderStateMixin {
  final EnhancedMarketplaceService _marketplaceService =
      EnhancedMarketplaceService();

  late TabController _tabController;
  List<SellingHistoryItem> _sellingHistory = [];
  Map<String, dynamic>? _userStats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Load selling history and user statistics in parallel
      final results = await Future.wait([
        _marketplaceService.getSellingHistory(user.uid),
        _marketplaceService.getUserStatistics(user.uid),
      ]);

      if (mounted) {
        setState(() {
          _sellingHistory = results[0] as List<SellingHistoryItem>;
          _userStats = results[1] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Selling History',
          style: TextStyle(
            color: AppTheme.getAppBarTextColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.getAppBarColor(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.getAppBarTextColor(context)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.getAppBarTextColor(context),
          unselectedLabelColor:
              AppTheme.getAppBarTextColor(context).withValues(alpha: 0.6),
          indicatorColor: AppTheme.getAppBarTextColor(context),
          tabs: const [
            Tab(
              icon: Icon(Icons.inventory_2),
              text: 'My Products',
            ),
            Tab(
              icon: Icon(Icons.analytics),
              text: 'Analytics',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    if (_isLoading) {
      return Center(
          child: CircularProgressIndicator(
              color: AppTheme.getPrimaryAccent(context)));
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_sellingHistory.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.getPrimaryAccent(context),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sellingHistory.length,
        itemBuilder: (context, index) {
          return _buildSellingHistoryCard(_sellingHistory[index]);
        },
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    if (_isLoading) {
      return Center(
          child: CircularProgressIndicator(
              color: AppTheme.getPrimaryAccent(context)));
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_userStats == null) {
      return const Center(child: Text('No analytics data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCards(),
          const SizedBox(height: 24),
          _buildPerformanceMetrics(),
          const SizedBox(height: 24),
          _buildRevenueChart(),
        ],
      ),
    );
  }

  Widget _buildSellingHistoryCard(SellingHistoryItem item) {
    final statusColor = _getStatusColor(item.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isDark ? 0 : 2,
      color: AppTheme.getCardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: AppTheme.getBorderColor(context)
                .withValues(alpha: isDark ? 0.1 : 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _viewProductDetails(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: item.imageUrl.isNotEmpty
                        ? Image.network(
                            item.imageUrl,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildImagePlaceholder(),
                          )
                        : _buildImagePlaceholder(),
                  ),
                  const SizedBox(width: 16),

                  // Product Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.productName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.getTextColor(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item.status.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.category,
                          style: TextStyle(
                            color: AppTheme.getSecondaryTextColor(context),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '₹${item.currentPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getPrimaryAccent(context),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatDate(item.listedDate),
                              style: TextStyle(
                                color: AppTheme.getSecondaryTextColor(context)
                                    .withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Divider(color: AppTheme.getDividerColor(context)),
              const SizedBox(height: 12),

              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(Icons.visibility_outlined,
                      '${item.totalViews}', 'Views', Colors.blue),
                  _buildStatItem(Icons.chat_bubble_outline_rounded,
                      '${item.totalInquiries}', 'Inquiries', Colors.orange),
                  _buildStatItem(
                      Icons.analytics_outlined,
                      '₹${item.totalRevenue.toStringAsFixed(0)}',
                      'Revenue',
                      Colors.green),
                ],
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewInterests(item),
                      icon: const Icon(Icons.people_outline_rounded, size: 18),
                      label: const Text('Interests'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.getPrimaryAccent(context),
                        side: BorderSide(
                            color: AppTheme.getPrimaryAccent(context)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _viewOffers(item),
                      icon: const Icon(Icons.local_offer_outlined, size: 18),
                      label: const Text('Offers'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.getPrimaryAccent(context),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
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

  Widget _buildImagePlaceholder() {
    return Container(
      width: 64,
      height: 64,
      color: AppTheme.getSurfaceColor(context),
      child: Icon(Icons.image_outlined,
          color:
              AppTheme.getSecondaryTextColor(context).withValues(alpha: 0.5)),
    );
  }

  Widget _buildStatItem(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.getTextColor(context),
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.getSecondaryTextColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                title: 'Total Sales',
                value: _userStats!['totalSales'].toString(),
                icon: Icons.shopping_bag_outlined,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                title: 'Earnings',
                value: '₹${_userStats!['totalEarnings'].toStringAsFixed(0)}',
                icon: Icons.payments_outlined,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.getBorderColor(context)
                .withValues(alpha: isDark ? 0.1 : 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.getSecondaryTextColor(context),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem('Rating', '${_userStats!['averageRating']} ⭐'),
              _buildMetricItem('Active', '${_userStats!['activeListings']}'),
              _buildMetricItem('Conversion', '85%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getPrimaryAccent(context).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppTheme.getPrimaryAccent(context).withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded,
              size: 40,
              color: AppTheme.getPrimaryAccent(context).withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            'Monthly Trends',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context)),
          ),
          Text(
            'Visual analytics coming in next update',
            style: TextStyle(
                fontSize: 12, color: AppTheme.getSecondaryTextColor(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.getTextColor(context),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.getSecondaryTextColor(context),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 48, color: AppTheme.getErrorColor(context)),
          const SizedBox(height: 16),
          Text('Error loading history',
              style: TextStyle(
                  color: AppTheme.getTextColor(context),
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 80,
              color: AppTheme.getSecondaryTextColor(context)
                  .withValues(alpha: 0.2)),
          const SizedBox(height: 24),
          Text(
            'No selling history',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context)),
          ),
          const SizedBox(height: 8),
          Text('Your listed products will appear here',
              style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'sold_out':
        return Colors.orange;
      case 'paused':
        return Colors.grey;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _viewProductDetails(SellingHistoryItem item) {
    // Navigate to product detail
  }

  void _viewOffers(SellingHistoryItem item) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PriceOffersPage(productId: item.productId)));
  }

  void _viewInterests(SellingHistoryItem item) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                BuyerInterestsPage(productId: item.productId)));
  }
}
