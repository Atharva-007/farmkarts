import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../theme/app_theme.dart';
import '../services/apmc_api_service.dart';

class EnhancedMarketTicker extends StatefulWidget {
  final int maxItems;
  final Duration scrollDuration;
  final bool showTrends;
  final VoidCallback? onTap;

  const EnhancedMarketTicker({
    super.key,
    this.maxItems = 10,
    this.scrollDuration = const Duration(seconds: 30),
    this.showTrends = true,
    this.onTap,
  });

  @override
  State<EnhancedMarketTicker> createState() => _EnhancedMarketTickerState();
}

class _EnhancedMarketTickerState extends State<EnhancedMarketTicker>
    with TickerProviderStateMixin {
  late AnimationController _scrollController;
  late AnimationController _fadeController;
  late Timer _refreshTimer;
  late APMCApiService _apiService;

  List<MarketRate> _marketRates = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController = AnimationController(
      duration: widget.scrollDuration,
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _apiService = APMCApiService();

    _loadMarketData();
    _startAutoRefresh();
    _startScrolling();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    _refreshTimer.cancel();
    super.dispose();
  }

  Future<void> _loadMarketData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final rates = await _apiService.fetchMarketRates();
      
      // Select top trending items
      final selectedRates = rates.take(widget.maxItems).toList();
      
      setState(() {
        _marketRates = selectedRates;
        _isLoading = false;
      });

      _fadeController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (mounted) {
        _loadMarketData();
      }
    });
  }

  void _startScrolling() {
    _scrollController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen.withOpacity(0.1),
            AppTheme.primaryGreen.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_marketRates.isEmpty) {
      return _buildEmptyState();
    }

    return _buildTickerContent();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Loading market data...',
            style: TextStyle(
              color: AppTheme.primaryGreen,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: GestureDetector(
        onTap: _loadMarketData,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.refresh,
              color: Colors.red[600],
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Tap to retry',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No market data available',
        style: TextStyle(
          color: AppTheme.textGrey,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTickerContent() {
    return GestureDetector(
      onTap: widget.onTap,
      child: FadeTransition(
        opacity: _fadeController,
        child: Row(
          children: [
            _buildLiveIndicator(),
            const SizedBox(width: 12),
            Expanded(
              child: _buildScrollingContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Container(
      margin: const EdgeInsets.only(left: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            color: Colors.white,
            size: 6,
          ),
          SizedBox(width: 4),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollingContent() {
    return SizedBox(
      height: 60,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = _calculateTotalWidth();
          
          return AnimatedBuilder(
            animation: _scrollController,
            builder: (context, child) {
              final offset = _scrollController.value * (totalWidth + constraints.maxWidth);
              return Transform.translate(
                offset: Offset(constraints.maxWidth - offset, 0),
                child: child,
              );
            },
            child: Row(
              children: _marketRates
                  .map((rate) => _buildMarketItem(rate))
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  double _calculateTotalWidth() {
    // Approximate width calculation for smooth scrolling
    return _marketRates.length * 180.0;
  }

  Widget _buildMarketItem(MarketRate rate) {
    final priceChange = rate.maxPrice - rate.minPrice;
    final isPositive = priceChange >= 0;
    
    return Container(
      margin: const EdgeInsets.only(right: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getProductIcon(rate.productName),
              color: AppTheme.primaryGreen,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rate.productName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              Row(
                children: [
                  Text(
                    '₹${rate.modalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  if (widget.showTrends) ...[
                    const SizedBox(width: 4),
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: isPositive ? Colors.green : Colors.red,
                      size: 12,
                    ),
                    Text(
                      '${isPositive ? '+' : ''}${priceChange.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ],
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
}

/// Compact market ticker for dashboard
class CompactMarketTicker extends StatelessWidget {
  final VoidCallback? onTap;

  const CompactMarketTicker({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.defaultShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: AppTheme.primaryGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Live Market Rates',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const Spacer(),
                if (onTap != null)
                  GestureDetector(
                    onTap: onTap,
                    child: Text(
                      'View All',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: EnhancedMarketTicker(
              maxItems: 8,
              scrollDuration: const Duration(seconds: 20),
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }
}