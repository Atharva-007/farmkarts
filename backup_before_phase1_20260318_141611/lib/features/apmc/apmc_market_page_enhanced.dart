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
    'Quantity High to Low',
    'Location A-Z',
    'Most Active',
  ];

  List<APMCProduct> _products = [];
  List<APMCProduct> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _initializeProducts();
    _filterProducts();
    _animationController.forward();
    
    // Refresh market data every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateMarketPrices();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _refreshTimer.cancel();
    super.dispose();
  }

  void _initializeProducts() {
    _products = [
      APMCProduct('Wheat', 'Grains', 2450, 2480, 2420, 450.5, 'Mumbai - Vashi APMC', true, '1,250 quintals'),
      APMCProduct('Rice (Basmati)', 'Grains', 3200, 3180, 3220, 320.8, 'Delhi - Azadpur Mandi', false, '890 quintals'),
      APMCProduct('Corn', 'Grains', 1850, 1880, 1820, 225.3, 'Pune - Market Yard', true, '1,150 quintals'),
      APMCProduct('Soybeans', 'Oil Seeds', 4100, 4150, 4080, 180.7, 'Bangalore - KR Market', true, '750 quintals'),
      APMCProduct('Cotton', 'Oil Seeds', 5200, 5100, 5250, 95.2, 'Chennai - Koyambedu', false, '520 quintals'),
      APMCProduct('Tomato', 'Vegetables', 1250, 1300, 1200, 125.5, 'Mumbai - Vashi APMC', true, '2,100 quintals'),
      APMCProduct('Onion (Red)', 'Vegetables', 1800, 1750, 1850, 200.0, 'Delhi - Azadpur Mandi', false, '1,850 quintals'),
      APMCProduct('Potato', 'Vegetables', 950, 980, 920, 180.0, 'Pune - Market Yard', true, '3,200 quintals'),
      APMCProduct('Banana', 'Fruits', 2200, 2250, 2150, 75.2, 'Bangalore - KR Market', true, '950 quintals'),
      APMCProduct('Apple', 'Fruits', 8500, 8600, 8400, 45.8, 'Chennai - Koyambedu', true, '425 quintals'),
      APMCProduct('Mango', 'Fruits', 3500, 3600, 3400, 85.5, 'Kolkata - Sealdah', true, '680 quintals'),
      APMCProduct('Turmeric', 'Spices', 12500, 12800, 12200, 25.3, 'Hyderabad - Gaddiannaram', true, '180 quintals'),
      APMCProduct('Chili (Red)', 'Spices', 15000, 15200, 14800, 32.1, 'Nashik - Agricultural Market', false, '220 quintals'),
      APMCProduct('Coriander', 'Spices', 9800, 10000, 9600, 18.7, 'Indore - Krishi Upaj Mandi', true, '150 quintals'),
      APMCProduct('Arhar (Toor)', 'Pulses', 6800, 7000, 6600, 120.5, 'Mumbai - Vashi APMC', true, '450 quintals'),
      APMCProduct('Chana', 'Pulses', 5200, 5300, 5100, 150.8, 'Delhi - Azadpur Mandi', false, '680 quintals'),
      APMCProduct('Masoor', 'Pulses', 4500, 4600, 4400, 95.2, 'Pune - Market Yard', true, '320 quintals'),
      APMCProduct('Groundnut', 'Oil Seeds', 5800, 5900, 5700, 180.5, 'Bangalore - KR Market', true, '750 quintals'),
      APMCProduct('Mustard', 'Oil Seeds', 4200, 4300, 4100, 125.3, 'Chennai - Koyambedu', false, '520 quintals'),
      APMCProduct('Sugarcane', 'Others', 320, 330, 310, 2500.0, 'Kolkata - Sealdah', true, '15,000 quintals'),
    ];
  }

  void _updateMarketPrices() {
    if (!mounted) return;
    
    setState(() {
      for (var product in _products) {
        final random = Random();
        final changePercent = (random.nextDouble() - 0.5) * 0.02; // ±1% max change
        final newPrice = product.currentPrice * (1 + changePercent);
        
        product.currentPrice = newPrice;
        product.highPrice = max(product.highPrice, newPrice);
        product.lowPrice = min(product.lowPrice, newPrice);
        product.isRising = changePercent > 0;
      }
    });
    
    _filterProducts();
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products.where((product) {
        bool matchesLocation = _selectedLocation == 'All Locations' || 
                              product.location == _selectedLocation;
        bool matchesCategory = _selectedCategory == 'All Products' || 
                              product.category == _selectedCategory;
        return matchesLocation && matchesCategory;
      }).toList();
      
      _sortProducts();
    });
  }

  void _sortProducts() {
    switch (_sortBy) {
      case 'Price High to Low':
        _filteredProducts.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
        break;
      case 'Price Low to High':
        _filteredProducts.sort((a, b) => a.currentPrice.compareTo(b.currentPrice));
        break;
      case 'Quantity High to Low':
        _filteredProducts.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
      case 'Location A-Z':
        _filteredProducts.sort((a, b) => a.location.compareTo(b.location));
        break;
      case 'Most Active':
        _filteredProducts.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundLight,
      child: SafeArea(
        child: FadeTransition(
          opacity: _animationController,
          child: Column(
            children: [
              _buildHeader(),
              _buildFilters(),
              _buildMarketSummary(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProductList(),
                    _buildTrendingProducts(),
                    _buildLocationAnalysis(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    
    return Container(
      padding: ResponsiveHelper.getScreenPadding(context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.deepGreen,
            AppTheme.primaryGreen,
          ],
        ),
        boxShadow: AppTheme.defaultShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: isDesktop ? 28 : 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'APMC Live Market',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isDesktop ? 28 : 24,
                      ),
                    ),
                    Text(
                      'Real-time agricultural commodity prices',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        fontSize: isDesktop ? 16 : 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      color: AppTheme.success,
                      size: 8,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Last updated: ${DateTime.now().toString().substring(11, 19)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return Container(
      padding: ResponsiveHelper.getScreenPadding(context).copyWith(top: 16, bottom: 8),
      child: Column(
        children: [
          if (isMobile) ...[
            _buildMobileFilters(),
          ] else ...[
            _buildDesktopFilters(),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileFilters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFilterDropdown(
                'Location',
                _selectedLocation,
                _locations,
                (value) => setState(() {
                  _selectedLocation = value!;
                  _filterProducts();
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFilterDropdown(
                'Category',
                _selectedCategory,
                _categories,
                (value) => setState(() {
                  _selectedCategory = value!;
                  _filterProducts();
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildFilterDropdown(
          'Sort By',
          _sortBy,
          _sortOptions,
          (value) => setState(() {
            _sortBy = value!;
            _filterProducts();
          }),
        ),
      ],
    );
  }

  Widget _buildDesktopFilters() {
    return Row(
      children: [
        Expanded(
          child: _buildFilterDropdown(
            'Location',
            _selectedLocation,
            _locations,
            (value) => setState(() {
              _selectedLocation = value!;
              _filterProducts();
            }),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildFilterDropdown(
            'Category',
            _selectedCategory,
            _categories,
            (value) => setState(() {
              _selectedCategory = value!;
              _filterProducts();
            }),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildFilterDropdown(
            'Sort By',
            _sortBy,
            _sortOptions,
            (value) => setState(() {
              _sortBy = value!;
              _filterProducts();
            }),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _isLoading = true;
            });
            _updateMarketPrices();
            Future.delayed(const Duration(seconds: 1), () {
              setState(() {
                _isLoading = false;
              });
            });
          },
          icon: _isLoading 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.refresh),
          label: const Text('Refresh'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppTheme.textGrey,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderGrey),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              onChanged: onChanged,
              items: options.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    option,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarketSummary() {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final totalProducts = _filteredProducts.length;
    final risingProducts = _filteredProducts.where((p) => p.isRising).length;
    final avgPrice = _filteredProducts.isEmpty 
        ? 0.0 
        : _filteredProducts.map((p) => p.currentPrice).reduce((a, b) => a + b) / totalProducts;
    
    return Container(
      margin: ResponsiveHelper.getScreenPadding(context).copyWith(top: 8, bottom: 16),
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.defaultShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'Total Products',
              totalProducts.toString(),
              Icons.inventory,
              AppTheme.primaryGreen,
            ),
          ),
          Container(width: 1, height: 50, color: AppTheme.borderGrey),
          Expanded(
            child: _buildSummaryItem(
              'Rising Prices',
              risingProducts.toString(),
              Icons.trending_up,
              AppTheme.success,
            ),
          ),
          Container(width: 1, height: 50, color: AppTheme.borderGrey),
          Expanded(
            child: _buildSummaryItem(
              'Avg Price',
              '₹${avgPrice.toStringAsFixed(0)}',
              Icons.currency_rupee,
              AppTheme.accentOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textGrey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: ResponsiveHelper.getScreenPadding(context).copyWith(top: 0, bottom: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryGreen,
        unselectedLabelColor: AppTheme.textGrey,
        indicatorColor: AppTheme.primaryGreen,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'All Products'),
          Tab(text: 'Trending'),
          Tab(text: 'By Location'),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return Container(
      color: Colors.white,
      child: ListView.builder(
        padding: ResponsiveHelper.getScreenPadding(context),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          return _buildProductCard(_filteredProducts[index]);
        },
      ),
    );
  }

  Widget _buildProductCard(APMCProduct product) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: product.isRising 
                        ? AppTheme.success.withOpacity(0.1)
                        : AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCommodityIcon(product.name),
                    color: product.isRising ? AppTheme.success : AppTheme.error,
                    size: isDesktop ? 24 : 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        product.category,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.location,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                      '₹${product.currentPrice.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: product.isRising ? AppTheme.success : AppTheme.error,
                      ),
                    ),
                    Text(
                      'per quintal',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          product.isRising ? Icons.trending_up : Icons.trending_down,
                          size: 16,
                          color: product.isRising ? AppTheme.success : AppTheme.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${product.isRising ? '+' : ''}${(product.currentPrice - (product.highPrice + product.lowPrice) / 2).toStringAsFixed(0)}',
                          style: TextStyle(
                            color: product.isRising ? AppTheme.success : AppTheme.error,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPriceDetail('High', product.highPrice),
                ),
                Expanded(
                  child: _buildPriceDetail('Low', product.lowPrice),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantity',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        product.quantity,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDetail(String label, double price) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '₹${price.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingProducts() {
    final trendingProducts = _filteredProducts
        .where((product) => product.isRising)
        .take(10)
        .toList();
    
    return Container(
      color: Colors.white,
      child: ListView.builder(
        padding: ResponsiveHelper.getScreenPadding(context),
        itemCount: trendingProducts.length,
        itemBuilder: (context, index) {
          return _buildProductCard(trendingProducts[index]);
        },
      ),
    );
  }

  Widget _buildLocationAnalysis() {
    final locationGroups = <String, List<APMCProduct>>{};
    for (var product in _filteredProducts) {
      locationGroups[product.location] = 
          (locationGroups[product.location] ?? [])..add(product);
    }
    
    return Container(
      color: Colors.white,
      child: ListView.builder(
        padding: ResponsiveHelper.getScreenPadding(context),
        itemCount: locationGroups.length,
        itemBuilder: (context, index) {
          final location = locationGroups.keys.elementAt(index);
          final products = locationGroups[location]!;
          
          return _buildLocationCard(location, products);
        },
      ),
    );
  }

  Widget _buildLocationCard(String location, List<APMCProduct> products) {
    final avgPrice = products.map((p) => p.currentPrice).reduce((a, b) => a + b) / products.length;
    final risingCount = products.where((p) => p.isRising).length;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          location,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text('${products.length} products • Avg: ₹${avgPrice.toStringAsFixed(0)}'),
        children: products.map((product) => _buildProductCard(product)).toList(),
      ),
    );
  }

  IconData _getCommodityIcon(String name) {
    switch (name.toLowerCase()) {
      case 'wheat':
        return Icons.grain;
      case 'rice':
      case 'rice (basmati)':
        return Icons.rice_bowl;
      case 'corn':
        return Icons.grain;
      case 'tomato':
        return Icons.local_pizza;
      case 'onion':
      case 'onion (red)':
        return Icons.local_florist;
      case 'potato':
        return Icons.set_meal;
      case 'banana':
        return Icons.breakfast_dining;
      case 'apple':
        return Icons.apple;
      case 'mango':
        return Icons.local_dining;
      case 'cotton':
        return Icons.grass;
      case 'sugarcane':
        return Icons.grass;
      default:
        return Icons.agriculture;
    }
  }
}

class APMCProduct {
  final String name;
  final String category;
  double currentPrice;
  double highPrice;
  double lowPrice;
  final double volume;
  final String location;
  bool isRising;
  final String quantity;

  APMCProduct(
    this.name,
    this.category,
    this.currentPrice,
    this.highPrice,
    this.lowPrice,
    this.volume,
    this.location,
    this.isRising,
    this.quantity,
  );
}