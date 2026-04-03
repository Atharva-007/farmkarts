import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';

class LiveMarketRatesWidget extends StatefulWidget {
  const LiveMarketRatesWidget({super.key});

  @override
  State<LiveMarketRatesWidget> createState() => _LiveMarketRatesWidgetState();
}

class _LiveMarketRatesWidgetState extends State<LiveMarketRatesWidget>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late Timer _timer;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  int _currentIndex = 0;
  
  // Mock data for live market rates
  final List<MarketRate> _marketRates = [
    MarketRate(
      commodity: 'Wheat',
      price: 2150.0,
      unit: 'per quintal',
      change: 25.0,
      market: 'Kharif',
      quantity: '1,245 quintals',
    ),
    MarketRate(
      commodity: 'Rice',
      price: 3200.0,
      unit: 'per quintal',
      change: -15.0,
      market: 'Basmati',
      quantity: '890 quintals',
    ),
    MarketRate(
      commodity: 'Onion',
      price: 850.0,
      unit: 'per quintal',
      change: 45.0,
      market: 'Red Onion',
      quantity: '2,100 quintals',
    ),
    MarketRate(
      commodity: 'Tomato',
      price: 1200.0,
      unit: 'per quintal',
      change: -30.0,
      market: 'Fresh',
      quantity: '750 quintals',
    ),
    MarketRate(
      commodity: 'Potato',
      price: 800.0,
      unit: 'per quintal',
      change: 12.0,
      market: 'Local',
      quantity: '1,850 quintals',
    ),
    MarketRate(
      commodity: 'Sugarcane',
      price: 320.0,
      unit: 'per quintal',
      change: 8.0,
      market: 'Industrial',
      quantity: '5,200 quintals',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
    
    // Auto-scroll every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _currentIndex = (_currentIndex + 1) % _marketRates.length;
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
    
    // Simulate live price updates
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _updatePrices();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updatePrices() {
    setState(() {
      for (var rate in _marketRates) {
        // Simulate price fluctuations
        final random = Random();
        final changePercent = (random.nextDouble() - 0.5) * 0.1; // ±5% max change
        final newPrice = rate.price * (1 + changePercent);
        final priceChange = newPrice - rate.price;
        
        rate.price = newPrice;
        rate.change = priceChange;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    
    return Container(
      height: isMobile ? 160 : 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.deepGreen,
            AppTheme.primaryGreen,
          ],
        ),
        boxShadow: AppTheme.defaultShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 16 : 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.trending_up,
                        color: Colors.white,
                        size: isDesktop ? 20 : 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Market Rates',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Updated every 5 minutes',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        color: AppTheme.success,
                        size: 8,
                      ),
                      const SizedBox(width: 4),
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
                ),
              ],
            ),
          ),
          Expanded(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: _marketRates.length,
                itemBuilder: (context, index) {
                  return _buildMarketRateCard(_marketRates[index]);
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _marketRates.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketRateCard(MarketRate rate) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isPositive = rate.change >= 0;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCommodityIcon(rate.commodity),
              color: Colors.white,
              size: isMobile ? 24 : 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  rate.commodity,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  rate.market,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rate.quantity,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '₹${rate.price.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                rate.unit,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive
                      ? AppTheme.success.withOpacity(0.3)
                      : AppTheme.error.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
                      color: isPositive ? AppTheme.success : AppTheme.error,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${isPositive ? '+' : ''}${rate.change.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: isPositive ? AppTheme.success : AppTheme.error,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
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

  IconData _getCommodityIcon(String commodity) {
    switch (commodity.toLowerCase()) {
      case 'wheat':
        return Icons.grain;
      case 'rice':
        return Icons.rice_bowl;
      case 'onion':
        return Icons.local_florist;
      case 'tomato':
        return Icons.local_pizza;
      case 'potato':
        return Icons.set_meal;
      case 'sugarcane':
        return Icons.grass;
      default:
        return Icons.agriculture;
    }
  }
}

class MarketRate {
  String commodity;
  double price;
  String unit;
  double change;
  String market;
  String quantity;

  MarketRate({
    required this.commodity,
    required this.price,
    required this.unit,
    required this.change,
    required this.market,
    required this.quantity,
  });
}