import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_card.dart';

class EnhancedAPMCMarketLive extends StatefulWidget {
  const EnhancedAPMCMarketLive({super.key});

  @override
  State<EnhancedAPMCMarketLive> createState() => _EnhancedAPMCMarketLiveState();
}

class _EnhancedAPMCMarketLiveState extends State<EnhancedAPMCMarketLive>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Timer _refreshTimer;
  
  String _selectedState = 'All States';
  String _selectedCity = 'All Cities';
  String _selectedCategory = 'All Products';
  String _selectedUnit = 'Original Unit';
  bool _isLoading = false;
  
  final List<String> _states = [
    'All States',
    'Maharashtra',
    'Karnataka',
    'Tamil Nadu',
    'Gujarat', 
    'Uttar Pradesh',
    'Madhya Pradesh',
    'Rajasthan',
    'Punjab',
    'Haryana',
    'West Bengal',
    'Andhra Pradesh',
    'Telangana',
    'Odisha',
    'Kerala',
    'Bihar',
  ];

  final List<String> _cities = [
    'All Cities',
    'Mumbai',
    'Pune',
    'Nashik',
    'Bangalore',
    'Chennai',
    'Ahmedabad',
    'Delhi',
    'Kolkata',
    'Hyderabad',
    'Indore',
    'Jaipur',
    'Ludhiana',
    'Bhopal',
    'Nagpur',
    'Coimbatore',
  ];

  final List<String> _categories = [
    'All Products',
    'Vegetables',
    'Fruits', 
    'Grains & Cereals',
    'Pulses & Legumes',
    'Spices & Condiments',
    'Oil Seeds',
    'Cash Crops',
    'Fodder Crops',
  ];

  final List<String> _units = [
    'Original Unit',
    'Per Kg',
    'Per Quintal',
    'Per Dozen',
    'Per Ton',
  ];

  List<APMCMarketData> _marketData = [];
  List<APMCMarketData> _filteredData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _generateMarketData();
    _filterData();
    _animationController.forward();
    
    // Auto-refresh every 45 seconds for live data simulation
    _refreshTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      _updateLiveData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _refreshTimer.cancel();
    super.dispose();
  }

  void _generateMarketData() {
    final random = Random();
    final products = [
      // Vegetables - Fixed structure
      {'name': 'Tomato', 'category': 'Vegetables', 'baseUnit': 'Kg', 'basePrice': 35.0},
      {'name': 'Onion (Red)', 'category': 'Vegetables', 'baseUnit': 'Kg', 'basePrice': 28.0},
      {'name': 'Potato', 'category': 'Vegetables', 'baseUnit': 'Kg', 'basePrice': 22.0},
      {'name': 'Cabbage', 'category': 'Vegetables', 'baseUnit': 'Kg', 'basePrice': 18.0},
      {'name': 'Cauliflower', 'category': 'Vegetables', 'baseUnit': 'Kg', 'basePrice': 25.0},
      {'name': 'Carrot', 'category': 'Vegetables', 'baseUnit': 'Kg', 'basePrice': 30.0},
      {'name': 'Green Beans', 'category': 'Vegetables', 'baseUnit': 'Kg', 'basePrice': 45.0},
      {'name': 'Brinjal', 'category': 'Vegetables', 'baseUnit': 'Kg', 'basePrice': 32.0},
      
      // Fruits
      {'name': 'Apple', 'category': 'Fruits', 'baseUnit': 'Kg', 'basePrice': 120.0},
      {'name': 'Banana', 'category': 'Fruits', 'baseUnit': 'Dozen', 'basePrice': 45.0},
      {'name': 'Orange', 'category': 'Fruits', 'baseUnit': 'Kg', 'basePrice': 60.0},
      {'name': 'Mango', 'category': 'Fruits', 'baseUnit': 'Kg', 'basePrice': 80.0},
      {'name': 'Grapes', 'category': 'Fruits', 'baseUnit': 'Kg', 'basePrice': 85.0},
      {'name': 'Pomegranate', 'category': 'Fruits', 'baseUnit': 'Kg', 'basePrice': 150.0},
      
      // Grains & Cereals  
      {'name': 'Rice (Basmati)', 'category': 'Grains & Cereals', 'baseUnit': 'Quintal', 'basePrice': 3200.0},
      {'name': 'Wheat', 'category': 'Grains & Cereals', 'baseUnit': 'Quintal', 'basePrice': 2100.0},
      {'name': 'Maize', 'category': 'Grains & Cereals', 'baseUnit': 'Quintal', 'basePrice': 1850.0},
      {'name': 'Bajra', 'category': 'Grains & Cereals', 'baseUnit': 'Quintal', 'basePrice': 2200.0},
      {'name': 'Jowar', 'category': 'Grains & Cereals', 'baseUnit': 'Quintal', 'basePrice': 2050.0},
      
      // Pulses & Legumes
      {'name': 'Toor Dal', 'category': 'Pulses & Legumes', 'baseUnit': 'Quintal', 'basePrice': 6800.0},
      {'name': 'Moong Dal', 'category': 'Pulses & Legumes', 'baseUnit': 'Quintal', 'basePrice': 7200.0},
      {'name': 'Chana', 'category': 'Pulses & Legumes', 'baseUnit': 'Quintal', 'basePrice': 5400.0},
      {'name': 'Masoor', 'category': 'Pulses & Legumes', 'baseUnit': 'Quintal', 'basePrice': 4800.0},
      
      // Spices & Condiments
      {'name': 'Turmeric', 'category': 'Spices & Condiments', 'baseUnit': 'Kg', 'basePrice': 125.0},
      {'name': 'Red Chili', 'category': 'Spices & Condiments', 'baseUnit': 'Kg', 'basePrice': 180.0},
      {'name': 'Coriander', 'category': 'Spices & Condiments', 'baseUnit': 'Kg', 'basePrice': 98.0},
      {'name': 'Cumin', 'category': 'Spices & Condiments', 'baseUnit': 'Kg', 'basePrice': 450.0},
      
      // Oil Seeds
      {'name': 'Groundnut', 'category': 'Oil Seeds', 'baseUnit': 'Quintal', 'basePrice': 5800.0},
      {'name': 'Soybean', 'category': 'Oil Seeds', 'baseUnit': 'Quintal', 'basePrice': 4200.0},
      {'name': 'Sunflower', 'category': 'Oil Seeds', 'baseUnit': 'Quintal', 'basePrice': 5500.0},
      {'name': 'Mustard', 'category': 'Oil Seeds', 'baseUnit': 'Quintal', 'basePrice': 4800.0},
      
      // Cash Crops
      {'name': 'Cotton', 'category': 'Cash Crops', 'baseUnit': 'Quintal', 'basePrice': 5200.0},
      {'name': 'Sugarcane', 'category': 'Cash Crops', 'baseUnit': 'Ton', 'basePrice': 320.0},
      {'name': 'Tobacco', 'category': 'Cash Crops', 'baseUnit': 'Kg', 'basePrice': 180.0},
    ];

    _marketData = products.map((product) {
      final priceVariation = random.nextDouble() * 0.4 - 0.2; // ±20% variation
      final currentPrice = product['basePrice']! as double;
      final variatedPrice = currentPrice * (1 + priceVariation);
      final yesterdayPrice = variatedPrice * (1 + (random.nextDouble() * 0.1 - 0.05));
      
      return APMCMarketData(
        id: (product['name']! as String).toLowerCase().replaceAll(' ', '_'),
        productName: product['name']! as String,
        category: product['category']! as String,
        currentPrice: variatedPrice,
        yesterdayPrice: yesterdayPrice,
        highPrice: variatedPrice * (1 + random.nextDouble() * 0.15),
        lowPrice: variatedPrice * (1 - random.nextDouble() * 0.15),
        originalUnit: product['baseUnit']! as String,
        displayUnit: product['baseUnit']! as String,
        quantity: random.nextInt(5000) + 500,
        state: _states[random.nextInt(_states.length - 1) + 1],
        city: _cities[random.nextInt(_cities.length - 1) + 1],
        marketName: _generateMarketName(_cities[random.nextInt(_cities.length - 1) + 1]),
        lastUpdated: DateTime.now().subtract(Duration(minutes: random.nextInt(120))),
        volume: random.nextInt(100000) + 10000,
        qualityGrade: ['A', 'B', 'C'][random.nextInt(3)],
        trend: _calculateTrend(variatedPrice, yesterdayPrice),
        farmers: random.nextInt(50) + 10,
        buyers: random.nextInt(30) + 5,
      );
    }).toList();
  }

  String _generateMarketName(String city) {
    final marketTypes = ['APMC', 'Krishi Upaj Mandi', 'Agricultural Market', 'Wholesale Market'];
    return '$city ${marketTypes[Random().nextInt(marketTypes.length)]}';
  }

  PriceTrend _calculateTrend(double current, double previous) {
    final change = (current - previous) / previous;
    if (change > 0.02) return PriceTrend.up;
    if (change < -0.02) return PriceTrend.down;
    return PriceTrend.stable;
  }

  void _updateLiveData() {
    if (!mounted) return;
    
    final random = Random();
    for (var item in _marketData) {
      final change = (random.nextDouble() - 0.5) * 0.04; // ±2% max change
      item.yesterdayPrice = item.currentPrice;
      item.currentPrice = item.currentPrice * (1 + change);
      item.highPrice = max(item.highPrice, item.currentPrice);
      item.lowPrice = min(item.lowPrice, item.currentPrice);
      item.lastUpdated = DateTime.now();
      item.trend = _calculateTrend(item.currentPrice, item.yesterdayPrice);
    }
    
    if (mounted) {
      setState(() {
        _filterData();
      });
    }
  }

  void _filterData() {
    _filteredData = _marketData.where((item) {
      final stateMatch = _selectedState == 'All States' || item.state == _selectedState;
      final cityMatch = _selectedCity == 'All Cities' || item.city == _selectedCity;
      final categoryMatch = _selectedCategory == 'All Products' || item.category == _selectedCategory;
      return stateMatch && cityMatch && categoryMatch;
    }).toList();

    // Convert units if needed
    for (var item in _filteredData) {
      _convertUnit(item);
    }

    // Sort by current price (high to low)
    _filteredData.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
  }

  void _convertUnit(APMCMarketData item) {
    if (_selectedUnit == 'Original Unit' || item.originalUnit == _selectedUnit.replaceAll('Per ', '')) {
      item.displayUnit = item.originalUnit;
      return;
    }

    final originalUnit = item.originalUnit;
    final targetUnit = _selectedUnit.replaceAll('Per ', '');
    
    // Base conversion rates (everything converted to kg first)
    final toKgRates = {
      'Kg': 1.0,
      'Quintal': 100.0,
      'Ton': 1000.0,
      'Dozen': 1.0, // Special case - dozen items treated as 1 unit
    };

    final fromKgRates = {
      'Kg': 1.0,
      'Quintal': 0.01,
      'Ton': 0.001,
      'Dozen': 1.0, // Special case
    };

    if (originalUnit == 'Dozen' || targetUnit == 'Dozen') {
      // Special handling for dozen - no conversion for now
      item.displayUnit = item.originalUnit;
      return;
    }

    final originalToKg = toKgRates[originalUnit] ?? 1.0;
    final kgToTarget = fromKgRates[targetUnit] ?? 1.0;
    
    final conversionRate = originalToKg * kgToTarget;
    
    if (conversionRate != 1.0) {
      item.currentPrice = item.currentPrice * conversionRate;
      item.yesterdayPrice = item.yesterdayPrice * conversionRate;
      item.highPrice = item.highPrice * conversionRate;
      item.lowPrice = item.lowPrice * conversionRate;
      item.displayUnit = targetUnit;
    } else {
      item.displayUnit = item.originalUnit;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: FadeTransition(
          opacity: _animationController,
          child: Column(
            children: [
              _buildHeader(),
              _buildFiltersSection(),
              _buildMarketSummary(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllProductsTab(),
                    _buildTrendingTab(),
                    _buildLocationTab(),
                    _buildAnalyticsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isLoading = true;
          });
          _updateLiveData();
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          });
        },
        backgroundColor: AppTheme.primaryGreen,
        child: _isLoading 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
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
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'APMC Live Market',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Real-time commodity prices across India',
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
                  color: Colors.green.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
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
          const SizedBox(height: 16),
          Text(
            'Last updated: ${_formatTime(DateTime.now())}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.defaultShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Filters',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Mobile responsive filters
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: (MediaQuery.of(context).size.width - 72) / 2,
                child: _buildDropdown('State', _selectedState, _states, (value) {
                  setState(() {
                    _selectedState = value!;
                    _filterData();
                  });
                }),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 72) / 2,
                child: _buildDropdown('City', _selectedCity, _cities, (value) {
                  setState(() {
                    _selectedCity = value!;
                    _filterData();
                  });
                }),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 72) / 2,
                child: _buildDropdown('Category', _selectedCategory, _categories, (value) {
                  setState(() {
                    _selectedCategory = value!;
                    _filterData();
                  });
                }),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 72) / 2,
                child: _buildDropdown('Unit', _selectedUnit, _units, (value) {
                  setState(() {
                    _selectedUnit = value!;
                    _filterData();
                  });
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textGrey,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderGrey),
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

  Widget _buildMarketSummary() {
    final totalProducts = _filteredData.length;
    final avgPrice = _filteredData.isEmpty 
        ? 0.0 
        : _filteredData.map((d) => d.currentPrice).reduce((a, b) => a + b) / totalProducts;
    final risingCount = _filteredData.where((d) => d.trend == PriceTrend.up).length;
    final fallingCount = _filteredData.where((d) => d.trend == PriceTrend.down).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.defaultShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Market Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Use Wrap instead of Row to prevent overflow
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: (MediaQuery.of(context).size.width - 64) / 2,
                child: _buildSummaryCard(
                  'Products',
                  totalProducts.toString(),
                  Icons.inventory,
                  AppTheme.primaryGreen,
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 64) / 2,
                child: _buildSummaryCard(
                  'Avg Price',
                  '₹${avgPrice.toStringAsFixed(0)}',
                  Icons.currency_rupee,
                  AppTheme.skyBlue,
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 64) / 2,
                child: _buildSummaryCard(
                  'Rising',
                  risingCount.toString(),
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 64) / 2,
                child: _buildSummaryCard(
                  'Falling',
                  fallingCount.toString(),
                  Icons.trending_down,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.defaultShadow,
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryGreen,
        unselectedLabelColor: AppTheme.textGrey,
        indicatorColor: AppTheme.primaryGreen,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        tabs: const [
          Tab(text: 'All Products'),
          Tab(text: 'Trending'),
          Tab(text: 'Locations'), 
          Tab(text: 'Analytics'),
        ],
      ),
    );
  }

  Widget _buildAllProductsTab() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: _filteredData.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: AppTheme.textGrey),
                  SizedBox(height: 16),
                  Text(
                    'No products found for selected filters',
                    style: TextStyle(color: AppTheme.textGrey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: _filteredData.length,
              itemBuilder: (context, index) {
                return _buildProductCard(_filteredData[index]);
              },
            ),
    );
  }

  Widget _buildProductCard(APMCMarketData data) {
    final priceChange = data.currentPrice - data.yesterdayPrice;
    final percentageChange = (priceChange / data.yesterdayPrice) * 100;
    
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showProductDetails(data),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getProductIcon(data.productName),
                      color: AppTheme.primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${data.marketName} • Grade ${data.qualityGrade}',
                          style: const TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${data.city}, ${data.state}',
                          style: const TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${data.currentPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      Text(
                        'per ${data.displayUnit}',
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
              // Use Wrap to prevent overflow in bottom section
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTrendColor(data.trend).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getTrendIcon(data.trend),
                          color: _getTrendColor(data.trend),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${percentageChange >= 0 ? '+' : ''}${percentageChange.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: _getTrendColor(data.trend),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Qty: ${data.quantity} ${data.displayUnit}',
                    style: const TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Vol: ${(data.volume / 1000).toStringAsFixed(1)}K',
                    style: const TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _formatTime(data.lastUpdated),
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

  Widget _buildTrendingTab() {
    final trendingData = _filteredData
        .where((d) => d.trend == PriceTrend.up)
        .take(20)
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: trendingData.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, size: 64, color: AppTheme.textGrey),
                  SizedBox(height: 16),
                  Text(
                    'No trending products found',
                    style: TextStyle(color: AppTheme.textGrey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: trendingData.length,
              itemBuilder: (context, index) {
                return _buildProductCard(trendingData[index]);
              },
            ),
    );
  }

  Widget _buildLocationTab() {
    final locationGroups = <String, List<APMCMarketData>>{};
    for (var data in _filteredData) {
      final key = '${data.city}, ${data.state}';
      locationGroups[key] = (locationGroups[key] ?? [])..add(data);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: locationGroups.length,
        itemBuilder: (context, index) {
          final location = locationGroups.keys.elementAt(index);
          final products = locationGroups[location]!;
          final avgPrice = products.map((p) => p.currentPrice).reduce((a, b) => a + b) / products.length;

          return CustomCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(
                location,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${products.length} products • Avg: ₹${avgPrice.toStringAsFixed(0)}'),
              children: products.map((product) => _buildProductCard(product)).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildCategoryAnalysis(),
            const SizedBox(height: 16),
            _buildPriceAnalysis(),
            const SizedBox(height: 16),
            _buildMarketActivity(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryAnalysis() {
    final categoryData = <String, double>{};
    final categoryCount = <String, int>{};
    
    for (var data in _filteredData) {
      categoryData[data.category] = (categoryData[data.category] ?? 0) + data.currentPrice;
      categoryCount[data.category] = (categoryCount[data.category] ?? 0) + 1;
    }

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: AppTheme.primaryGreen, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Category Analysis',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...categoryData.entries.map((entry) {
              final category = entry.key;
              final totalPrice = entry.value;
              final count = categoryCount[category]!;
              final avgPrice = totalPrice / count;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '$count products',
                            style: const TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${avgPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceAnalysis() {
    if (_filteredData.isEmpty) {
      return const CustomCard(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No data available for price analysis'),
        ),
      );
    }

    final prices = _filteredData.map((d) => d.currentPrice).toList()..sort();
    final minPrice = prices.first;
    final maxPrice = prices.last;
    final medianPrice = prices[prices.length ~/ 2];

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: AppTheme.primaryGreen, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Price Analysis',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsItem('Minimum', '₹${minPrice.toStringAsFixed(0)}', Colors.green),
                ),
                Expanded(
                  child: _buildAnalyticsItem('Maximum', '₹${maxPrice.toStringAsFixed(0)}', Colors.red),
                ),
                Expanded(
                  child: _buildAnalyticsItem('Median', '₹${medianPrice.toStringAsFixed(0)}', Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketActivity() {
    final totalFarmers = _filteredData.fold(0, (sum, d) => sum + d.farmers);
    final totalBuyers = _filteredData.fold(0, (sum, d) => sum + d.buyers);
    final totalVolume = _filteredData.fold(0, (sum, d) => sum + d.volume);

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: AppTheme.primaryGreen, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Market Activity',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsItem('Farmers', totalFarmers.toString(), AppTheme.primaryGreen),
                ),
                Expanded(
                  child: _buildAnalyticsItem('Buyers', totalBuyers.toString(), AppTheme.skyBlue),
                ),
                Expanded(
                  child: _buildAnalyticsItem('Volume', '${(totalVolume / 1000).toStringAsFixed(0)}K', AppTheme.accentOrange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
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
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getProductIcon(String productName) {
    final name = productName.toLowerCase();
    if (name.contains('tomato') || name.contains('potato') || name.contains('onion')) {
      return Icons.eco;
    } else if (name.contains('apple') || name.contains('banana') || name.contains('orange')) {
      return Icons.local_florist;
    } else if (name.contains('rice') || name.contains('wheat') || name.contains('maize')) {
      return Icons.grain;
    } else if (name.contains('cotton') || name.contains('sugarcane')) {
      return Icons.grass;
    } else if (name.contains('turmeric') || name.contains('chili') || name.contains('coriander')) {
      return Icons.spa;
    }
    return Icons.agriculture;
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
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showProductDetails(APMCMarketData data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProductDetailsSheet(data),
    );
  }

  Widget _buildProductDetailsSheet(APMCMarketData data) {
    final priceChange = data.currentPrice - data.yesterdayPrice;
    final percentageChange = (priceChange / data.yesterdayPrice) * 100;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                _getProductIcon(data.productName),
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
                                    data.productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),
                                  Text(
                                    data.category,
                                    style: const TextStyle(
                                      color: AppTheme.textGrey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Price Information
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current Price',
                                style: TextStyle(
                                  color: AppTheme.textGrey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '₹${data.currentPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'per ${data.displayUnit}',
                                    style: const TextStyle(
                                      color: AppTheme.textGrey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getTrendColor(data.trend).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getTrendIcon(data.trend),
                                      color: _getTrendColor(data.trend),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${percentageChange >= 0 ? '+' : ''}${percentageChange.toStringAsFixed(2)}% from yesterday',
                                      style: TextStyle(
                                        color: _getTrendColor(data.trend),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Market Details
                        _buildDetailRow('Market', data.marketName),
                        _buildDetailRow('Location', '${data.city}, ${data.state}'),
                        _buildDetailRow('Quality Grade', data.qualityGrade),
                        _buildDetailRow('Available Quantity', '${data.quantity} ${data.displayUnit}'),
                        _buildDetailRow('High Price', '₹${data.highPrice.toStringAsFixed(2)}'),
                        _buildDetailRow('Low Price', '₹${data.lowPrice.toStringAsFixed(2)}'),
                        _buildDetailRow('Volume Traded', '${(data.volume / 1000).toStringAsFixed(1)}K ${data.displayUnit}'),
                        _buildDetailRow('Active Farmers', data.farmers.toString()),
                        _buildDetailRow('Active Buyers', data.buyers.toString()),
                        _buildDetailRow('Last Updated', _formatTime(data.lastUpdated)),
                        
                        const SizedBox(height: 24),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Contact seller feature coming soon!'),
                                      backgroundColor: AppTheme.primaryGreen,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.phone),
                                label: const Text('Contact Seller'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Add to watchlist feature coming soon!'),
                                      backgroundColor: AppTheme.skyBlue,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.bookmark_border),
                                label: const Text('Add to Watchlist'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryGreen,
                                  side: const BorderSide(color: AppTheme.primaryGreen),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class APMCMarketData {
  final String id;
  final String productName;
  final String category;
  double currentPrice;
  double yesterdayPrice;
  double highPrice;
  double lowPrice;
  final String originalUnit;
  String displayUnit;
  final int quantity;
  final String state;
  final String city;
  final String marketName;
  DateTime lastUpdated;
  final int volume;
  final String qualityGrade;
  PriceTrend trend;
  final int farmers;
  final int buyers;

  APMCMarketData({
    required this.id,
    required this.productName,
    required this.category,
    required this.currentPrice,
    required this.yesterdayPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.originalUnit,
    required this.displayUnit,
    required this.quantity,
    required this.state,
    required this.city,
    required this.marketName,
    required this.lastUpdated,
    required this.volume,
    required this.qualityGrade,
    required this.trend,
    required this.farmers,
    required this.buyers,
  });
}

class CommodityInfo {
  final String name;
  final String category;
  final double basePrice;
  final String baseUnit;

  CommodityInfo(this.name, this.category, this.basePrice, this.baseUnit);
}

enum PriceTrend { up, down, stable }