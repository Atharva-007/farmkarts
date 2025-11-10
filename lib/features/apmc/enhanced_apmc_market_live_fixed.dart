import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_card.dart';
import '../../services/apmc_api_service.dart';

class EnhancedAPMCMarketLiveFixed extends StatefulWidget {
  const EnhancedAPMCMarketLiveFixed({super.key});

  @override
  State<EnhancedAPMCMarketLiveFixed> createState() => _EnhancedAPMCMarketLiveFixedState();
}

class _EnhancedAPMCMarketLiveFixedState extends State<EnhancedAPMCMarketLiveFixed>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Timer _refreshTimer;
  late APMCApiService _apiService;
  
  String _selectedState = 'All States';
  String _selectedCity = 'All Cities';
  String _selectedCategory = 'All Products';
  String _selectedUnit = 'Original Unit';
  bool _isLoading = false;
  bool _isInitialLoading = true;
  String? _errorMessage;
  
  final List<String> _states = [
    'All States', 'Maharashtra', 'Karnataka', 'Tamil Nadu', 'Gujarat', 
    'Uttar Pradesh', 'Madhya Pradesh', 'Rajasthan', 'Punjab', 'Haryana',
    'West Bengal', 'Andhra Pradesh', 'Telangana', 'Odisha', 'Kerala', 'Bihar',
  ];

  final List<String> _cities = [
    'All Cities', 'Mumbai', 'Pune', 'Nashik', 'Bangalore', 'Chennai',
    'Ahmedabad', 'Delhi', 'Kolkata', 'Hyderabad', 'Indore', 'Jaipur',
    'Ludhiana', 'Bhopal', 'Nagpur', 'Coimbatore',
  ];

  final List<String> _categories = [
    'All Products', 'Vegetables', 'Fruits', 'Grains & Cereals',
    'Pulses & Legumes', 'Spices & Condiments', 'Oil Seeds', 'Cash Crops', 'Fodder Crops',
  ];

  final List<String> _units = [
    'Original Unit', 'Per Kg', 'Per Quintal', 'Per Dozen', 'Per Ton',
  ];

  List<MarketRate> _marketData = [];
  List<MarketRate> _filteredData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _apiService = APMCApiService();
    
    _initializeData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _refreshTimer.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isInitialLoading = true;
        _errorMessage = null;
      });

      _marketData = await _apiService.fetchMarketRates();
      _filterData();
      _animationController.forward();

      setState(() {
        _isInitialLoading = false;
      });
    } catch (e) {
      setState(() {
        _isInitialLoading = false;
        _errorMessage = 'Failed to load market data: ${e.toString()}';
      });
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _refreshData();
      }
    });
  }

  Future<void> _refreshData() async {
    if (_isLoading) return;
    
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final newData = await _apiService.fetchMarketRates(
        state: _selectedState == 'All States' ? null : _selectedState,
        commodity: _selectedCategory == 'All Products' ? null : _selectedCategory,
      );

      setState(() {
        _marketData = newData;
        _filterData();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to refresh data: ${e.toString()}';
      });
    }
  }

  void _filterData() {
    _filteredData = _marketData.where((item) {
      final stateMatch = _selectedState == 'All States' || item.state == _selectedState;
      final districtMatch = _selectedCity == 'All Cities' || item.district.contains(_selectedCity);
      final categoryMatch = _selectedCategory == 'All Products' || item.category == _selectedCategory;
      return stateMatch && districtMatch && categoryMatch;
    }).toList();

    // Sort by modal price (high to low)
    _filteredData.sort((a, b) => b.modalPrice.compareTo(a.modalPrice));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: _isInitialLoading
            ? _buildLoadingState()
            : _errorMessage != null
                ? _buildErrorState()
                : _buildMainContent(),
      ),
      floatingActionButton: _buildRefreshFAB(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
          ),
          SizedBox(height: 16),
          Text(
            'Loading market data...',
            style: TextStyle(
              color: AppTheme.textGrey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load market data',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: const TextStyle(
                color: AppTheme.textGrey,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return FadeTransition(
      opacity: _animationController,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildFiltersSection(),
                      _buildMarketSummary(),
                      _buildTabBar(),
                    ],
                  ),
                ),
                SliverFillRemaining(
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
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
              _buildLiveIndicator(),
            ],
          ),
          const SizedBox(height: 16),
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
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
          const SizedBox(width: 6),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final totalProducts = _filteredData.length;
    final avgPrice = _filteredData.isEmpty 
        ? 0.0 
        : _filteredData.map((d) => d.modalPrice).reduce((a, b) => a + b) / totalProducts;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Products',
            totalProducts.toString(),
            Icons.inventory_2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Avg Price',
            '₹${avgPrice.toStringAsFixed(0)}',
            Icons.currency_rupee,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Markets',
            _filteredData.map((e) => e.market).toSet().length.toString(),
            Icons.store,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
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
          // Use responsive layout to prevent overflow
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return isWide ? _buildWideFilters() : _buildNarrowFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWideFilters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildDropdown('State', _selectedState, _states, (value) {
              setState(() {
                _selectedState = value!;
                _filterData();
              });
            })),
            const SizedBox(width: 16),
            Expanded(child: _buildDropdown('City', _selectedCity, _cities, (value) {
              setState(() {
                _selectedCity = value!;
                _filterData();
              });
            })),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDropdown('Category', _selectedCategory, _categories, (value) {
              setState(() {
                _selectedCategory = value!;
                _filterData();
              });
            })),
            const SizedBox(width: 16),
            Expanded(child: _buildDropdown('Unit', _selectedUnit, _units, (value) {
              setState(() {
                _selectedUnit = value!;
                _filterData();
              });
            })),
          ],
        ),
      ],
    );
  }

  Widget _buildNarrowFilters() {
    return Column(
      children: [
        _buildDropdown('State', _selectedState, _states, (value) {
          setState(() {
            _selectedState = value!;
            _filterData();
          });
        }),
        const SizedBox(height: 12),
        _buildDropdown('City', _selectedCity, _cities, (value) {
          setState(() {
            _selectedCity = value!;
            _filterData();
          });
        }),
        const SizedBox(height: 12),
        _buildDropdown('Category', _selectedCategory, _categories, (value) {
          setState(() {
            _selectedCategory = value!;
            _filterData();
          });
        }),
        const SizedBox(height: 12),
        _buildDropdown('Unit', _selectedUnit, _units, (value) {
          setState(() {
            _selectedUnit = value!;
            _filterData();
          });
        }),
      ],
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
        const SizedBox(height: 6),
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
        : _filteredData.map((d) => d.modalPrice).reduce((a, b) => a + b) / totalProducts;
    final highestPrice = _filteredData.isEmpty ? 0.0 : _filteredData.first.modalPrice;
    final lowestPrice = _filteredData.isEmpty ? 0.0 : _filteredData.last.modalPrice;

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
          // Use responsive grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                childAspectRatio: 2.5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  _buildSummaryItem('Total Products', totalProducts.toString(), Icons.inventory),
                  _buildSummaryItem('Average Price', '₹${avgPrice.toStringAsFixed(0)}', Icons.trending_up),
                  _buildSummaryItem('Highest Price', '₹${highestPrice.toStringAsFixed(0)}', Icons.arrow_upward),
                  _buildSummaryItem('Lowest Price', '₹${lowestPrice.toStringAsFixed(0)}', Icons.arrow_downward),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppTheme.primaryGreen,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textGrey,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.defaultShadow,
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryGreen,
        unselectedLabelColor: AppTheme.textGrey,
        indicatorColor: AppTheme.primaryGreen,
        indicatorSize: TabBarIndicatorSize.tab,
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
          ? _buildEmptyState('No products found', 'Try adjusting your filters')
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: _filteredData.length,
              itemBuilder: (context, index) {
                return _buildProductCard(_filteredData[index]);
              },
            ),
    );
  }

  Widget _buildTrendingTab() {
    final trendingData = _filteredData.take(20).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: trendingData.isEmpty
          ? _buildEmptyState('No trending products', 'Check back later for updates')
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: trendingData.length,
              itemBuilder: (context, index) {
                return _buildProductCard(trendingData[index]);
              },
            ),
    );
  }

  Widget _buildLocationTab() {
    final locationGroups = <String, List<MarketRate>>{};
    for (var data in _filteredData) {
      final key = '${data.district}, ${data.state}';
      locationGroups[key] = (locationGroups[key] ?? [])..add(data);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: locationGroups.length,
        itemBuilder: (context, index) {
          final location = locationGroups.keys.elementAt(index);
          final products = locationGroups[location]!;
          final avgPrice = products.map((p) => p.modalPrice).reduce((a, b) => a + b) / products.length;

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
            _buildPriceDistribution(),
            const SizedBox(height: 16),
            _buildMarketActivity(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(MarketRate data) {
    final priceChange = data.maxPrice - data.minPrice;
    
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
                          '${data.market} • Grade ${data.grade}',
                          style: const TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${data.district}, ${data.state}',
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
                        '₹${data.modalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      Text(
                        'per ${data.unit}',
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
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildInfoChip('Min: ₹${data.minPrice.toStringAsFixed(0)}', Icons.trending_down, Colors.red),
                  _buildInfoChip('Max: ₹${data.maxPrice.toStringAsFixed(0)}', Icons.trending_up, Colors.green),
                  if (data.arrivals > 0)
                    _buildInfoChip('Arrivals: ${data.arrivals}', Icons.local_shipping, AppTheme.textGrey),
                  _buildInfoChip(_formatDate(data.priceDate), Icons.schedule, AppTheme.textGrey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryAnalysis() {
    final categoryGroups = <String, List<MarketRate>>{};
    for (var data in _filteredData) {
      categoryGroups[data.category] = (categoryGroups[data.category] ?? [])..add(data);
    }

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Analysis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            ...categoryGroups.entries.map((entry) {
              final avgPrice = entry.value.map((e) => e.modalPrice).reduce((a, b) => a + b) / entry.value.length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '${entry.value.length} items',
                      style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
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
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDistribution() {
    final priceRanges = <String, int>{
      '< ₹100': 0,
      '₹100-500': 0,
      '₹500-1000': 0,
      '₹1000-5000': 0,
      '> ₹5000': 0,
    };

    for (var data in _filteredData) {
      final price = data.modalPrice;
      if (price < 100) {
        priceRanges['< ₹100'] = priceRanges['< ₹100']! + 1;
      } else if (price < 500) {
        priceRanges['₹100-500'] = priceRanges['₹100-500']! + 1;
      } else if (price < 1000) {
        priceRanges['₹500-1000'] = priceRanges['₹500-1000']! + 1;
      } else if (price < 5000) {
        priceRanges['₹1000-5000'] = priceRanges['₹1000-5000']! + 1;
      } else {
        priceRanges['> ₹5000'] = priceRanges['> ₹5000']! + 1;
      }
    }

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            ...priceRanges.entries.map((entry) {
              final percentage = _filteredData.isEmpty ? 0.0 : (entry.value / _filteredData.length) * 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(entry.key)),
                        Text('${entry.value} (${percentage.toStringAsFixed(1)}%)'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketActivity() {
    final totalArrivals = _filteredData.fold<int>(0, (sum, item) => sum + item.arrivals);
    final activeMarkets = _filteredData.map((e) => e.market).toSet().length;

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Market Activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActivityStat('Total Arrivals', '$totalArrivals', Icons.local_shipping),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActivityStat('Active Markets', '$activeMarkets', Icons.store),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshFAB() {
    return FloatingActionButton(
      onPressed: _refreshData,
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
    );
  }

  void _showProductDetails(MarketRate data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
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
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${data.market}',
                        style: const TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${data.district}, ${data.state}',
                        style: const TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection('Price Information', [
                      _buildDetailRow('Modal Price', '₹${data.modalPrice.toStringAsFixed(2)} per ${data.unit}'),
                      _buildDetailRow('Minimum Price', '₹${data.minPrice.toStringAsFixed(2)} per ${data.unit}'),
                      _buildDetailRow('Maximum Price', '₹${data.maxPrice.toStringAsFixed(2)} per ${data.unit}'),
                    ]),
                    const SizedBox(height: 20),
                    _buildDetailSection('Market Details', [
                      _buildDetailRow('Market', data.market),
                      _buildDetailRow('District', data.district),
                      _buildDetailRow('State', data.state),
                      _buildDetailRow('Grade', data.grade),
                      if (data.variety.isNotEmpty) _buildDetailRow('Variety', data.variety),
                    ]),
                    const SizedBox(height: 20),
                    _buildDetailSection('Additional Information', [
                      if (data.arrivals > 0) _buildDetailRow('Arrivals', '${data.arrivals} ${data.unit}'),
                      _buildDetailRow('Price Date', _formatDate(data.priceDate)),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textGrey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getProductIcon(String productName) {
    final name = productName.toLowerCase();
    if (name.contains('rice') || name.contains('wheat') || name.contains('grain')) {
      return Icons.grain;
    } else if (name.contains('tomato') || name.contains('onion') || name.contains('potato')) {
      return Icons.eco;
    } else if (name.contains('fruit') || name.contains('mango') || name.contains('apple')) {
      return Icons.apple;
    } else if (name.contains('spice') || name.contains('turmeric') || name.contains('chili')) {
      return Icons.restaurant;
    } else if (name.contains('oil') || name.contains('seed')) {
      return Icons.water_drop;
    }
    return Icons.agriculture;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}