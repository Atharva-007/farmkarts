import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';

class MarketPriceTicker extends StatefulWidget {
  const MarketPriceTicker({super.key});

  @override
  State<MarketPriceTicker> createState() => _MarketPriceTickerState();
}

class _MarketPriceTickerState extends State<MarketPriceTicker>
    with TickerProviderStateMixin {
  late AnimationController _scrollController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<_MarketPrice> _prices = [
    _MarketPrice('Wheat', 2450, 2.5, true),
    _MarketPrice('Rice', 3200, -1.2, false),
    _MarketPrice('Corn', 1850, 3.8, true),
    _MarketPrice('Soybeans', 4100, 0.5, true),
    _MarketPrice('Cotton', 5200, -2.1, false),
    _MarketPrice('Sugarcane', 280, 1.8, true),
    _MarketPrice('Tomato', 1250, 4.2, true),
    _MarketPrice('Onion', 1800, -0.8, false),
    _MarketPrice('Potato', 950, 1.5, true),
    _MarketPrice('Banana', 2200, 2.3, true),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = AnimationController(
      duration: const Duration(seconds: 25), // Slower for better readability
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scrollController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with live indicator
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppTheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Text(
                'Live Market Rates',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.update,
                      size: 14,
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Updated now',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Enhanced ticker with better visibility
          Container(
            height: ResponsiveHelper.isDesktop(context) ? 120 : 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryGreen.withValues(alpha: 0.05),
                  AppTheme.skyBlue.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AnimatedBuilder(
                animation: _scrollController,
                builder: (context, child) {
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _prices.length * 100, // Infinite scroll effect
                    itemBuilder: (context, index) {
                      final price = _prices[index % _prices.length];
                      return Transform.translate(
                        offset: Offset(-_scrollController.value * 200, 0),
                        child: _buildPriceCard(price),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          
          // Speed control info
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.speed,
                size: 14,
                color: AppTheme.textGrey,
              ),
              const SizedBox(width: 4),
              Text(
                'Optimized reading speed • Tap for details',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textGrey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(_MarketPrice price) {
    final isPositive = price.isPositive;
    final changeColor = isPositive ? AppTheme.success : AppTheme.error;
    final changeIcon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Container(
      width: ResponsiveHelper.isDesktop(context) ? 200 : 160,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: changeColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Product name
          Text(
            price.name,
            style: TextStyle(
              fontSize: ResponsiveHelper.isDesktop(context) ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          
          // Price
          Row(
            children: [
              Text(
                '₹${price.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: ResponsiveHelper.isDesktop(context) ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/kg',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // Change indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: changeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  changeIcon,
                  size: 12,
                  color: changeColor,
                ),
                const SizedBox(width: 2),
                Text(
                  '${isPositive ? '+' : ''}${price.change.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: changeColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketPrice {
  final String name;
  final double price;
  final double change;
  final bool isPositive;

  _MarketPrice(this.name, this.price, this.change, this.isPositive);
}