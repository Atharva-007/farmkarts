import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MarketPriceTicker extends StatefulWidget {
  const MarketPriceTicker({super.key});

  @override
  State<MarketPriceTicker> createState() => _MarketPriceTickerState();
}

class _MarketPriceTickerState extends State<MarketPriceTicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late ScrollController _scrollController;

  final List<_MarketPrice> _prices = [
    _MarketPrice('Wheat', 2450, 2.5, true),
    _MarketPrice('Rice', 3200, -1.2, false),
    _MarketPrice('Corn', 1850, 3.8, true),
    _MarketPrice('Soybeans', 4100, 0.5, true),
    _MarketPrice('Cotton', 5200, -2.1, false),
    _MarketPrice('Sugarcane', 280, 1.8, true),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );
    _scrollController = ScrollController();
    _startScrolling();
  }

  void _startScrolling() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        _controller.addListener(() {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_controller.value * maxScroll);
          }
        });
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppConstants.defaultPadding.copyWith(bottom: 8),
            child: Text(
              'Live Market Prices (₹/quintal)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(8),
                boxShadow: AppTheme.defaultShadow,
              ),
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: _prices.length * 100, // Infinite scroll effect
                itemBuilder: (context, index) {
                  final price = _prices[index % _prices.length];
                  return _buildPriceCard(price);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(_MarketPrice price) {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: price.isPositive
            ? AppTheme.success.withOpacity(0.1)
            : AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: price.isPositive
              ? AppTheme.success.withOpacity(0.3)
              : AppTheme.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            price.commodity,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '₹${price.currentPrice}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          Row(
            children: [
              Icon(
                price.isPositive ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: price.isPositive ? AppTheme.success : AppTheme.error,
              ),
              const SizedBox(width: 2),
              Text(
                '${price.isPositive ? '+' : ''}${price.changePercentage.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: price.isPositive ? AppTheme.success : AppTheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarketPrice {
  final String commodity;
  final int currentPrice;
  final double changePercentage;
  final bool isPositive;

  _MarketPrice(
    this.commodity,
    this.currentPrice,
    this.changePercentage,
    this.isPositive,
  );
}