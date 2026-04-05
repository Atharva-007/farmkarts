import 'package:flutter/material.dart';
import 'dart:async';
import '../../theme/app_theme.dart';
import '../../services/apmc_api_service.dart';
import 'apmc_commodity_detail_page.dart';

class EnhancedAPMCMarketLivePage extends StatefulWidget {
  const EnhancedAPMCMarketLivePage({super.key});

  @override
  State<EnhancedAPMCMarketLivePage> createState() =>
      _EnhancedAPMCMarketLivePageState();
}

class _EnhancedAPMCMarketLivePageState extends State<EnhancedAPMCMarketLivePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late Timer _refreshTimer;
  late APMCApiService _apiService;

  String _selectedState = 'All States';
  String _selectedCity = 'All Cities';
  String _selectedCategory = 'All Products';
  bool _isLoading = false;
  bool _isInitialLoading = true;
  String? _errorMessage;

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
  ];

  final List<String> _categories = [
    'All Products',
    'Vegetables',
    'Fruits',
    'Grains & Cereals',
    'Pulses & Legumes',
    'Spices & Condiments',
  ];

  List<MarketRate> _marketData = [];
  List<MarketRate> _filteredData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _apiService = APMCApiService();

    _initializeData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      if (mounted) {
        setState(() {
          _isInitialLoading = true;
          _errorMessage = null;
        });
      }

      _marketData = await _apiService.fetchMarketRates();
      _filterData();

      if (mounted) setState(() => _isInitialLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _errorMessage = 'Failed to load market data: ${e.toString()}';
        });
      }
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) _refreshData();
    });
  }

  Future<void> _refreshData() async {
    if (_isLoading) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      _marketData = await _apiService.fetchMarketRates();
      _filterData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to refresh: $e'),
              backgroundColor: AppTheme.getErrorColor(context)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterData() {
    _filteredData = _marketData.where((item) {
      bool matchesState =
          _selectedState == 'All States' || item.state == _selectedState;
      bool matchesCity =
          _selectedCity == 'All Cities' || item.market == _selectedCity;
      bool matchesCategory = _selectedCategory == 'All Products' ||
          item.category == _selectedCategory;

      return matchesState && matchesCity && matchesCategory;
    }).toList();

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('APMC Live Market Rates'),
        backgroundColor: AppTheme.getAppBarColor(context),
        foregroundColor: AppTheme.getAppBarTextColor(context),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.getAppBarTextColor(context),
          unselectedLabelColor:
              AppTheme.getAppBarTextColor(context).withValues(alpha: 0.6),
          indicatorColor: AppTheme.getAppBarTextColor(context),
          tabs: const [
            Tab(text: 'All Rates', icon: Icon(Icons.list, size: 18)),
            Tab(text: 'Trending', icon: Icon(Icons.trending_up, size: 18)),
            Tab(text: 'Favorites', icon: Icon(Icons.star, size: 18)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isInitialLoading
                  ? _buildLoadingWidget(key: const ValueKey('loading'))
                  : _errorMessage != null
                      ? _buildErrorWidget(key: const ValueKey('error'))
                      : TabBarView(
                          key: const ValueKey('content'),
                          controller: _tabController,
                          children: [
                            _buildMarketList(),
                            _buildTrendingList(),
                            _buildFavoritesList(),
                          ],
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'apmc_refresh_fab',
        onPressed: _refreshData,
        backgroundColor: AppTheme.getPrimaryAccent(context),
        elevation: 4,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
        border: Border(
            bottom: BorderSide(
                color:
                    AppTheme.getBorderColor(context).withValues(alpha: 0.5))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'State',
                  _selectedState,
                  _states,
                  (value) {
                    setState(() {
                      _selectedState = value!;
                      _filterData();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  'City',
                  _selectedCity,
                  _cities,
                  (value) {
                    setState(() {
                      _selectedCity = value!;
                      _filterData();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFilterDropdown(
            'Category',
            _selectedCategory,
            _categories,
            (value) {
              setState(() {
                _selectedCategory = value!;
                _filterData();
              });
            },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: AppTheme.getCardColor(context),
      style: TextStyle(color: AppTheme.getTextColor(context), fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor:
            isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      isExpanded: true,
    );
  }

  Widget _buildLoadingWidget({Key? key}) {
    return Center(
      key: key,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.getPrimaryAccent(context)),
          const SizedBox(height: 16),
          Text('Loading market rates...',
              style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
        ],
      ),
    );
  }

  Widget _buildErrorWidget({Key? key}) {
    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64,
                color: AppTheme.getErrorColor(context).withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, color: AppTheme.getTextColor(context)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeData,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Retry', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.getPrimaryAccent(context),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketList() {
    if (_filteredData.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppTheme.getPrimaryAccent(context),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredData.length,
        itemBuilder: (context, index) {
          return _buildCommodityCard(_filteredData[index]);
        },
      ),
    );
  }

  Widget _buildCommodityCard(MarketRate rate) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceChange = (rate.modalPrice - rate.minPrice) / rate.minPrice * 100;
    final isPositive = priceChange >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDark ? 0 : 2,
      color: AppTheme.getCardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: AppTheme.getBorderColor(context)
                .withValues(alpha: isDark ? 0.1 : 0.5)),
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(rate),
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
                      color: AppTheme.getPrimaryAccent(context)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.eco_rounded,
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
                          rate.productName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getTextColor(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                size: 14,
                                color: AppTheme.getSecondaryTextColor(context)
                                    .withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${rate.market}, ${rate.state}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      AppTheme.getSecondaryTextColor(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 14,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${priceChange.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isPositive ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPriceInfo('Min', '₹${rate.minPrice.toStringAsFixed(0)}',
                      Colors.orange),
                  const SizedBox(width: 12),
                  _buildPriceInfo('Max', '₹${rate.maxPrice.toStringAsFixed(0)}',
                      Colors.blue),
                  const SizedBox(width: 12),
                  _buildPriceInfo(
                      'Modal',
                      '₹${rate.modalPrice.toStringAsFixed(0)}',
                      AppTheme.primaryGreen),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceInfo(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.getSecondaryTextColor(context)
                    .withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingList() {
    final trending = _filteredData
        .where((r) => ((r.modalPrice - r.minPrice) / r.minPrice * 100) > 5)
        .toList();

    if (trending.isEmpty) {
      return _buildEmptyState(message: 'No significant price trends today');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trending.length,
      itemBuilder: (context, index) => _buildCommodityCard(trending[index]),
    );
  }

  Widget _buildFavoritesList() {
    return _buildEmptyState(message: 'Save products to track them here');
  }

  Widget _buildEmptyState({String message = 'No market data found'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined,
              size: 80,
              color: AppTheme.getSecondaryTextColor(context)
                  .withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
                fontSize: 16,
                color: AppTheme.getSecondaryTextColor(context),
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(MarketRate rate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => APMCCommodityDetailPage(marketRate: rate),
      ),
    );
  }
}
