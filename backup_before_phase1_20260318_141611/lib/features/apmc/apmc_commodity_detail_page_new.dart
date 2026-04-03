import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../services/apmc_api_service.dart';

class APMCCommodityDetailPage extends StatefulWidget {
  final MarketRate commodity;

  const APMCCommodityDetailPage({
    super.key,
    required this.commodity,
  });

  @override
  State<APMCCommodityDetailPage> createState() => _APMCCommodityDetailPageState();
}

class _APMCCommodityDetailPageState extends State<APMCCommodityDetailPage> {
  final APMCApiService _apiService = APMCApiService();
  
  String? _selectedState;
  String? _selectedCity;
  bool _isLoading = true;
  
  List<String> _states = [];
  List<String> _cities = [];
  List<MarketRate> _commodityData = [];
  List<MarketRate> _filteredData = [];

  @override
  void initState() {
    super.initState();
    _loadCommodityDetails();
  }

  Future<void> _loadCommodityDetails() async {
    setState(() => _isLoading = true);
    
    try {
      // Fetch all data for this commodity
      final allData = await _apiService.fetchMarketRates();
      
      _commodityData = allData.where((rate) => 
        rate.productName.toLowerCase() == widget.commodity.productName.toLowerCase()
      ).toList();
      
      // Extract unique states and cities
      _states = _commodityData
          .map((rate) => rate.state)
          .toSet()
          .toList()
        ..sort();
      
      _filteredData = _commodityData;
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading details: $e')),
        );
      }
    }
  }

  void _filterData() {
    setState(() {
      _filteredData = _commodityData.where((rate) {
        final stateMatch = _selectedState == null || rate.state == _selectedState;
        final cityMatch = _selectedCity == null || rate.market == _selectedCity;
        return stateMatch && cityMatch;
      }).toList();
    });
  }

  void _onStateChanged(String? state) {
    setState(() {
      _selectedState = state;
      _selectedCity = null;
      
      // Update cities based on selected state
      if (state != null) {
        _cities = _commodityData
            .where((rate) => rate.state == state)
            .map((rate) => rate.market)
            .toSet()
            .toList()
          ..sort();
      } else {
        _cities = [];
      }
      
      _filterData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _buildDistrictAPMCSection(),
            _buildCompactFilters(),
            _buildSummaryCards(),
            _buildPriceHistoryChart(),
            _buildMarketInsights(),
            _buildPriceList(),
          ],
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppTheme.primaryGreen,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.commodity.productName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGreen,
                AppTheme.primaryGreen.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadCommodityDetails,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildDistrictAPMCSection() {
    if (_filteredData.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // Group by district
    final districtGroups = <String, List<MarketRate>>{};
    for (var rate in _filteredData) {
      final key = '${rate.district}, ${rate.state}';
      districtGroups[key] = (districtGroups[key] ?? [])..add(rate);
    }

    // Get top 5 districts by market count
    final topDistricts = districtGroups.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final displayDistricts = topDistricts.take(5).toList();

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryGreen, Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_city,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'District APMC Markets',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Top ${displayDistricts.length} districts by market coverage',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...displayDistricts.map((entry) {
              final district = entry.key;
              final markets = entry.value;
              final avgPrice = markets.map((m) => m.modalPrice).reduce((a, b) => a + b) / markets.length;
              final minPrice = markets.map((m) => m.minPrice).reduce((a, b) => a < b ? a : b);
              final maxPrice = markets.map((m) => m.maxPrice).reduce((a, b) => a > b ? a : b);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            district,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${markets.length} markets',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDistrictPriceTag('Avg', avgPrice, Colors.white),
                        _buildDistrictPriceTag('Min', minPrice, Colors.white70),
                        _buildDistrictPriceTag('Max', maxPrice, Colors.white70),
                      ],
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

  Widget _buildDistrictPriceTag(String label, double price, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 10,
          ),
        ),
        Text(
          '₹${price.toStringAsFixed(0)}',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactFilters() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildCompactDropdown(
                hint: 'All States',
                value: _selectedState,
                items: _states,
                onChanged: _onStateChanged,
                icon: Icons.location_on,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactDropdown(
                hint: 'All Cities',
                value: _selectedCity,
                items: _cities,
                onChanged: (city) {
                  setState(() {
                    _selectedCity = city;
                    _filterData();
                  });
                },
                icon: Icons.location_city,
                enabled: _selectedState != null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: enabled ? AppTheme.backgroundLight : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.textGrey),
              const SizedBox(width: 8),
              Text(hint, style: TextStyle(fontSize: 13, color: AppTheme.textGrey)),
            ],
          ),
          isExpanded: true,
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(hint, style: const TextStyle(fontSize: 13)),
            ),
            ...items.map((item) => DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            )),
          ],
          onChanged: enabled ? onChanged : null,
          icon: Icon(
            Icons.arrow_drop_down,
            color: enabled ? AppTheme.primaryGreen : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_filteredData.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final avgPrice = _filteredData.map((r) => r.modalPrice).reduce((a, b) => a + b) / _filteredData.length;
    final maxPrice = _filteredData.map((r) => r.maxPrice).reduce((a, b) => a > b ? a : b);
    final minPrice = _filteredData.map((r) => r.minPrice).reduce((a, b) => a < b ? a : b);

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Avg Price',
                '₹${avgPrice.toStringAsFixed(0)}',
                Icons.trending_up,
                AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Highest',
                '₹${maxPrice.toStringAsFixed(0)}',
                Icons.arrow_upward,
                AppTheme.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Lowest',
                '₹${minPrice.toStringAsFixed(0)}',
                Icons.arrow_downward,
                AppTheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceHistoryChart() {
    if (_filteredData.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // Group data by date and calculate average
    final priceHistory = <DateTime, double>{};
    for (var rate in _filteredData) {
      final date = DateTime(rate.priceDate.year, rate.priceDate.month, rate.priceDate.day);
      if (priceHistory.containsKey(date)) {
        priceHistory[date] = (priceHistory[date]! + rate.modalPrice) / 2;
      } else {
        priceHistory[date] = rate.modalPrice;
      }
    }

    final sortedDates = priceHistory.keys.toList()..sort();
    final last30Days = sortedDates.length > 30 ? sortedDates.sublist(sortedDates.length - 30) : sortedDates;

    if (last30Days.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < last30Days.length; i++) {
      spots.add(FlSpot(i.toDouble(), priceHistory[last30Days[i]]!));
    }

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) * 0.95;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.05;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: AppTheme.primaryGreen, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Price History (Last 30 Days)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY - minY) / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '₹${value.toInt()}',
                            style: const TextStyle(fontSize: 10, color: AppTheme.textGrey),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: last30Days.length / 5,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < last30Days.length) {
                            final date = last30Days[value.toInt()];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${date.day}/${date.month}',
                                style: const TextStyle(fontSize: 10, color: AppTheme.textGrey),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (last30Days.length - 1).toDouble(),
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppTheme.primaryGreen,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: AppTheme.primaryGreen,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildPriceTrend(spots),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceTrend(List<FlSpot> spots) {
    if (spots.length < 2) return const SizedBox();

    final firstPrice = spots.first.y;
    final lastPrice = spots.last.y;
    final change = lastPrice - firstPrice;
    final percentChange = (change / firstPrice) * 100;
    final isPositive = change >= 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isPositive ? AppTheme.success : AppTheme.error).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: isPositive ? AppTheme.success : AppTheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${isPositive ? '+' : ''}₹${change.toStringAsFixed(0)} (${percentChange.toStringAsFixed(1)}%)',
            style: TextStyle(
              color: isPositive ? AppTheme.success : AppTheme.error,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            'vs 30 days ago',
            style: TextStyle(
              color: AppTheme.textGrey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketInsights() {
    if (_filteredData.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final totalMarkets = _filteredData.length;
    final totalArrivals = _filteredData.fold<int>(0, (sum, rate) => sum + rate.arrivals);
    final avgArrivals = totalArrivals / totalMarkets;
    final uniqueStates = _filteredData.map((r) => r.state).toSet().length;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: AppTheme.primaryGreen, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Market Insights',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInsightCard(
                    'Markets',
                    totalMarkets.toString(),
                    Icons.store,
                    AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInsightCard(
                    'States',
                    uniqueStates.toString(),
                    Icons.map,
                    AppTheme.accentOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInsightCard(
                    'Total Arrivals',
                    '${totalArrivals} Q',
                    Icons.local_shipping,
                    AppTheme.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInsightCard(
                    'Avg/Market',
                    '${avgArrivals.toStringAsFixed(0)} Q',
                    Icons.analytics,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceList() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: _filteredData.isEmpty
          ? SliverToBoxAdapter(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No data available for selected filters',
                      style: TextStyle(color: AppTheme.textGrey),
                    ),
                  ],
                ),
              ),
            )
          : SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final rate = _filteredData[index];
                  return _buildPriceCard(rate);
                },
                childCount: _filteredData.length,
              ),
            ),
    );
  }

  Widget _buildPriceCard(MarketRate rate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: AppTheme.primaryGreen),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  rate.market,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rate.state,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPriceDetail('Modal', rate.modalPrice, AppTheme.primaryGreen),
              _buildPriceDetail('Min', rate.minPrice, AppTheme.error),
              _buildPriceDetail('Max', rate.maxPrice, AppTheme.success),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 12, color: AppTheme.textGrey),
              const SizedBox(width: 4),
              Text(
                'Updated: ${_formatDate(rate.priceDate)}',
                style: TextStyle(fontSize: 11, color: AppTheme.textGrey),
              ),
              const Spacer(),
              Text(
                '${rate.arrivals.toStringAsFixed(0)} Quintal',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDetail(String label, double price, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textGrey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${price.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
