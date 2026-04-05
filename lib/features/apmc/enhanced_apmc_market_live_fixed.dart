import 'package:flutter/material.dart';
import 'dart:async';
import '../../theme/app_theme.dart';
import '../../widgets/universal_drawer.dart';
import '../../widgets/universal_header.dart';
import '../../services/apmc_api_service.dart';
import '../../utils/responsive_helper.dart';
import 'apmc_commodity_detail_page.dart';

class EnhancedAPMCMarketLiveFixed extends StatefulWidget {
  const EnhancedAPMCMarketLiveFixed({super.key});

  @override
  State<EnhancedAPMCMarketLiveFixed> createState() =>
      _EnhancedAPMCMarketLiveFixedState();
}

class _EnhancedAPMCMarketLiveFixedState
    extends State<EnhancedAPMCMarketLiveFixed> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  final APMCApiService _apiService = APMCApiService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  String _selectedState = 'All States';
  String _selectedDistrict = 'All Districts';
  String _selectedCategory = 'All Categories';
  String _searchQuery = '';
  String _sortBy = 'Recommended';

  bool _isLoading = true;
  String? _errorMessage;

  List<MarketRate> _filteredData = [];

  final List<String> _availableStates = APMCApiService.getAvailableStates();
  final List<String> _availableCategories =
      APMCApiService.getAvailableCategories();
  List<String> _availableDistricts = ['All Districts'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _syncDistricts(initial: true);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// PROPER SYNC LOGIC: Updates district list and resets selection if needed
  void _syncDistricts({bool initial = false}) {
    final districts = APMCApiService.getDistrictsForState(_selectedState);
    setState(() {
      _availableDistricts = districts;
      if (!districts.contains(_selectedDistrict)) {
        _selectedDistrict = 'All Districts';
      }
    });
    if (!initial) _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.fetchMarketRates(
        state: _selectedState,
        district: _selectedDistrict,
        query: _searchQuery,
        category: _selectedCategory,
      );

      if (!mounted) return;

      // Apply Sorting
      _applySorting(data);

      setState(() {
        _filteredData = data;
        _isLoading = false;
      });

      _animationController.reset();
      _animationController.forward();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Synchronisation error. Please retry.";
        });
      }
    }
  }

  void _applySorting(List<MarketRate> data) {
    switch (_sortBy) {
      case 'Price: High to Low':
        data.sort((a, b) => b.modalPrice.compareTo(a.modalPrice));
        break;
      case 'Price: Low to High':
        data.sort((a, b) => a.modalPrice.compareTo(b.modalPrice));
        break;
      case 'Quantity (Arrivals)':
        data.sort((a, b) => b.arrivals.compareTo(a.arrivals));
        break;
      case 'Quality (High)':
        data.sort((a, b) => b.qualityScore.compareTo(a.qualityScore));
        break;
      case 'Most Selling':
        data.sort((a, b) => (b.arrivals * 0.8).compareTo(a.arrivals * 0.8));
        break;
      default:
        break;
    }
  }

  void _onSearchChanged(String v) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = v;
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final sidePadding =
        ResponsiveHelper.getScreenPadding(context).horizontal / 2;

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      drawer: const UniversalDrawer(currentPage: 'apmc'),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          UniversalHeader(
            title: 'APMC Market',
            subtitle: 'Nation Wide Goods Place',
            icon: Icons.analytics_rounded,
            showProfile: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _loadData,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Market Rates'),
                Tab(text: 'Regional Trends'),
                Tab(text: 'Deep Analysis'),
                Tab(text: 'Price Alerts'),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _buildEnterpriseFilterHub(context),
          ),
          if (_isLoading)
            _buildLoadingState()
          else if (_errorMessage != null)
            _buildErrorState()
          else
            _buildDataContent(sidePadding, isDesktop),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildEnterpriseFilterHub(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
        boxShadow: AppTheme.getPremiumShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Search & Sorting
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.getLayerColor(context),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: TextStyle(
                        color: AppTheme.getTextColor(context), fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search commodities...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildSortMenu(),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Synchronized Location Selectors
          Row(
            children: [
              Expanded(
                child: _buildCompactRegionSelector(
                    'STATE', _selectedState, _availableStates, (v) {
                  setState(() => _selectedState = v!);
                  _syncDistricts();
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactRegionSelector(
                    'DISTRICT', _selectedDistrict, _availableDistricts, (v) {
                  setState(() => _selectedDistrict = v!);
                  _loadData();
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 3: Category Quick-Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _availableCategories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat == 'All Categories' ? 'All' : cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = cat);
                        _loadData();
                      }
                    },
                    selectedColor: AppTheme.getPrimaryAccent(context)
                        .withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppTheme.getPrimaryAccent(context)
                          : AppTheme.getSecondaryTextColor(context),
                    ),
                    backgroundColor: AppTheme.getLayerColor(context),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.getPrimaryAccent(context)
                          : Colors.transparent,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortMenu() {
    return PopupMenuButton<String>(
      onSelected: (v) {
        setState(() => _sortBy = v);
        _loadData();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => [
        'Recommended',
        'Price: High to Low',
        'Price: Low to High',
        'Quantity (Arrivals)',
        'Quality (High)',
        'Most Selling'
      ]
          .map((s) => PopupMenuItem(
              value: s,
              child: Text(s,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600))))
          .toList(),
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: AppTheme.getPrimaryAccent(context).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.sort_rounded,
            color: AppTheme.getPrimaryAccent(context), size: 22),
      ),
    );
  }

  Widget _buildCompactRegionSelector(String label, String current,
      List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.getLayerColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppTheme.getBorderColor(context).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.getSecondaryTextColor(context))),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isDense: true,
              isExpanded: true,
              value: items.contains(current) ? current : items.first,
              items: items
                  .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold))))
                  .toList(),
              onChanged: onChanged,
              icon: Icon(Icons.arrow_drop_down_rounded,
                  size: 18, color: AppTheme.getPrimaryAccent(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SliverFillRemaining(
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_errorMessage!,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextButton(onPressed: _loadData, child: const Text('RETRY')),
          ],
        ),
      ),
    );
  }

  Widget _buildDataContent(double padding, bool isDesktop) {
    if (_filteredData.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('No data found for this selection.')),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isDesktop ? 2 : 1,
          mainAxisExtent: 135,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final rate = _filteredData[index];
            return FadeTransition(
              opacity: _animationController,
              child: _buildMarketRateCard(rate),
            );
          },
          childCount: _filteredData.length,
        ),
      ),
    );
  }

  Widget _buildMarketRateCard(MarketRate rate) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.getBorderColor(context)),
        boxShadow: AppTheme.getPremiumShadow(context),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => APMCCommodityDetailPage(marketRate: rate),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.getLayerColor(context),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.agriculture_rounded,
                    color: AppTheme.getPrimaryAccent(context), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      rate.productName,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.getTextColor(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${rate.market}, ${rate.state}',
                      style: TextStyle(
                          color: AppTheme.getSecondaryTextColor(context),
                          fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildMiniBadge('Grade ${rate.grade}', Colors.blue),
                        const SizedBox(width: 4),
                        _buildMiniBadge(
                            '${rate.arrivals} ${rate.unit}', Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '₹${rate.modalPrice.toInt()}',
                    style: TextStyle(
                        color: AppTheme.getPrimaryAccent(context),
                        fontWeight: FontWeight.w900,
                        fontSize: 20),
                  ),
                  Text(
                    'per ${rate.unit}',
                    style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context),
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 8, fontWeight: FontWeight.w900)),
    );
  }
}
