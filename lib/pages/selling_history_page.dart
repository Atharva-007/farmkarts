import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../widgets/universal_header.dart';

class SellingHistoryPage extends StatefulWidget {
  const SellingHistoryPage({super.key});

  @override
  State<SellingHistoryPage> createState() => _SellingHistoryPageState();
}

class _SellingHistoryPageState extends State<SellingHistoryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final ProductService _productService = ProductService();

  List<dynamic> _sellingHistory = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadSellingHistory();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSellingHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final history = await _productService.getSellingHistory(user.uid);
      final summary = await _productService.getSellingSummary(user.uid);

      if (mounted) {
        setState(() {
          _sellingHistory = history;
          _summary = summary;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            UniversalHeader(
              title: 'Selling Analytics',
              subtitle: 'Track your performance',
              icon: Icons.analytics_rounded,
              showBackButton: true,
              showProfile: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: _loadSellingHistory,
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: _isLoading
                  ? Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.getPrimaryAccent(context))),
                    )
                  : _errorMessage != null
                      ? _buildErrorState()
                      : Column(
                          children: [
                            _buildSummaryCards(),
                            _buildHistoryList(),
                            const SizedBox(height: 100),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildSummaryCard('Total Sales', '₹${_summary['totalRevenue'] ?? 0}',
              Colors.green, Icons.payments_rounded),
          const SizedBox(width: 12),
          _buildSummaryCard('Orders', '${_summary['totalOrders'] ?? 0}',
              Colors.blue, Icons.shopping_bag_rounded),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, Color color, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppTheme.getBorderColor(context)
                  .withValues(alpha: isDark ? 0.1 : 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title,
                style: TextStyle(
                    color: AppTheme.getSecondaryTextColor(context),
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_sellingHistory.isEmpty) {
      return Center(
          child: Text('No selling history yet',
              style:
                  TextStyle(color: AppTheme.getSecondaryTextColor(context))));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _sellingHistory.length,
      itemBuilder: (context, index) {
        final item = _sellingHistory[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            title: Text(item['productName'] ?? 'Product',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Sold to: ${item['buyerName'] ?? 'Unknown'}'),
            trailing: Text('₹${item['totalAmount']}',
                style: TextStyle(
                    color: AppTheme.getPrimaryAccent(context),
                    fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(child: Text('Error: $_errorMessage'));
  }
}
