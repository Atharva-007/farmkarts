import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/app_constants.dart';

class APMCMarketPage extends StatefulWidget {
  const APMCMarketPage({super.key});

  @override
  State<APMCMarketPage> createState() => _APMCMarketPageState();
}

class _APMCMarketPageState extends State<APMCMarketPage> {
  String _selectedLocation = 'All Locations';
  String _selectedCategory = 'All Products';
  
  final List<String> _locations = [
    'All Locations',
    'Mumbai - Vashi APMC',
    'Delhi - Azadpur Mandi',
    'Pune - Market Yard',
    'Bangalore - KR Market',
    'Chennai - Koyambedu',
    'Kolkata - Sealdah',
    'Hyderabad - Gaddiannaram',
  ];

  final List<String> _categories = [
    'All Products',
    'Vegetables',
    'Fruits',
    'Grains',
    'Pulses',
    'Spices',
    'Oil Seeds',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundLight,
      child: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshRates,
              color: AppTheme.primaryGreen,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildSummaryCards(),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = _getFilteredProducts()[index];
                          return _buildProductCard(product);
                        },
                        childCount: _getFilteredProducts().length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Location',
                  _selectedLocation,
                  _locations,
                  (value) => setState(() => _selectedLocation = value!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  'Category',
                  _selectedCategory,
                  _categories,
                  (value) => setState(() => _selectedCategory = value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppTheme.textGrey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rates updated every 30 minutes from APMC markets',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderGrey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSummaryCards() {
    final products = _getFilteredProducts();
    final highestPrice = products.isNotEmpty 
        ? products.reduce((a, b) => a.maxPrice > b.maxPrice ? a : b)
        : null;
    final lowestPrice = products.isNotEmpty 
        ? products.reduce((a, b) => a.minPrice < b.minPrice ? a : b)
        : null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Market Summary',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Highest Rate',
                  highestPrice?.name ?? 'N/A',
                  '₹${highestPrice?.maxPrice.toStringAsFixed(2) ?? '0'}/kg',
                  AppTheme.success,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Lowest Rate',
                  lowestPrice?.name ?? 'N/A',
                  '₹${lowestPrice?.minPrice.toStringAsFixed(2) ?? '0'}/kg',
                  AppTheme.error,
                  Icons.trending_down,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String product,
    String price,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              product,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(MarketProduct product) {
    final priceChange = product.maxPrice - product.minPrice;
    final changeColor = priceChange >= 0 ? AppTheme.success : AppTheme.error;
    final changeIcon = priceChange >= 0 ? Icons.arrow_upward : Icons.arrow_downward;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    _getProductIcon(product.category),
                    color: AppTheme.primaryGreen,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppTheme.textGrey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              product.location,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textGrey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.category,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Price Change Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: changeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        changeIcon,
                        size: 14,
                        color: changeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '₹${priceChange.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: changeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Price Range
            Row(
              children: [
                Expanded(
                  child: _buildPriceInfo(
                    'Min Price',
                    '₹${product.minPrice.toStringAsFixed(2)}',
                    AppTheme.error,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppTheme.borderGrey,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Expanded(
                  child: _buildPriceInfo(
                    'Max Price',
                    '₹${product.maxPrice.toStringAsFixed(2)}',
                    AppTheme.success,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppTheme.borderGrey,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Expanded(
                  child: _buildPriceInfo(
                    'Quantity',
                    '${product.quantity} tons',
                    AppTheme.info,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Last Updated
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: AppTheme.textGrey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Updated: ${product.lastUpdated}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textGrey,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showProductDetails(product),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('Details'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  IconData _getProductIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables':
        return Icons.eco;
      case 'fruits':
        return Icons.apple;
      case 'grains':
        return Icons.grain;
      case 'pulses':
        return Icons.circle;
      case 'spices':
        return Icons.local_florist;
      case 'oil seeds':
        return Icons.opacity;
      default:
        return Icons.agriculture;
    }
  }

  List<MarketProduct> _getFilteredProducts() {
    return _sampleProducts.where((product) {
      final locationMatch = _selectedLocation == 'All Locations' || 
                           product.location.contains(_selectedLocation.split(' - ')[0]);
      final categoryMatch = _selectedCategory == 'All Products' || 
                           product.category == _selectedCategory;
      return locationMatch && categoryMatch;
    }).toList();
  }

  Future<void> _refreshRates() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Market rates refreshed!'),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showProductDetails(MarketProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildProductDetailsSheet(product),
    );
  }

  Widget _buildProductDetailsSheet(MarketProduct product) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getProductIcon(product.category),
                color: AppTheme.primaryGreen,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      product.location,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDetailRow('Category', product.category),
          _buildDetailRow('Quality', product.quality),
          _buildDetailRow('Variety', product.variety),
          _buildDetailRow('Min Price', '₹${product.minPrice.toStringAsFixed(2)}/kg'),
          _buildDetailRow('Max Price', '₹${product.maxPrice.toStringAsFixed(2)}/kg'),
          _buildDetailRow('Available Quantity', '${product.quantity} tons'),
          _buildDetailRow('Last Updated', product.lastUpdated),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sample data - In real app, this would come from an API
  final List<MarketProduct> _sampleProducts = [
    MarketProduct(
      name: 'Tomato',
      category: 'Vegetables',
      location: 'Mumbai - Vashi APMC',
      minPrice: 15.50,
      maxPrice: 28.00,
      quantity: 125.5,
      quality: 'Grade A',
      variety: 'Hybrid',
      lastUpdated: '2 hours ago',
    ),
    MarketProduct(
      name: 'Onion',
      category: 'Vegetables',
      location: 'Delhi - Azadpur Mandi',
      minPrice: 18.00,
      maxPrice: 35.00,
      quantity: 200.0,
      quality: 'Grade A',
      variety: 'Red',
      lastUpdated: '1 hour ago',
    ),
    MarketProduct(
      name: 'Apple',
      category: 'Fruits',
      location: 'Pune - Market Yard',
      minPrice: 80.00,
      maxPrice: 120.00,
      quantity: 75.2,
      quality: 'Premium',
      variety: 'Kashmir',
      lastUpdated: '30 minutes ago',
    ),
    MarketProduct(
      name: 'Rice',
      category: 'Grains',
      location: 'Hyderabad - Gaddiannaram',
      minPrice: 45.00,
      maxPrice: 65.00,
      quantity: 300.0,
      quality: 'Grade A',
      variety: 'Basmati',
      lastUpdated: '3 hours ago',
    ),
    MarketProduct(
      name: 'Wheat',
      category: 'Grains',
      location: 'Delhi - Azadpur Mandi',
      minPrice: 22.00,
      maxPrice: 28.50,
      quantity: 450.0,
      quality: 'Grade A',
      variety: 'Durum',
      lastUpdated: '1 hour ago',
    ),
    MarketProduct(
      name: 'Potato',
      category: 'Vegetables',
      location: 'Kolkata - Sealdah',
      minPrice: 12.00,
      maxPrice: 18.00,
      quantity: 180.0,
      quality: 'Grade B',
      variety: 'Red',
      lastUpdated: '45 minutes ago',
    ),
  ];
}

class MarketProduct {
  final String name;
  final String category;
  final String location;
  final double minPrice;
  final double maxPrice;
  final double quantity;
  final String quality;
  final String variety;
  final String lastUpdated;

  MarketProduct({
    required this.name,
    required this.category,
    required this.location,
    required this.minPrice,
    required this.maxPrice,
    required this.quantity,
    required this.quality,
    required this.variety,
    required this.lastUpdated,
  });
}