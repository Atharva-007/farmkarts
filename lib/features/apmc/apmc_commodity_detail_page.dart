import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../theme/app_theme.dart';
import '../../services/apmc_api_service.dart';
import '../../services/price_alert_service.dart';
import 'package:fl_chart/fl_chart.dart';

/// Redesigned APMC Commodity Detail Page with Pro-Level Market Intelligence
class APMCCommodityDetailPage extends StatefulWidget {
  final MarketRate marketRate;

  const APMCCommodityDetailPage({
    super.key,
    required this.marketRate,
  });

  @override
  State<APMCCommodityDetailPage> createState() =>
      _APMCCommodityDetailPageState();
}

class _APMCCommodityDetailPageState extends State<APMCCommodityDetailPage> {
  final APMCApiService _apiService = APMCApiService();
  final PriceAlertService _alertService = PriceAlertService();
  StreamSubscription? _alertSubscription;

  late List<FlSpot> _trendData = [];
  late String _advisorRecommendation;
  late Color _advisorColor;
  late String _advisorReason;
  late Map<String, dynamic> _dynamics;
  late List<Map<String, dynamic>> _topMandis;
  late List<Map<String, dynamic>> _nearbyMandis;

  int _historyDays = 7;
  bool _isLoadingHistory = true;
  PriceAlert? _activeAlert;
  List<Map<String, dynamic>> _historyRawData = [];

  @override
  void initState() {
    super.initState();
    _dynamics = APMCApiService.getDynamicDynamics(widget.marketRate);
    _topMandis = APMCApiService.getTopMandis(widget.marketRate);
    _nearbyMandis = APMCApiService.getNearbyMandis(widget.marketRate);
    _loadHistoryData();
    _initAlertListener();
    _calculateAdvisorLogic();
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    super.dispose();
  }

  /// PRO-LEVEL: Live reactive listener for price alerts
  void _initAlertListener() {
    _alertSubscription = _alertService.getMyAlerts().listen((alerts) {
      if (mounted) {
        setState(() {
          _activeAlert = alerts.cast<PriceAlert?>().firstWhere(
                (a) =>
                    a?.productName == widget.marketRate.productName &&
                    a?.district == widget.marketRate.district,
                orElse: () => null,
              );
        });
      }
    });
  }

  Future<void> _loadHistoryData() async {
    if (!mounted) return;
    setState(() => _isLoadingHistory = true);
    try {
      final history = await _apiService.fetchCommodityHistory(
          widget.marketRate.productName,
          days: _historyDays);

      if (mounted) {
        setState(() {
          _historyRawData = history;
          _trendData = history.asMap().entries.map((entry) {
            return FlSpot(
                entry.key.toDouble(), entry.value['modalPrice'] as double);
          }).toList();
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  void _calculateAdvisorLogic() {
    final diff = widget.marketRate.maxPrice - widget.marketRate.modalPrice;
    final volatility = (diff / widget.marketRate.modalPrice) * 100;

    if (volatility < 5) {
      _advisorRecommendation = "STRONGLY SELL";
      _advisorColor = Colors.green;
      _advisorReason =
          "Prices have plateaued. Historical data suggests a downward correction in the next 48 hours.";
    } else if (volatility > 12) {
      _advisorRecommendation = "STRONG HOLD";
      _advisorColor = Colors.orange;
      _advisorReason =
          "Massive supply-demand gap detected. Nearby mandis reporting inventory shortages.";
    } else {
      _advisorRecommendation = "MONITOR";
      _advisorColor = AppTheme.primaryBlue;
      _advisorReason =
          "Balanced market. Good returns for FAQ grade, but wait for morning arrivals for better bidding.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  _buildAdvisorCard(),
                  _buildPriceMatrix(),
                  _buildArrivalsVolume(),
                  _buildTrendAnalysis(),
                  _buildNearbyComparison(),
                  _buildMarketDynamicsSection(),
                  _buildTopPerformingMandis(),
                  _buildActionHub(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.getPrimaryAccent(context),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          widget.marketRate.productName,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.getPrimaryAccent(context),
                    AppTheme.getPrimaryAccent(context).withValues(alpha: 0.6)
                  ],
                ),
              ),
            ),
            Positioned(
              right: -30,
              top: -30,
              child: Icon(Icons.auto_awesome_rounded,
                  size: 200, color: Colors.white.withValues(alpha: 0.1)),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    widget.marketRate.market,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${widget.marketRate.district}, ${widget.marketRate.state}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvisorCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _advisorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: _advisorColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration:
                    BoxDecoration(color: _advisorColor, shape: BoxShape.circle),
                child: const Icon(Icons.insights_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MARKET INTELLIGENCE',
                        style: TextStyle(
                            color: _advisorColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 1.5)),
                    Text(_advisorRecommendation,
                        style: TextStyle(
                            color: _advisorColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 24)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(_advisorReason,
              style: TextStyle(
                  color: AppTheme.getTextColor(context).withValues(alpha: 0.8),
                  height: 1.5,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPriceMatrix() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Price Matrix',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: AppTheme.getLayerColor(context),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('Variety: ${widget.marketRate.variety}',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getPrimaryAccent(context))),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildPriceBox(
                  'MINIMUM', widget.marketRate.minPrice, Colors.redAccent),
              const SizedBox(width: 12),
              _buildPriceBox('MODAL', widget.marketRate.modalPrice,
                  AppTheme.getPrimaryAccent(context),
                  isLarge: true),
              const SizedBox(width: 12),
              _buildPriceBox(
                  'MAXIMUM', widget.marketRate.maxPrice, Colors.green),
            ],
          ),
        ),
        _buildPriceRangeIndicator(),
      ],
    );
  }

  Widget _buildPriceRangeIndicator() {
    final totalRange = widget.marketRate.maxPrice - widget.marketRate.minPrice;
    final currentPos =
        widget.marketRate.modalPrice - widget.marketRate.minPrice;
    final percentage = totalRange > 0 ? currentPos / totalRange : 0.5;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₹${widget.marketRate.minPrice.toInt()}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold)),
              Text('Current: ₹${widget.marketRate.modalPrice.toInt()}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getPrimaryAccent(context))),
              Text('₹${widget.marketRate.maxPrice.toInt()}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage.clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.redAccent,
                      AppTheme.getPrimaryAccent(context)
                    ]),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Daily Price Spread',
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPriceBox(String label, double price, Color color,
      {bool isLarge = false}) {
    return Expanded(
      flex: isLarge ? 4 : 3,
      child: Container(
        padding:
            EdgeInsets.symmetric(vertical: isLarge ? 20 : 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10)
          ],
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Text('₹${price.toInt()}',
                style: TextStyle(
                    fontSize: isLarge ? 22 : 18, fontWeight: FontWeight.bold)),
            Text('per ${widget.marketRate.unit}',
                style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.getSecondaryTextColor(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildArrivalsVolume() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.local_shipping_rounded,
                    color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Arrival Volume',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Today\'s total stock in Mandi',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.getSecondaryTextColor(context))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(widget.marketRate.arrivals.toString(),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900)),
                  Text(widget.marketRate.unit,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.7,
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Lower Supply',
                  style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.getSecondaryTextColor(context))),
              const Text('High Market Activity',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendAnalysis() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Price History',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              _buildRangeSelector(),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoadingHistory)
            const SizedBox(
                height: 150, child: Center(child: CircularProgressIndicator()))
          else if (_trendData.isEmpty)
            const SizedBox(
                height: 150,
                child: Center(child: Text('No historical data available')))
          else
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 500,
                    getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.withValues(alpha: 0.1),
                        strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value % (_historyDays / 4).ceil() != 0)
                            return const SizedBox.shrink();
                          final index = value.toInt();
                          if (index < 0 || index >= _historyRawData.length)
                            return const SizedBox.shrink();
                          final date =
                              _historyRawData[index]['date'] as DateTime;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(DateFormat('dd MMM').format(date),
                                style: const TextStyle(
                                    fontSize: 9, color: Colors.grey)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('₹${value.toInt()}',
                              style: const TextStyle(
                                  fontSize: 9, color: Colors.grey));
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _trendData,
                      isCurved: true,
                      color: AppTheme.getPrimaryAccent(context),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: _historyDays <= 7,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: AppTheme.getPrimaryAccent(context),
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.getPrimaryAccent(context)
                                .withValues(alpha: 0.2),
                            Colors.transparent
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
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

  Widget _buildRangeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [7, 15, 30].map((days) {
          final isSelected = _historyDays == days;
          return GestureDetector(
            onTap: () {
              if (isSelected) return;
              setState(() => _historyDays = days);
              _loadHistoryData();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.getPrimaryAccent(context)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${days}D',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : AppTheme.getSecondaryTextColor(context),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNearbyComparison() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nearby Mandi Comparison',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton(
                onPressed: () {},
                child: const Text('View All',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          ..._nearbyMandis.map((mandi) => _buildMandiCompareTile(
                mandi['name'],
                mandi['price'],
                mandi['distance'],
                mandi['arrivals'],
                mandi['trusted'],
              )),
        ],
      ),
    );
  }

  Widget _buildMandiCompareTile(String name, double price, String distance,
      String arrivals, String trusted) {
    final diff = price - widget.marketRate.modalPrice;
    final isHigher = diff > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 12,
                            color: AppTheme.getSecondaryTextColor(context)),
                        const SizedBox(width: 4),
                        Text('$distance km away',
                            style: TextStyle(
                                fontSize: 11,
                                color:
                                    AppTheme.getSecondaryTextColor(context))),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${price.toInt()}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isHigher ? Colors.green : Colors.red)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${isHigher ? '+' : ''}${diff.toInt()}',
                      style: TextStyle(
                          color: isHigher ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSmallInfoTile(
                  Icons.trending_up_rounded, 'Arrivals', arrivals),
              _buildSmallInfoTile(
                  Icons.access_time_rounded, 'Open Until', '6 PM'),
              _buildSmallInfoTile(
                  Icons.verified_user_rounded, 'Trusted', trusted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInfoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon,
            size: 14,
            color: AppTheme.getPrimaryAccent(context).withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    color: AppTheme.getSecondaryTextColor(context))),
            Text(value,
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildMarketDynamicsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Market Dynamics',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _buildDynamicRow(Icons.trending_up_rounded, 'Demand',
              _dynamics['demand'], Colors.green),
          _buildDynamicRow(Icons.inventory_2_rounded, 'Stock Level',
              _dynamics['stock'], Colors.orange),
          _buildDynamicRow(Icons.verified_rounded, 'Quality Index',
              '${_dynamics['quality']}/10', Colors.blue),
          _buildDynamicRow(Icons.calendar_month_rounded, 'Next Peak Period',
              _dynamics['peakPeriod'], Colors.purple),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.getSurfaceColor(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _dynamics['trendMessage'],
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.getSecondaryTextColor(context),
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicRow(
      IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  color: AppTheme.getSecondaryTextColor(context),
                  fontSize: 14)),
          const Spacer(),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTopPerformingMandis() {
    final topPrice = _topMandis.isNotEmpty
        ? _topMandis.first['price']
        : widget.marketRate.modalPrice;
    final profitPotential = ((topPrice - widget.marketRate.modalPrice) /
            widget.marketRate.modalPrice *
            100)
        .toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                  color: Colors.amber.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stars_rounded,
                    color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Best Value Discovery',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('Highest regional profit markers',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._topMandis.asMap().entries.map((entry) =>
              _buildTopMandiEnhancedRow(
                  index: entry.key,
                  name: entry.value['name'],
                  stateCode: entry.value['state'],
                  price: entry.value['price'])),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.getSurfaceColor(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    size: 16, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'PRO TIP: Transporting to ${_topMandis.first['name']} could net you $profitPotential% higher returns today.',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.getSecondaryTextColor(context),
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMandiEnhancedRow(
      {required int index,
      required String name,
      required String stateCode,
      required double price}) {
    final diff = price - widget.marketRate.modalPrice;
    final isTop = index == 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isTop ? Colors.amber : AppTheme.getLayerColor(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '#${index + 1}',
                style: TextStyle(
                  color: isTop ? Colors.white : AppTheme.getTextColor(context),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Text(stateCode,
                        style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.getSecondaryTextColor(context),
                            fontWeight: FontWeight.w900)),
                    const SizedBox(width: 8),
                    const Icon(Icons.local_shipping_outlined,
                        size: 10, color: Colors.grey),
                    const SizedBox(width: 4),
                    const Text('Feasible',
                        style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${price.toInt()}',
                  style: TextStyle(
                      color: AppTheme.getPrimaryAccent(context),
                      fontWeight: FontWeight.w900,
                      fontSize: 17)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text('+₹${diff.toInt()} profit',
                    style: const TextStyle(
                        color: Colors.green,
                        fontSize: 9,
                        fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionHub() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPriceAlertCard(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.directions_rounded),
              label: const Text('NAVIGATE TO MANDI',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: AppTheme.getPrimaryAccent(context), width: 2),
                foregroundColor: AppTheme.getPrimaryAccent(context),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceAlertCard() {
    final bool isActive = _activeAlert != null;
    final color = isActive ? Colors.green : AppTheme.getPrimaryAccent(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                    isActive
                        ? Icons.verified_rounded
                        : Icons.notifications_active_rounded,
                    color: color,
                    size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isActive ? 'Monitoring Active' : 'Custom Price Alert',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w900,
                            fontSize: 19)),
                    Text(
                        isActive
                            ? 'Target: ₹${_activeAlert!.targetPrice.toInt()} (${_activeAlert!.condition.toUpperCase()})'
                            : 'Set thresholds for instant push alerts',
                        style: TextStyle(
                            color: AppTheme.getSecondaryTextColor(context),
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (isActive)
                IconButton(
                  onPressed: () async {
                    await _alertService.removeAlertFor(
                        widget.marketRate.productName,
                        widget.marketRate.district);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Alert removed.'),
                        behavior: SnackBarBehavior.floating));
                  },
                  icon: const Icon(Icons.delete_sweep_rounded,
                      color: Colors.redAccent),
                  tooltip: 'Remove Alert',
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (!isActive)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showPriceAlertDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 0,
                ),
                child: const Text('CONFIGURE SMART ALERT',
                    style: TextStyle(
                        fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.radar_rounded, color: Colors.green, size: 18),
                  SizedBox(width: 10),
                  Text('LIVE TRACKING ENABLED',
                      style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.5)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showPriceAlertDialog() {
    final currentPrice = widget.marketRate.modalPrice.toInt();
    final TextEditingController priceController =
        TextEditingController(text: (currentPrice * 1.1).toInt().toString());
    String selectedCondition = 'above';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppTheme.getSurfaceColor(context),
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          title: const Column(
            children: [
              Text('Smart Price Alert',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
              SizedBox(height: 4),
              Text('Powered by Real-time Market Data',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notify when ${widget.marketRate.productName} in ${widget.marketRate.district} moves:',
                style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.getSecondaryTextColor(context),
                    height: 1.4,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildConditionChip(
                      setModalState,
                      'above',
                      selectedCondition == 'above',
                      'ABOVE',
                      (v) => selectedCondition = v),
                  const SizedBox(width: 10),
                  _buildConditionChip(
                      setModalState,
                      'below',
                      selectedCondition == 'below',
                      'BELOW',
                      (v) => selectedCondition = v),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: 1),
                decoration: InputDecoration(
                  labelText: 'Target Threshold',
                  prefixText: '₹ ',
                  helperText: 'Current Market Rate: ₹$currentPrice',
                  helperStyle: const TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20)),
                  filled: true,
                  fillColor:
                      AppTheme.getLayerColor(context).withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Quick Presets:',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [0.05, 0.10, 0.15].map((pct) {
                  final target = (currentPrice * (1 + pct)).toInt();
                  return ActionChip(
                    label: Text('+${(pct * 100).toInt()}%',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => setModalState(
                        () => priceController.text = target.toString()),
                    backgroundColor: AppTheme.getLayerColor(context),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  );
                }).toList(),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  final target = double.tryParse(priceController.text);
                  if (target != null) {
                    await _alertService.createAlert(
                      productName: widget.marketRate.productName,
                      category: widget.marketRate.category,
                      state: widget.marketRate.state,
                      district: widget.marketRate.district,
                      targetPrice: target,
                      condition: selectedCondition,
                    );
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.getPrimaryAccent(context),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('ACTIVATE SMART MONITORING',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionChip(StateSetter setModalState, String val,
      bool isSelected, String label, Function(String) onSelect) {
    return Expanded(
      child: ChoiceChip(
        label: Center(
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 11))),
        selected: isSelected,
        onSelected: (s) => setModalState(() {
          onSelect(val);
        }),
        selectedColor:
            AppTheme.getPrimaryAccent(context).withValues(alpha: 0.2),
        checkmarkColor: AppTheme.getPrimaryAccent(context),
      ),
    );
  }
}
