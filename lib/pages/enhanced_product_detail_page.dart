import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/toast_helper.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';
import 'main_app_layout.dart';
import '../services/apmc_api_service.dart';
import '../widgets/universal_header.dart';

class EnhancedProductDetailPage extends StatefulWidget {
  final Product product;

  const EnhancedProductDetailPage({
    super.key,
    required this.product,
  });

  @override
  State<EnhancedProductDetailPage> createState() =>
      _EnhancedProductDetailPageState();
}

class _EnhancedProductDetailPageState extends State<EnhancedProductDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final APMCApiService _apmcService = APMCApiService();

  int _currentImageIndex = 0;
  late PageController _pageController;
  List<MarketRate> _relatedMarketRates = [];
  bool _isLoadingMarketRates = true;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
    );

    _pageController = PageController();
    _animationController.forward();
    _loadMarketRates();
  }

  Future<void> _loadMarketRates() async {
    setState(() => _isLoadingMarketRates = true);
    try {
      final rates = await _apmcService.fetchMarketRates(
        category: widget.product.category,
      );
      if (mounted) {
        setState(() {
          _relatedMarketRates = rates.take(3).toList();
          _isLoadingMarketRates = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMarketRates = false);
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
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            UniversalHeader(
              title: widget.product.name,
              subtitle:
                  '${widget.product.category} • ${widget.product.location}',
              icon: Icons.inventory_2_rounded,
              showBackButton: true,
              showProfile: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  onPressed: () => ToastHelper.showInfo(
                      context, 'Sharing product details...'),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImageSection(),
                      const SizedBox(height: 24),
                      _buildProductInfoCard(),
                      const SizedBox(height: 20),
                      _buildMarketAnalysisCard(),
                      const SizedBox(height: 20),
                      _buildDescriptionCard(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionBottomBar(),
    );
  }

  Widget _buildImageSection() {
    final images =
        widget.product.imageUrls.isNotEmpty ? widget.product.imageUrls : [];

    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.getPremiumShadow(context),
        border: Border.all(
            color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            if (images.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported_rounded,
                        size: 64,
                        color: AppTheme.getPrimaryAccent(context)
                            .withValues(alpha: 0.2)),
                    const SizedBox(height: 12),
                    Text('No images available',
                        style: TextStyle(
                            color: AppTheme.getSecondaryTextColor(context),
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            else
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) =>
                    setState(() => _currentImageIndex = index),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return CachedNetworkImage(
                    imageUrl: images[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error, size: 50),
                  );
                },
              ),
            if (images.length > 1)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: images.asMap().entries.map((entry) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _currentImageIndex == entry.key ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _currentImageIndex == entry.key
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                    );
                  }).toList(),
                ),
              ),
            // Badges
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.product.category.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.getPremiumShadow(context),
        border: Border.all(
            color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.product.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
              ),
              if (widget.product.isOrganic)
                _buildTag('Organic', Colors.green, Icons.eco_rounded),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹${widget.product.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.getPrimaryAccent(context),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                ' / ${widget.product.unit}',
                style: TextStyle(
                  color: AppTheme.getSecondaryTextColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 40),
          _buildDetailRow(Icons.inventory_2_rounded, 'Stock Available',
              '${widget.product.quantity} ${widget.product.unit}'),
          const SizedBox(height: 12),
          _buildDetailRow(
              Icons.location_on_rounded, 'Location', widget.product.location),
          const SizedBox(height: 12),
          _buildDetailRow(
              Icons.person_rounded, 'Seller', widget.product.sellerName),
        ],
      ),
    );
  }

  Widget _buildMarketAnalysisCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.getPremiumShadow(context),
        border:
            Border.all(color: Colors.blue.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.analytics_rounded,
                    color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Market Price Analysis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoadingMarketRates)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ))
          else if (_relatedMarketRates.isEmpty)
            _buildEmptyMarketState()
          else
            ..._relatedMarketRates.map((rate) => _buildMarketRateItem(rate)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const MainAppLayout(initialIndex: 3)),
                );
              },
              icon: const Icon(Icons.trending_up_rounded, size: 18),
              label: const Text('EXPLORE FULL MARKET TRENDS',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.5)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMarketState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getLayerColor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'No recent APMC data found for this category. Prices may vary based on local demand.',
        style: TextStyle(
            color: AppTheme.getSecondaryTextColor(context),
            fontSize: 13,
            height: 1.4),
      ),
    );
  }

  Widget _buildMarketRateItem(MarketRate rate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getLayerColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.getBorderColor(context).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rate.market,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text('${rate.district}, ${rate.state}',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.getSecondaryTextColor(context),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${rate.modalPrice.toInt()}',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.getPrimaryAccent(context),
                    fontSize: 18),
              ),
              const Text('Mandi Rate',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.getPremiumShadow(context),
        border: Border.all(
            color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Description',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            widget.product.description.isNotEmpty
                ? widget.product.description
                : 'The seller hasn\'t provided a detailed description for this produce.',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppTheme.getTextColor(context).withValues(alpha: 0.8),
              fontStyle: widget.product.description.isEmpty
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.getLayerColor(context),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              Icon(icon, color: AppTheme.getPrimaryAccent(context), size: 18),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: AppTheme.getSecondaryTextColor(context),
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
            Text(value,
                style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -10)),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.chat_bubble_rounded),
                label: const Text('CONTACT SELLER',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: AppTheme.getPrimaryAccent(context), width: 2),
                  foregroundColor: AppTheme.getPrimaryAccent(context),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.shopping_cart_checkout_rounded),
                label: const Text('ADD TO CART',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 0.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.getPrimaryAccent(context),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor:
                      AppTheme.getPrimaryAccent(context).withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
