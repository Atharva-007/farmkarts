import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/toast_helper.dart';
import '../models/product_model.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../models/order_model.dart' as OrderModelFile;
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';
import 'chat_conversation_page.dart';
import 'buyer_details_dialog.dart';
import 'cart_page.dart';
import 'main_app_layout.dart';
import '../services/apmc_api_service.dart';

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
      CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
    );
    
    _pageController = PageController();
    _animationController.forward();
    _loadMarketRates();
  }

  Future<void> _loadMarketRates() async {
    setState(() => _isLoadingMarketRates = true);
    try {
      final rates = await _apmcService.fetchMarketRates(
        commodity: widget.product.category,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.product.name),
        backgroundColor: AppTheme.getPrimaryAccent(context),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => ToastHelper.showInfo(context, 'Sharing...'),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageSection(),
                const SizedBox(height: 20),
                _buildProductInfoCard(),
                const SizedBox(height: 20),
                _buildMarketAnalysisCard(),
                const SizedBox(height: 20),
                _buildDescriptionCard(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final images = widget.product.imageUrls.isNotEmpty 
        ? widget.product.imageUrls 
        : ['https://via.placeholder.com/400x300?text=No+Image'];

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppTheme.getIconBackgroundColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentImageIndex = index),
              itemCount: images.length,
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error, size: 50),
                );
              },
            ),
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
                        color: _currentImageIndex == entry.key ? Colors.white : Colors.white.withOpacity(0.4),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInfoCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: isDark ? Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.1)) : null,
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
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
              ),
              if (widget.product.isOrganic)
                _buildTag('Organic', AppTheme.success, Icons.eco),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.product.category,
            style: TextStyle(color: AppTheme.getSecondaryTextColor(context), fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '₹${widget.product.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getPrimaryAccent(context),
                ),
              ),
              Text(
                ' / ${widget.product.unit}',
                style: TextStyle(color: AppTheme.getSecondaryTextColor(context), fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Quantity', '${widget.product.quantity} ${widget.product.unit}'),
          _buildInfoRow('Location', widget.product.location),
        ],
      ),
    );
  }

  Widget _buildMarketAnalysisCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: isDark ? Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.1)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_rounded, color: AppTheme.getPrimaryAccent(context), size: 24),
              const SizedBox(width: 12),
              Text(
                'APMC Market Analysis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingMarketRates)
            const Center(child: CircularProgressIndicator())
          else if (_relatedMarketRates.isEmpty)
            Text('No market data available for this category', style: TextStyle(color: AppTheme.getSecondaryTextColor(context)))
          else
            ..._relatedMarketRates.map((rate) => _buildMarketRateItem(rate)),
          
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context, 
                  MaterialPageRoute(builder: (context) => const MainAppLayout(initialIndex: 3)),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.trending_up),
              label: const Text('View Full Market Trends'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.getPrimaryAccent(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketRateItem(MarketRate rate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rate.market, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('${rate.district}, ${rate.state}', style: TextStyle(fontSize: 12, color: AppTheme.getSecondaryTextColor(context))),
              ],
            ),
          ),
          Text(
            '₹${rate.modalPrice.toStringAsFixed(0)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.getPrimaryAccent(context), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: isDark ? Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.1)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.product.description.isNotEmpty ? widget.product.description : 'No description available.',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppTheme.getTextColor(context).withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(color: AppTheme.getSecondaryTextColor(context), fontSize: 14)),
          Text(value, style: TextStyle(color: AppTheme.getTextColor(context), fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}
