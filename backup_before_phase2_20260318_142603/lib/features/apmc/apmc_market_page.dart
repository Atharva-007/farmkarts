import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/app_constants.dart';

class APMCMarketPage extends StatefulWidget {
  const APMCMarketPage({super.key});

  @override
  State<APMCMarketPage> createState() => _APMCMarketPageState();
}

class _APMCMarketPageState extends State<APMCMarketPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Timer _refreshTimer;
  
  String _selectedLocation = 'All Locations';
  String _selectedCategory = 'All Products';
  String _sortBy = 'Price High to Low';
  bool _isLoading = false;
  
  final List<String> _locations = [
    'All Locations',
    'Mumbai - Vashi APMC',
    'Delhi - Azadpur Mandi',
    'Pune - Market Yard',
    'Bangalore - KR Market',
    'Chennai - Koyambedu',
    'Kolkata - Sealdah',
    'Hyderabad - Gaddiannaram',
    'Nashik - Agricultural Market',
    'Indore - Krishi Upaj Mandi',
  ];

  final List<String> _categories = [
    'All Products',
    'Vegetables',
    'Fruits',
    'Grains',
    'Pulses',
    'Spices',
    'Oil Seeds',
    'Dairy Products',
  ];

  final List<String> _sortOptions = [
    'Price High to Low',
    'Price Low to High',
    'Latest Update',
    'Name A-Z',
    'Highest Volume',
  ];

  List<MarketRate> _marketRates = [];
  List<MarketRate> _filteredRates = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _generateMockData();
    _startRealTimeUpdates();
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _refreshTimer.cancel();
    super.dispose();
  }

  void _generateMockData() {
    final random = Random();
    final products = [
      'Tomato', 'Onion', 'Potato', 'Rice', 'Wheat', 'Sugar', 'Turmeric',
      'Chili', 'Garlic', 'Ginger', 'Apple', 'Banana', 'Orange', 'Mango',
      'Grapes', 'Soybean', 'Cotton', 'Groundnut', 'Mustard', 'Bajra'
    ];
    
    _marketRates = products.map((product) {
      final basePrice = random.nextDouble() * 100 + 20;
      final change = (random.nextDouble() - 0.5) * 10;
      return MarketRate(
        id: product.toLowerCase().replaceAll(' ', '_'),
        productName: product,
        category: _getCategoryForProduct(product),
        currentPrice: basePrice,
        previousPrice: basePrice - change,
        quantity: random.nextInt(10000) + 1000,
        unit: _getUnitForProduct(product),
        location: _locations[random.nextInt(_locations.length - 1) + 1],
        lastUpdated: DateTime.now().subtract(Duration(minutes: random.nextInt(60))),
        volume: random.nextInt(50000) + 5000,
        trend: change > 0 ? PriceTrend.up : change < 0 ? PriceTrend.down : PriceTrend.stable,
        qualityGrade: _getRandomGrade(),
      );
    }).toList();
    
    _filterAndSortRates();
  }

  String _getCategoryForProduct(String product) {
    if (['Tomato', 'Onion', 'Potato', 'Garlic', 'Ginger'].contains(product)) {
      return 'Vegetables';
    } else if (['Apple', 'Banana', 'Orange', 'Mango', 'Grapes'].contains(product)) {
      return 'Fruits';
    } else if (['Rice', 'Wheat', 'Bajra'].contains(product)) {
      return 'Grains';
    } else if (['Turmeric', 'Chili'].contains(product)) {
      return 'Spices';
    } else if (['Soybean', 'Groundnut', 'Mustard'].contains(product)) {
      return 'Oil Seeds';
    }
    return 'Others';
  }

  String _getUnitForProduct(String product) {
    if (['Rice', 'Wheat', 'Sugar'].contains(product)) {
      return 'Quintal';
    } else if (['Cotton', 'Soybean'].contains(product)) {
      return 'Quintal';
    }
    return 'Kg';
  }

  String _getRandomGrade() {
    final grades = ['A', 'B', 'C'];
    return grades[Random().nextInt(grades.length)];
  }

  void _startRealTimeUpdates() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _updatePrices();
      }
    });
  }

  void _updatePrices() {
    final random = Random();
    for (var rate in _marketRates) {
      final change = (random.nextDouble() - 0.5) * 2;
      rate.previousPrice = rate.currentPrice;
      rate.currentPrice = (rate.currentPrice + change).clamp(1.0, 1000.0);
      rate.lastUpdated = DateTime.now();
      rate.trend = change > 0.1 ? PriceTrend.up 
          : change < -0.1 ? PriceTrend.down 
          : PriceTrend.stable;
    }
    
    if (mounted) {
      setState(() {
        _filterAndSortRates();
      });
    }
  }

  void _filterAndSortRates() {
    _filteredRates = _marketRates.where((rate) {
      final locationMatch = _selectedLocation == 'All Locations' || 
          rate.location == _selectedLocation;
      final categoryMatch = _selectedCategory == 'All Products' || 
          rate.category == _selectedCategory;
      return locationMatch && categoryMatch;
    }).toList();
    
    // Sort rates
    switch (_sortBy) {
      case 'Price High to Low':
        _filteredRates.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
        break;
      case 'Price Low to High':
        _filteredRates.sort((a, b) => a.currentPrice.compareTo(b.currentPrice));
        break;
      case 'Latest Update':
        _filteredRates.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
        break;
      case 'Name A-Z':
        _filteredRates.sort((a, b) => a.productName.compareTo(b.productName));
        break;
      case 'Highest Volume':
        _filteredRates.sort((a, b) => b.volume.compareTo(a.volume));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          _buildMarketOverview(),
          Expanded(child: _buildMarketRates()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: ResponsiveHelper.getScreenPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'APMC Market',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Live Commodity Prices',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.defaultShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  'Location',
                  _selectedLocation,
                  _locations,
                  (value) => setState(() {
                    _selectedLocation = value!;
                    _filterAndSortRates();
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  'Category',
                  _selectedCategory,
                  _categories,
                  (value) => setState(() {
                    _selectedCategory = value!;
                    _filterAndSortRates();
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDropdown(
            'Sort By',
            _sortBy,
            _sortOptions,
            (value) => setState(() {
              _sortBy = value!;
              _filterAndSortRates();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: AppTheme.textGrey,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((item) {
                return DropdownMenuItem<String>(
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
          ),
        ),
      ],
    );
  }

  Widget _buildMarketOverview() {
    final totalRates = _filteredRates.length;
    final avgPrice = _filteredRates.isEmpty 
        ? 0.0 
        : _filteredRates.map((r) => r.currentPrice).reduce((a, b) => a + b) / totalRates;
    final upTrend = _filteredRates.where((r) => r.trend == PriceTrend.up).length;
    final downTrend = _filteredRates.where((r) => r.trend == PriceTrend.down).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.defaultShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildOverviewCard(
              'Total Products',
              totalRates.toString(),
              Icons.inventory,
              AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildOverviewCard(
              'Average Price',
              '₹${avgPrice.toStringAsFixed(0)}',
              Icons.currency_rupee,
              AppTheme.skyBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildOverviewCard(
              'Price Rising',
              upTrend.toString(),
              Icons.trending_up,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildOverviewCard(
              'Price Falling',
              downTrend.toString(),
              Icons.trending_down,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMarketRates() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.defaultShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.list_alt, color: Colors.white, size: 20),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'Market Rates',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _updatePrices(),
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredRates.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppTheme.textGrey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No products found for selected filters',
                          style: TextStyle(color: AppTheme.textGrey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredRates.length,
                    itemBuilder: (context, index) {
                      final rate = _filteredRates[index];
                      return _buildRateCard(rate);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateCard(MarketRate rate) {
    final priceChange = rate.currentPrice - rate.previousPrice;
    final percentageChange = (priceChange / rate.previousPrice) * 100;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showProductDetails(rate),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getProductIcon(rate.productName),
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rate.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${rate.location} • Grade ${rate.qualityGrade}',
                          style: const TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${rate.currentPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      Text(
                        'per ${rate.unit}',
                        style: const TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTrendColor(rate.trend).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getTrendIcon(rate.trend),
                          color: _getTrendColor(rate.trend),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${percentageChange >= 0 ? '+' : ''}${percentageChange.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: _getTrendColor(rate.trend),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Qty: ${rate.quantity} ${rate.unit}',
                    style: const TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Vol: ${(rate.volume / 1000).toStringAsFixed(1)}K',
                    style: const TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatTime(rate.lastUpdated),
                    style: const TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 12,
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

  IconData _getProductIcon(String productName) {
    switch (productName.toLowerCase()) {
      case 'tomato':
      case 'onion':
      case 'potato':
        return Icons.eco;
      case 'apple':
      case 'banana':
      case 'orange':
        return Icons.local_florist;
      case 'rice':
      case 'wheat':
        return Icons.grain;
      default:
        return Icons.agriculture;
    }
  }

  Color _getTrendColor(PriceTrend trend) {
    switch (trend) {
      case PriceTrend.up:
        return Colors.green;
      case PriceTrend.down:
        return Colors.red;
      case PriceTrend.stable:
        return Colors.orange;
    }
  }

  IconData _getTrendIcon(PriceTrend trend) {
    switch (trend) {
      case PriceTrend.up:
        return Icons.trending_up;
      case PriceTrend.down:
        return Icons.trending_down;
      case PriceTrend.stable:
        return Icons.trending_flat;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showProductDetails(MarketRate rate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProductDetailsSheet(rate),
    );
  }

  Widget _buildProductDetailsSheet(MarketRate rate) {
    final priceChange = rate.currentPrice - rate.previousPrice;
    final percentageChange = (priceChange / rate.previousPrice) * 100;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getProductIcon(rate.productName),
                                color: AppTheme.primaryGreen,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rate.productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),
                                  Text(
                                    rate.category,
                                    style: const TextStyle(
                                      color: AppTheme.textGrey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getTrendColor(rate.trend).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getTrendIcon(rate.trend),
                                    color: _getTrendColor(rate.trend),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${percentageChange >= 0 ? '+' : ''}${percentageChange.toStringAsFixed(2)}%',
                                    style: TextStyle(
                                      color: _getTrendColor(rate.trend),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Price: ₹${rate.currentPrice.toStringAsFixed(2)} per ${rate.unit}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Quantity: ${rate.quantity} ${rate.unit}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Location: ${rate.location}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Quality Grade: ${rate.qualityGrade}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Last Updated: ${_formatTime(rate.lastUpdated)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Contact seller feature coming soon!'),
                                  backgroundColor: AppTheme.primaryGreen,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Contact Seller'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MarketRate {
  final String id;
  final String productName;
  final String category;
  double currentPrice;
  double previousPrice;
  final int quantity;
  final String unit;
  final String location;
  DateTime lastUpdated;
  final int volume;
  PriceTrend trend;
  final String qualityGrade;

  MarketRate({
    required this.id,
    required this.productName,
    required this.category,
    required this.currentPrice,
    required this.previousPrice,
    required this.quantity,
    required this.unit,
    required this.location,
    required this.lastUpdated,
    required this.volume,
    required this.trend,
    required this.qualityGrade,
  });
}

enum PriceTrend { up, down, stable }