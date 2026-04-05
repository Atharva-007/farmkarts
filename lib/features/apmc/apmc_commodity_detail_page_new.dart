import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../services/apmc_api_service.dart';
import '../../utils/toast_helper.dart';

class APMCCommodityDetailPage extends StatefulWidget {
  final MarketRate commodity;

  const APMCCommodityDetailPage({
    super.key,
    required this.commodity,
  });

  @override
  State<APMCCommodityDetailPage> createState() =>
      _APMCCommodityDetailPageState();
}

class _APMCCommodityDetailPageState extends State<APMCCommodityDetailPage> {
  final APMCApiService _apiService = APMCApiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedState;
  String? _selectedCity;
  bool _isLoading = true;
  bool _isTracking = false;

  List<String> _states = [];
  List<String> _cities = [];
  List<MarketRate> _commodityData = [];
  List<MarketRate> _filteredData = [];

  @override
  void initState() {
    super.initState();
    _loadCommodityDetails();
    _checkIfTracking();
    _saveHistoryToMyData();
  }

  Future<void> _saveHistoryToMyData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Save current price point to user's history for predictions
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('user_commodity_history')
          .add({
        'commodityName': widget.commodity.productName,
        'price': widget.commodity.modalPrice,
        'date': Timestamp.fromDate(widget.commodity.priceDate),
        'market': widget.commodity.market,
        'state': widget.commodity.state,
        'unit': widget.commodity.unit,
        'variety': widget.commodity.variety,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // print('Error auto-saving history: $e');
    }
  }

  Future<void> _checkIfTracking() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tracked_commodities')
          .doc(widget.commodity.productName.toLowerCase())
          .get();

      if (mounted) {
        setState(() {
          _isTracking = doc.exists;
        });
      }
    } catch (e) {
      // print('Error checking tracking status: $e');
    }
  }

  Future<void> _toggleTracking() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ToastHelper.showError(context, 'Please login to track commodities');
      return;
    }

    setState(() => _isTracking = !_isTracking);

    try {
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tracked_commodities')
          .doc(widget.commodity.productName.toLowerCase());

      if (_isTracking) {
        await docRef.set({
          'commodityName': widget.commodity.productName,
          'category': widget.commodity.category,
          'trackedAt': FieldValue.serverTimestamp(),
          'lastPrice': widget.commodity.modalPrice,
          'unit': widget.commodity.unit,
          // Save a snapshot of history for predictions
          'priceHistory':
              _commodityData.take(10).map((e) => e.toJson()).toList(),
        });
        if (mounted)
          ToastHelper.showSuccess(
              context, 'Now tracking ${widget.commodity.productName}');
      } else {
        await docRef.delete();
        if (mounted)
          ToastHelper.showInfo(
              context, 'Stopped tracking ${widget.commodity.productName}');
      }
    } catch (e) {
      setState(() => _isTracking = !_isTracking);
      if (mounted)
        ToastHelper.showError(context, 'Failed to update tracking: $e');
    }
  }

  Future<void> _loadCommodityDetails() async {
    setState(() => _isLoading = true);

    try {
      // Fetch all data for this commodity
      final allData = await _apiService.fetchMarketRates();

      _commodityData = allData
          .where((rate) =>
              rate.productName.toLowerCase() ==
              widget.commodity.productName.toLowerCase())
          .toList();

      // Extract unique states and cities
      _states = _commodityData.map((rate) => rate.state).toSet().toList()
        ..sort();

      _filteredData = _commodityData;

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ToastHelper.showError(context, 'Error loading details: $e');
      }
    }
  }

  void _filterData() {
    setState(() {
      _filteredData = _commodityData.where((rate) {
        final stateMatch =
            _selectedState == null || rate.state == _selectedState;
        final cityMatch = _selectedCity == null || rate.market == _selectedCity;
        return stateMatch && cityMatch;
      }).toList();
    });
  }

  void _onStateChanged(String? state) {
    setState(() {
      _selectedState = state;
      _selectedCity = null;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _buildQuickSummaryHeader(),
            _buildCompactFilters(),
            _buildSummaryCards(),
            _buildPriceHistoryDropdown(),
            _buildProductQualityDropdown(),
            _buildMarketInsights(),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppTheme.getPrimaryAccent(context),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.commodity.productName,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_isTracking ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.white),
          onPressed: _toggleTracking,
          tooltip: 'Track this Commodity',
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadCommodityDetails,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildQuickSummaryHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.getPrimaryAccent(context).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppTheme.getPrimaryAccent(context).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.getPrimaryAccent(context),
              child: const Icon(Icons.analytics, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Market Pulse',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  Text(
                    'Real-time data from ${_filteredData.length} active markets',
                    style: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactFilters() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isDark
              ? Border.all(color: AppTheme.getBorderColor(context))
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildCompactDropdown(
                hint: 'State',
                value: _selectedState,
                items: _states,
                onChanged: _onStateChanged,
                icon: Icons.map,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactDropdown(
                hint: 'Market',
                value: _selectedCity,
                items: _cities,
                onChanged: (city) {
                  setState(() {
                    _selectedCity = city;
                    _filterData();
                  });
                },
                icon: Icons.store,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: enabled
            ? (isDark ? AppTheme.darkHighlight : Colors.grey.shade50)
            : (isDark ? Colors.black26 : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.getPrimaryAccent(context).withValues(alpha: 0.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: Theme.of(context).cardColor,
          hint: Row(
            children: [
              Icon(icon,
                  size: 14, color: AppTheme.getSecondaryTextColor(context)),
              const SizedBox(width: 6),
              Text(hint,
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.getSecondaryTextColor(context))),
            ],
          ),
          isExpanded: true,
          items: [
            DropdownMenuItem(
              value: null,
              child: Text('All $hint', style: const TextStyle(fontSize: 12)),
            ),
            ...items.map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
          ],
          onChanged: enabled ? onChanged : null,
          icon: Icon(
            Icons.arrow_drop_down,
            size: 18,
            color: enabled ? AppTheme.getPrimaryAccent(context) : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_filteredData.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    final avgPrice =
        _filteredData.map((r) => r.modalPrice).reduce((a, b) => a + b) /
            _filteredData.length;
    final maxPrice =
        _filteredData.map((r) => r.maxPrice).reduce((a, b) => a > b ? a : b);
    final minPrice =
        _filteredData.map((r) => r.minPrice).reduce((a, b) => a < b ? a : b);

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildStatBox('Avg Price', '₹${avgPrice.toStringAsFixed(0)}',
                AppTheme.getPrimaryAccent(context)),
            const SizedBox(width: 10),
            _buildStatBox(
                'High', '₹${maxPrice.toStringAsFixed(0)}', AppTheme.success),
            const SizedBox(width: 10),
            _buildStatBox(
                'Low', '₹${minPrice.toStringAsFixed(0)}', AppTheme.error),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceHistoryDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isDark
              ? Border.all(color: AppTheme.getBorderColor(context))
              : null,
        ),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          title: const Text('Price History & Trends',
              style: TextStyle(fontWeight: FontWeight.bold)),
          leading:
              Icon(Icons.show_chart, color: AppTheme.getPrimaryAccent(context)),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: _buildChart(),
                  ),
                  const SizedBox(height: 16),
                  _buildHistoryTable(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    final priceHistory = <DateTime, double>{};
    for (var rate in _filteredData) {
      final date = DateTime(
          rate.priceDate.year, rate.priceDate.month, rate.priceDate.day);
      priceHistory[date] = (priceHistory[date] ?? 0) + rate.modalPrice;
    }

    final sortedDates = priceHistory.keys.toList()..sort();
    final spots = <FlSpot>[];
    for (var i = 0; i < sortedDates.length; i++) {
      spots.add(FlSpot(i.toDouble(), priceHistory[sortedDates[i]]!));
    }

    if (spots.isEmpty) return const Center(child: Text('No history data'));

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.getPrimaryAccent(context),
            barWidth: 3,
            belowBarData: BarAreaData(
                show: true,
                color:
                    AppTheme.getPrimaryAccent(context).withValues(alpha: 0.1)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTable() {
    return Column(
      children: _filteredData
          .take(5)
          .map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDate(e.priceDate),
                        style: const TextStyle(fontSize: 12)),
                    Text('₹${e.modalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildProductQualityDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isDark
              ? Border.all(color: AppTheme.getBorderColor(context))
              : null,
        ),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          title: const Text('Product Quality Parameters',
              style: TextStyle(fontWeight: FontWeight.bold)),
          leading: Icon(Icons.verified_user, color: AppTheme.success),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildQualityRow('Variety', widget.commodity.variety),
                  _buildQualityRow('Grade', widget.commodity.grade),
                  _buildQualityRow('Standard moisture', '12% - 14%'),
                  _buildQualityRow('Foreign Matter', '< 1%'),
                  _buildQualityRow('Broken Grains', '< 2%'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(
                                'Quality parameters may vary by market and arrival date.',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.amber.shade900))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: AppTheme.getSecondaryTextColor(context),
                  fontSize: 13)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMarketInsights() {
    if (_filteredData.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    final totalArrivals =
        _filteredData.fold<int>(0, (sum, rate) => sum + rate.arrivals);
    final uniqueStates = _filteredData.map((r) => r.state).toSet().length;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Market Insights',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context))),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildInsightTile('Arrivals', '$totalArrivals Q',
                    Icons.local_shipping, Colors.blue),
                const SizedBox(width: 16),
                _buildInsightTile(
                    'States', '$uniqueStates active', Icons.map, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightTile(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.getSecondaryTextColor(context))),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
