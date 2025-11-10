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
    _MarketPrice('Wheat', 2450, 2.5, true, 450.5),
    _MarketPrice('Rice', 3200, -1.2, false, 320.8),
    _MarketPrice('Corn', 1850, 3.8, true, 225.3),
    _MarketPrice('Soybeans', 4100, 0.5, true, 180.7),
    _MarketPrice('Cotton', 5200, -2.1, false, 95.2),
    _MarketPrice('Sugarcane', 280, 1.8, true, 1200.0),
    _MarketPrice('Tomato', 1250, 4.2, true, 125.5),
    _MarketPrice('Onion', 1800, -0.8, false, 200.0),
    _MarketPrice('Potato', 950, 1.5, true, 180.0),
    _MarketPrice('Banana', 2200, 2.3, true, 75.2),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = AnimationController(
      duration: const Duration(seconds: 25),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with live indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppTheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Live Market Rates',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.update,
                        size: 12,
                        color: AppTheme.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Live',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Enhanced ticker with fixed overflow
          Container(
            height: ResponsiveHelper.isDesktop(context) ? 110 : 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryGreen.withOpacity(0.05),
                  AppTheme.skyBlue.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AnimatedBuilder(
                animation: _scrollController,
                builder: (context, child) {
                  return OverflowBox(
                    maxWidth: double.infinity,
                    child: Transform.translate(
                      offset: Offset(-_scrollController.value * 1000, 0),
                      child: Row(
                        children: List.generate(_prices.length * 3, (index) {
                          final price = _prices[index % _prices.length];
                          return _buildPriceCard(price);
                        }),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Speed control info
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.speed,
                size: 12,
                color: AppTheme.textGrey,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Optimized reading speed • Live from APMC markets',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textGrey,
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
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
      width: ResponsiveHelper.isDesktop(context) ? 180 : 140,
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: changeColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Product name
          Text(
            price.name,
            style: TextStyle(
              fontSize: ResponsiveHelper.isDesktop(context) ? 14 : 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          
          // Price and quantity
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${price.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.isDesktop(context) ? 16 : 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    Text(
                      '${price.quantity}t',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Change indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: changeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      changeIcon,
                      size: 10,
                      color: changeColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${isPositive ? '+' : ''}${price.change.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: changeColor,
                      ),
                    ),
                  ],
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
  final String name;
  final double price;
  final double change;
  final bool isPositive;
  final double quantity; // Added quantity

  _MarketPrice(this.name, this.price, this.change, this.isPositive, this.quantity);
}