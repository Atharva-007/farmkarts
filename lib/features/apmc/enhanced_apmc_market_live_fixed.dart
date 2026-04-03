import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/universal_drawer.dart';
import '../../widgets/universal_header.dart';
import '../../services/apmc_api_service.dart';
import 'apmc_commodity_detail_page.dart';

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
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedState = 'All States';
  String _selectedCity = 'All Cities';
  String _selectedCategory = 'All Products';
  String _selectedUnit = 'Original Unit';
  String _searchQuery = '';
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
      if (!mounted) return;
      setState(() {
        _isInitialLoading = true;
        _errorMessage = null;
      });

      _marketData = await _apiService.fetchMarketRates();
      if (!mounted) return;
      _filterData();
      _animationController.forward();

      setState(() {
        _isInitialLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final newData = await _apiService.fetchMarketRates(
        state: _selectedState == 'All States' ? null : _selectedState,
        commodity: _selectedCategory == 'All Products' ? null : _selectedCategory,
      );

      if (!mounted) return;
      setState(() {
        _marketData = newData;
        _filterData();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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
      final searchMatch = _searchQuery.isEmpty || 
          item.productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.market.toLowerCase().contains(_searchQuery.toLowerCase());
      return stateMatch && districtMatch && categoryMatch && searchMatch;
    }).toList();

    // Sort by modal price (high to low)
    _filteredData.sort((a, b) => b.modalPrice.compareTo(a.modalPrice));
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: AppTheme.getTextColor(context)),
        decoration: InputDecoration(
          hintText: 'Search commodities or markets...',
          hintStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context).withOpacity(0.7)),
          prefixIcon: Icon(Icons.search, color: AppTheme.getPrimaryAccent(context)),
          suffixIcon: _searchQuery.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _filterData();
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: isDark ? BorderSide(color: AppTheme.getBorderColor(context)) : BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: isDark ? BorderSide(color: AppTheme.getBorderColor(context)) : BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.getPrimaryAccent(context), width: 1.5),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _filterData();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const UniversalDrawer(currentPage: 'apmc'),
      body: _isInitialLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildMainContent(),
      floatingActionButton: _buildRefreshFAB(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.getPrimaryAccent(context)),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading market data...',
            style: TextStyle(
              color: AppTheme.getSecondaryTextColor(context),
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
              style: TextStyle(
                color: AppTheme.getSecondaryTextColor(context),
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
                backgroundColor: AppTheme.getPrimaryAccent(context),
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
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildSearchBar(),
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
    );
  }

  Widget _buildSliverAppBar() {
    return UniversalHeader(
      title: 'APMC Markets',
      subtitle: 'Live market rates & trends',
      icon: Icons.business,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () => _showPriceAlerts(),
          tooltip: 'Price Alerts',
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () => _initializeData(),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  void _showPriceAlerts() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Price alerts feature coming soon!'),
        backgroundColor: AppTheme.getPrimaryAccent(context),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Market Filters'),
        content: const Text('Filter options coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
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
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Avg Price',
            '₹${avgPrice.toStringAsFixed(0)}',
            Icons.currency_rupee,
          ),
        ),
        const SizedBox(width: 8),
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? Border.all(color: AppTheme.getBorderColor(context)) : null,
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCompactDropdown('State', _selectedState, _states, Icons.location_on),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactDropdown('Category', _selectedCategory, _categories, Icons.category),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDropdown(String hint, String value, List<String> items, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkHighlight : AppTheme.getBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.getPrimaryAccent(context).withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          dropdownColor: Theme.of(context).cardColor,
          style: TextStyle(color: AppTheme.getTextColor(context)),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Row(
              children: [
                Icon(icon, size: 14, color: AppTheme.getSecondaryTextColor(context)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(fontSize: 12, color: AppTheme.getTextColor(context)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )).toList(),
          onChanged: (value) {
            setState(() {
              if (hint == 'State') _selectedState = value!;
              if (hint == 'Category') _selectedCategory = value!;
              _filterData();
            });
          },
          icon: Icon(Icons.arrow_drop_down, size: 20, color: AppTheme.getSecondaryTextColor(context)),
        ),
      ),
    );
  }

  Widget _buildMarketSummary() {
    if (_filteredData.isEmpty) {
      return const SizedBox.shrink();
    }

    final avgPrice = _filteredData.map((d) => d.modalPrice).reduce((a, b) => a + b) / _filteredData.length;
    final maxPrice = _filteredData.map((r) => r.maxPrice).reduce((a, b) => a > b ? a : b);
    final minPrice = _filteredData.map((r) => r.minPrice).reduce((a, b) => a < b ? a : b);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactSummaryCard('Avg', '₹${avgPrice.toStringAsFixed(0)}', Icons.trending_up, AppTheme.getPrimaryAccent(context)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCompactSummaryCard('High', '₹${maxPrice.toStringAsFixed(0)}', Icons.arrow_upward, AppTheme.success),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCompactSummaryCard('Low', '₹${minPrice.toStringAsFixed(0)}', Icons.arrow_downward, AppTheme.error),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSummaryCard(String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? Border.all(color: color.withOpacity(0.3)) : null,
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 45,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? Border.all(color: AppTheme.getBorderColor(context)) : null,
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.getTabLabelColor(context),
        unselectedLabelColor: AppTheme.getTabUnselectedLabelColor(context),
        indicator: BoxDecoration(
          color: AppTheme.getTabIndicatorColor(context),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        tabs: const [
          Tab(text: 'All'),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: locationGroups.length,
        itemBuilder: (context, index) {
          final location = locationGroups.keys.elementAt(index);
          final products = locationGroups[location]!;
          final avgPrice = products.map((p) => p.modalPrice).reduce((a, b) => a + b) / products.length;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isDark ? BorderSide(color: AppTheme.getBorderColor(context)) : BorderSide.none,
            ),
            color: Theme.of(context).cardColor,
            child: ExpansionTile(
              shape: const RoundedRectangleBorder(side: BorderSide.none),
              collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
              iconColor: AppTheme.getPrimaryAccent(context),
              collapsedIconColor: AppTheme.getSecondaryTextColor(context),
              title: Text(
                location,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              subtitle: Text(
                '${products.length} products • Avg: ₹${avgPrice.toStringAsFixed(0)}',
                style: TextStyle(color: AppTheme.getSecondaryTextColor(context), fontSize: 12),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    children: products.map((product) => _buildProductCard(product)).toList(),
                  ),
                ),
              ],
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
            color: AppTheme.getSecondaryTextColor(context).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.getSecondaryTextColor(context).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(MarketRate data) {
    final priceChange = data.maxPrice - data.minPrice;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? Border.all(color: AppTheme.getBorderColor(context)) : null,
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToCommodityDetail(data),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.getIconBackgroundColor(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getProductIcon(data.productName),
                    color: AppTheme.getPrimaryAccent(context),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: AppTheme.getSecondaryTextColor(context)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${data.market}, ${data.state}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.getSecondaryTextColor(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${data.modalPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.getPrimaryAccent(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: priceChange >= 0 ? AppTheme.success.withOpacity(0.1) : AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '±₹${priceChange.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: priceChange >= 0 ? AppTheme.success : AppTheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.getSecondaryTextColor(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToCommodityDetail(MarketRate commodity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => APMCCommodityDetailPage(marketRate: commodity),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark ? BorderSide(color: AppTheme.getBorderColor(context)) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Analysis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.getPrimaryAccent(context),
              ),
            ),
            const SizedBox(height: 16),
            ...categoryGroups.entries.map((entry) {
              final avgPrice = entry.value.map((e) => e.modalPrice).reduce((a, b) => a + b) / entry.value.length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.getTextColor(context)),
                      ),
                    ),
                    Text(
                      '${entry.value.length} items',
                      style: TextStyle(color: AppTheme.getSecondaryTextColor(context), fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '₹${avgPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getPrimaryAccent(context),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark ? BorderSide(color: AppTheme.getBorderColor(context)) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.getPrimaryAccent(context),
              ),
            ),
            const SizedBox(height: 16),
            ...priceRanges.entries.map((entry) {
              final percentage = _filteredData.isEmpty ? 0.0 : (entry.value / _filteredData.length) * 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(entry.key, style: TextStyle(color: AppTheme.getTextColor(context)))),
                        Text(
                          '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                          style: TextStyle(color: AppTheme.getSecondaryTextColor(context), fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 6,
                        backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.getPrimaryAccent(context)),
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

  Widget _buildMarketActivity() {
    final totalArrivals = _filteredData.fold<int>(0, (sum, item) => sum + item.arrivals);
    final activeMarkets = _filteredData.map((e) => e.market).toSet().length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark ? BorderSide(color: AppTheme.getBorderColor(context)) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Market Activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.getPrimaryAccent(context),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActivityStat('Total Arrivals', '$totalArrivals', Icons.local_shipping),
                ),
                const SizedBox(width: 12),
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
        color: AppTheme.getPrimaryAccent(context).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.getPrimaryAccent(context), size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getPrimaryAccent(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.getSecondaryTextColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshFAB() {
    return FloatingActionButton(
      heroTag: 'apmc_live_refresh_fab',
      onPressed: _refreshData,
      backgroundColor: AppTheme.getPrimaryAccent(context),
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
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: AppTheme.getDividerColor(context),
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
                    color: AppTheme.getIconBackgroundColor(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getProductIcon(data.productName),
                    color: AppTheme.getPrimaryAccent(context),
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
                        style: TextStyle(
                          color: AppTheme.getSecondaryTextColor(context),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${data.district}, ${data.state}',
                        style: TextStyle(
                          color: AppTheme.getSecondaryTextColor(context),
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
            color: AppTheme.getPrimaryAccent(context),
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
              style: TextStyle(
                color: AppTheme.getSecondaryTextColor(context),
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