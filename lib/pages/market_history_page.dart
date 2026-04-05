import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/universal_drawer.dart';
import '../widgets/universal_header.dart';
import '../widgets/custom_card.dart';

class MarketHistoryPage extends StatefulWidget {
  const MarketHistoryPage({super.key});

  @override
  State<MarketHistoryPage> createState() => _MarketHistoryPageState();
}

class _MarketHistoryPageState extends State<MarketHistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  String _selectedCommodity = 'All';
  List<String> _trackedCommodities = ['All'];

  @override
  void initState() {
    super.initState();
    _loadTrackedList();
  }

  Future<void> _loadTrackedList() async {
    if (_uid.isEmpty) return;

    final snapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('user_commodity_history')
        .get();

    final names = snapshot.docs
        .map((doc) => doc['commodityName'] as String)
        .toSet()
        .toList();
    if (mounted) {
      setState(() {
        _trackedCommodities = ['All', ...names..sort()];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const UniversalDrawer(currentPage: 'history'),
      body: CustomScrollView(
        slivers: [
          const UniversalHeader(
            title: 'Market Trends',
            subtitle: 'Your personal price history',
            icon: Icons.history_edu,
          ),
          SliverToBoxAdapter(
            child: _buildFilterSection(),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _getHistoryStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              final docs = snapshot.data!.docs;
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildVisualTrends(docs),
                    const SizedBox(height: 24),
                    Text(
                      'Historical Records',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...docs.map((doc) => _buildHistoryCard(doc)),
                    const SizedBox(height: 100),
                  ]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getHistoryStream() {
    var query = _firestore
        .collection('users')
        .doc(_uid)
        .collection('user_commodity_history')
        .orderBy('date', descending: true);

    if (_selectedCommodity != 'All') {
      query = query.where('commodityName', isEqualTo: _selectedCommodity);
    }

    return query.snapshots();
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _trackedCommodities.length,
        itemBuilder: (context, index) {
          final name = _trackedCommodities[index];
          final isSelected = _selectedCommodity == name;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(name),
              onSelected: (val) => setState(() => _selectedCommodity = name),
              selectedColor:
                  AppTheme.getPrimaryAccent(context).withValues(alpha: 0.2),
              checkmarkColor: AppTheme.getPrimaryAccent(context),
              labelStyle: TextStyle(
                color: isSelected
                    ? AppTheme.getPrimaryAccent(context)
                    : AppTheme.getSecondaryTextColor(context),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVisualTrends(List<QueryDocumentSnapshot> docs) {
    if (_selectedCommodity == 'All') {
      return const SizedBox.shrink();
    }

    // Prepare data for chart
    final spots = <FlSpot>[];
    final sortedDocs = docs.reversed.toList();
    for (var i = 0; i < sortedDocs.length; i++) {
      final price = (sortedDocs[i]['price'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), price));
    }

    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Momentum',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.getPrimaryAccent(context)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.getPrimaryAccent(context),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.getPrimaryAccent(context)
                          .withValues(alpha: 0.1),
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

  Widget _buildHistoryCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final date = (data['date'] as Timestamp).toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    AppTheme.getPrimaryAccent(context).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inventory_2,
                  color: AppTheme.getPrimaryAccent(context), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['commodityName'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '${data['market']}, ${data['state']}',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.getSecondaryTextColor(context)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${(data['price'] as num).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppTheme.getPrimaryAccent(context),
                  ),
                ),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.getSecondaryTextColor(context)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history,
                size: 64,
                color: AppTheme.getSecondaryTextColor(context)
                    .withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('No market history saved yet'),
            const SizedBox(height: 8),
            Text(
              'Browse commodities in APMC Market to save data',
              style: TextStyle(
                  color: AppTheme.getSecondaryTextColor(context), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
