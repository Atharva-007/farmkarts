import 'package:flutter/material.dart';
import 'dart:async';
import '../../theme/app_theme.dart';
import '../../services/apmc_api_service.dart';
import 'apmc_commodity_detail_page.dart';

class EnhancedAPMCMarketLivePage extends StatefulWidget {
  const EnhancedAPMCMarketLivePage({super.key});

  @override
  State<EnhancedAPMCMarketLivePage> createState() => _EnhancedAPMCMarketLivePageState();
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
    'All States', 'Maharashtra', 'Karnataka', 'Tamil Nadu', 'Gujarat', 
    'Uttar Pradesh', 'Madhya Pradesh', 'Rajasthan', 'Punjab', 'Haryana',
  ];

  final List<String> _cities = [
    'All Cities', 'Mumbai', 'Pune', 'Nashik', 'Bangalore', 'Chennai',
    'Ahmedabad', 'Delhi', 'Kolkata', 'Hyderabad', 'Indore',
  ];

  final List<String> _categories = [
    'All Products', 'Vegetables', 'Fruits', 'Grains & Cereals',
    'Pulses & Legumes', 'Spices & Condiments',
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
      setState(() {
        _isInitialLoading = true;
        _errorMessage = null;
      });

      _marketData = await _apiService.fetchMarketRates();
      _filterData();

      setState(() => _isInitialLoading = false);
    } catch (e) {
      setState(() {
        _isInitialLoading = false;
        _errorMessage = 'Failed to load market data: ${e.toString()}';
      });
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) _refreshData();
    });
  }

  Future<void> _refreshData() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      _marketData = await _apiService.fetchMarketRates();
      _filterData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterData() {
    _filteredData = _marketData.where((item) {
      bool matchesState = _selectedState == 'All States' || 
          item.state == _selectedState;
      bool matchesCity = _selectedCity == 'All Cities' || 
          item.market == _selectedCity;
      bool matchesCategory = _selectedCategory == 'All Products' || 
          item.category == _selectedCategory;
      
      return matchesState && matchesCity && matchesCategory;
    }).toList();
    
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('APMC Live Market Rates'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
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
            child: _isInitialLoading
                ? _buildLoadingWidget()
                : _errorMessage != null
                    ? _buildErrorWidget()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildMarketList(),
                          _buildTrendingList(),
                          _buildFavoritesList(),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'apmc_refresh_fab',
        onPressed: _refreshData,
        backgroundColor: AppTheme.primaryGreen,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 14)));
      }).toList(),
      onChanged: onChanged,
      isExpanded: true,
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryGreen),
          SizedBox(height: 16),
          Text('Loading market rates...'),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
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
    final priceChange = (rate.modalPrice - rate.minPrice) / rate.minPrice * 100;
    final isPositive = priceChange >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToDetail(rate),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.eco,
                      color: AppTheme.primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rate.commodity,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${rate.market}, ${rate.state}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive ? Icons.trending_up : Icons.trending_down,
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPriceInfo('Min', '₹${rate.minPrice.toStringAsFixed(2)}', Colors.orange),
                  _buildPriceInfo('Max', '₹${rate.maxPrice.toStringAsFixed(2)}', Colors.blue),
                  _buildPriceInfo('Modal', '₹${rate.modalPrice.toStringAsFixed(2)}', AppTheme.primaryGreen),
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
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
        ),
      ),
    );
  }

  Widget _buildTrendingList() {
    final trending = _filteredData.where((r) => 
      ((r.modalPrice - r.minPrice) / r.minPrice * 100) > 5
    ).toList();

    if (trending.isEmpty) {
      return _buildEmptyState(message: 'No trending commodities');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trending.length,
      itemBuilder: (context, index) => _buildCommodityCard(trending[index]),
    );
  }

  Widget _buildFavoritesList() {
    return _buildEmptyState(message: 'No favorites yet');
  }

  Widget _buildEmptyState({String message = 'No data available'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
