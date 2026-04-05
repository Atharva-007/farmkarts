import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../theme/app_theme.dart';

class LiveMarketRatesWidget extends StatefulWidget {
  const LiveMarketRatesWidget({super.key});

  @override
  State<LiveMarketRatesWidget> createState() => _LiveMarketRatesWidgetState();
}

class _LiveMarketRatesWidgetState extends State<LiveMarketRatesWidget> {
  late ScrollController _scrollController;
  late Timer _scrollTimer;
  late Timer _priceUpdateTimer;

  // Mock data for live market rates (standard prices per quintal/100kg)
  final List<MarketRate> _marketRates = [
    MarketRate(commodity: 'Wheat', price: 2450.0, unit: 'qtl', change: 12.5),
    MarketRate(commodity: 'Rice', price: 3800.0, unit: 'qtl', change: -10.0),
    MarketRate(commodity: 'Onion', price: 1850.0, unit: 'qtl', change: 65.0),
    MarketRate(commodity: 'Tomato', price: 2200.0, unit: 'qtl', change: -45.5),
    MarketRate(commodity: 'Potato', price: 1400.0, unit: 'qtl', change: 22.0),
    MarketRate(commodity: 'Cotton', price: 7200.0, unit: 'qtl', change: 145.0),
    MarketRate(commodity: 'Soybean', price: 4600.0, unit: 'qtl', change: -35.0),
    MarketRate(commodity: 'Maize', price: 2150.0, unit: 'qtl', change: 18.0),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Start continuous fast scrolling after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });

    // Simulate live price updates
    _priceUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) _updatePrices();
    });
  }

  void _startScrolling() {
    const double step = 1.0; // Distance per tick
    const Duration duration =
        Duration(milliseconds: 30); // Tick interval (smaller = faster)

    _scrollTimer = Timer.periodic(duration, (timer) {
      if (_scrollController.hasClients) {
        double maxScroll = _scrollController.position.maxScrollExtent;
        double currentScroll = _scrollController.offset;

        if (currentScroll >= maxScroll) {
          _scrollController.jumpTo(0);
        } else {
          _scrollController.jumpTo(currentScroll + step);
        }
      }
    });
  }

  void _updatePrices() {
    setState(() {
      for (var rate in _marketRates) {
        final random = Random();
        final changePercent = (random.nextDouble() - 0.5) * 0.02;
        rate.price = rate.price * (1 + changePercent);
        rate.change = (random.nextDouble() - 0.5) * 50;
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer.cancel();
    _priceUpdateTimer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // Sleek Dark Background
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Fixed "LIVE" indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: const Center(
              child: Row(
                children: [
                  Icon(Icons.flash_on, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),

          // Scrolling Ticker
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              // Multiply list to create infinite loop effect
              itemBuilder: (context, index) {
                final rate = _marketRates[index % _marketRates.length];
                return _buildTickerItem(rate);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTickerItem(MarketRate rate) {
    final bool isPositive = rate.change >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            rate.commodity.toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '₹${rate.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                TextSpan(
                  text: '/qtl',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            color: isPositive ? Colors.greenAccent : Colors.redAccent,
            size: 20,
          ),
          Text(
            '${isPositive ? '+' : ''}${rate.change.toStringAsFixed(1)}',
            style: TextStyle(
              color: isPositive ? Colors.greenAccent : Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 15),
          Container(
            height: 15,
            width: 1,
            color: Colors.white24,
          ),
        ],
      ),
    );
  }
}

class MarketRate {
  String commodity;
  double price;
  String unit;
  double change;

  MarketRate({
    required this.commodity,
    required this.price,
    required this.unit,
    required this.change,
  });
}
