import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class APMCApiService {
  static const String _baseUrl = 'https://api.data.gov.in/catalog/';
  static const String _apiKey = 'your_api_key_here'; // Replace with actual API key
  
  /// Fetch market rates from government API
  Future<List<MarketRate>> fetchMarketRates({
    String? state,
    String? district,
    String? market,
    String? commodity,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      // For demo purposes, we'll use mock data
      // In production, use the actual government API endpoints
      return await _fetchMockMarketRates();
    } catch (e) {
      print('Error fetching market rates: $e');
      return _generateFallbackData();
    }
  }

  /// Mock data for demonstration (when real API is not available)
  Future<List<MarketRate>> _fetchMockMarketRates() async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));
    
    return _generateComprehensiveMarketData();
  }

  /// Generate comprehensive mock market data
  List<MarketRate> _generateComprehensiveMarketData() {
    final random = Random();
    final today = DateTime.now();

    final comprehensiveCommodities = [
      // Vegetables
      {'name': 'Tomato', 'price': 30.0, 'category': 'Vegetables', 'unit': 'Kg'},
      {'name': 'Onion', 'price': 25.0, 'category': 'Vegetables', 'unit': 'Kg'},
      {'name': 'Potato', 'price': 20.0, 'category': 'Vegetables', 'unit': 'Kg'},
      {'name': 'Cabbage', 'price': 15.0, 'category': 'Vegetables', 'unit': 'Kg'},
      {'name': 'Cauliflower', 'price': 35.0, 'category': 'Vegetables', 'unit': 'Kg'},
      {'name': 'Brinjal', 'price': 40.0, 'category': 'Vegetables', 'unit': 'Kg'},
      {'name': 'Okra', 'price': 45.0, 'category': 'Vegetables', 'unit': 'Kg'},
      {'name': 'Green Chilli', 'price': 50.0, 'category': 'Vegetables', 'unit': 'Kg'},
      {'name': 'Capsicum', 'price': 60.0, 'category': 'Vegetables', 'unit': 'Kg'},
      {'name': 'Cucumber', 'price': 18.0, 'category': 'Vegetables', 'unit': 'Kg'},
      {'name': 'Carrot', 'price': 35.0, 'category': 'Vegetables', 'unit': 'Kg'},
      {'name': 'Beans', 'price': 40.0, 'category': 'Vegetables', 'unit': 'Kg'},

      // Fruits
      {'name': 'Apple', 'price': 120.0, 'category': 'Fruits', 'unit': 'Kg'},
      {'name': 'Banana', 'price': 45.0, 'category': 'Fruits', 'unit': 'Dozen'},
      {'name': 'Orange', 'price': 60.0, 'category': 'Fruits', 'unit': 'Kg'},
      {'name': 'Mango', 'price': 80.0, 'category': 'Fruits', 'unit': 'Kg'},
      {'name': 'Grapes', 'price': 85.0, 'category': 'Fruits', 'unit': 'Kg'},
      {'name': 'Pomegranate', 'price': 150.0, 'category': 'Fruits', 'unit': 'Kg'},
      {'name': 'Papaya', 'price': 25.0, 'category': 'Fruits', 'unit': 'Kg'},
      {'name': 'Watermelon', 'price': 15.0, 'category': 'Fruits', 'unit': 'Kg'},

      // Grains & Cereals
      {'name': 'Rice (Basmati)', 'price': 3200.0, 'category': 'Grains & Cereals', 'unit': 'Quintal'},
      {'name': 'Rice (Sona Masuri)', 'price': 2800.0, 'category': 'Grains & Cereals', 'unit': 'Quintal'},
      {'name': 'Wheat', 'price': 2100.0, 'category': 'Grains & Cereals', 'unit': 'Quintal'},
      {'name': 'Maize', 'price': 1850.0, 'category': 'Grains & Cereals', 'unit': 'Quintal'},
      {'name': 'Bajra', 'price': 2200.0, 'category': 'Grains & Cereals', 'unit': 'Quintal'},
      {'name': 'Jowar', 'price': 2050.0, 'category': 'Grains & Cereals', 'unit': 'Quintal'},

      // Pulses & Legumes
      {'name': 'Toor Dal', 'price': 6800.0, 'category': 'Pulses & Legumes', 'unit': 'Quintal'},
      {'name': 'Moong Dal', 'price': 7200.0, 'category': 'Pulses & Legumes', 'unit': 'Quintal'},
      {'name': 'Chana', 'price': 5400.0, 'category': 'Pulses & Legumes', 'unit': 'Quintal'},
      {'name': 'Masoor', 'price': 4800.0, 'category': 'Pulses & Legumes', 'unit': 'Quintal'},
      {'name': 'Urad Dal', 'price': 6500.0, 'category': 'Pulses & Legumes', 'unit': 'Quintal'},

      // Spices & Condiments
      {'name': 'Turmeric', 'price': 125.0, 'category': 'Spices & Condiments', 'unit': 'Kg'},
      {'name': 'Red Chilli', 'price': 180.0, 'category': 'Spices & Condiments', 'unit': 'Kg'},
      {'name': 'Coriander', 'price': 98.0, 'category': 'Spices & Condiments', 'unit': 'Kg'},
      {'name': 'Cumin', 'price': 450.0, 'category': 'Spices & Condiments', 'unit': 'Kg'},
      {'name': 'Fenugreek', 'price': 85.0, 'category': 'Spices & Condiments', 'unit': 'Kg'},

      // Oil Seeds
      {'name': 'Groundnut', 'price': 5800.0, 'category': 'Oil Seeds', 'unit': 'Quintal'},
      {'name': 'Soybean', 'price': 4200.0, 'category': 'Oil Seeds', 'unit': 'Quintal'},
      {'name': 'Sunflower', 'price': 5500.0, 'category': 'Oil Seeds', 'unit': 'Quintal'},
      {'name': 'Mustard', 'price': 4800.0, 'category': 'Oil Seeds', 'unit': 'Quintal'},
      {'name': 'Sesame', 'price': 7200.0, 'category': 'Oil Seeds', 'unit': 'Quintal'},

      // Cash Crops
      {'name': 'Cotton', 'price': 5200.0, 'category': 'Cash Crops', 'unit': 'Quintal'},
      {'name': 'Sugarcane', 'price': 320.0, 'category': 'Cash Crops', 'unit': 'Ton'},
      {'name': 'Jute', 'price': 4100.0, 'category': 'Cash Crops', 'unit': 'Quintal'},
    ];

    final states = ['Maharashtra', 'Karnataka', 'Tamil Nadu', 'Gujarat', 'Uttar Pradesh', 'Madhya Pradesh', 'Rajasthan', 'Punjab', 'Haryana'];

    return comprehensiveCommodities.map((commodity) {
      final basePrice = commodity['price'] as double;
      final priceVariation = 0.8 + (random.nextDouble() * 0.4); // 80% to 120% of base price
      final modalPrice = basePrice * priceVariation;
      final state = states[random.nextInt(states.length)];
      
      return MarketRate(
        id: '${commodity['name']}_${state}_${random.nextInt(1000)}'.toLowerCase().replaceAll(' ', '_'),
        productName: commodity['name'] as String,
        category: commodity['category'] as String,
        state: state,
        district: _generateDistrict(state),
        market: _generateMarketName(state),
        minPrice: modalPrice * (0.85 + random.nextDouble() * 0.1), // 85-95% of modal
        maxPrice: modalPrice * (1.05 + random.nextDouble() * 0.1), // 105-115% of modal
        modalPrice: modalPrice,
        priceDate: today.subtract(Duration(hours: random.nextInt(24))),
        unit: commodity['unit'] as String,
        variety: _generateVariety(commodity['name'] as String),
        grade: ['FAQ', 'Medium', 'Good', 'Superior'][random.nextInt(4)],
        arrivals: random.nextInt(1000) + 100,
      );
    }).toList();
  }

  /// Generate market name based on state
  String _generateMarketName(String state) {
    final marketTypes = ['APMC Market', 'Krishi Upaj Mandi', 'Agricultural Market Yard', 'Wholesale Market', 'Mandi Samiti'];
    final district = _generateDistrict(state);
    return '$district ${marketTypes[Random().nextInt(marketTypes.length)]}';
  }

  /// Generate fallback data when API fails
  List<MarketRate> _generateFallbackData() {
    final random = Random();
    final basicCommodities = [
      {'name': 'Rice', 'price': 2500.0, 'category': 'Grains & Cereals', 'unit': 'Quintal'},
      {'name': 'Wheat', 'price': 2100.0, 'category': 'Grains & Cereals', 'unit': 'Quintal'},
      {'name': 'Tomato', 'price': 30.0, 'category': 'Vegetables', 'unit': 'Kg'},
      {'name': 'Onion', 'price': 25.0, 'category': 'Vegetables', 'unit': 'Kg'},
      {'name': 'Potato', 'price': 20.0, 'category': 'Vegetables', 'unit': 'Kg'},
    ];

    return basicCommodities.map((commodity) {
      final basePrice = commodity['price'] as double;
      return MarketRate(
        id: commodity['name'] as String,
        productName: commodity['name'] as String,
        category: commodity['category'] as String,
        state: 'Maharashtra',
        district: 'Pune',
        market: 'Market Yard',
        minPrice: basePrice * 0.9,
        maxPrice: basePrice * 1.1,
        modalPrice: basePrice,
        priceDate: DateTime.now(),
        unit: commodity['unit'] as String,
        variety: 'Common',
        grade: 'FAQ',
        arrivals: random.nextInt(500) + 100,
      );
    }).toList();
  }

  /// Generate district name based on state
  String _generateDistrict(String state) {
    final districtMap = {
      'Maharashtra': ['Pune', 'Mumbai', 'Nashik', 'Nagpur', 'Aurangabad'],
      'Karnataka': ['Bangalore', 'Mysore', 'Hubli', 'Mangalore', 'Belgaum'],
      'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Salem', 'Tiruchirappalli'],
      'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar'],
      'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Agra', 'Meerut', 'Varanasi'],
    };
    
    final districts = districtMap[state] ?? ['District'];
    return districts[Random().nextInt(districts.length)];
  }

  /// Generate variety name based on commodity
  String _generateVariety(String commodity) {
    final varietyMap = {
      'Rice': ['Basmati', 'Sona Masuri', 'IR-64', 'PR-106', 'Kolam'],
      'Wheat': ['PBW-343', 'HD-2967', 'WH-147', 'DBW-17', 'UP-2338'],
      'Cotton': ['Bt Cotton', 'Deshi', 'American', 'Hybrid', 'Organic'],
      'Tomato': ['Hybrid', 'Deshi', 'Cherry', 'Roma', 'Beef'],
      'Onion': ['Red', 'White', 'Hybrid', 'Deshi', 'Export Quality'],
    };
    
    final varieties = varietyMap[commodity] ?? ['Common', 'Local', 'Hybrid'];
    return varieties[Random().nextInt(varieties.length)];
  }
}

/// Market Rate model
class MarketRate {
  final String id;
  final String productName;
  final String category;
  final String state;
  final String district;
  final String market;
  final double minPrice;
  final double maxPrice;
  final double modalPrice;
  final DateTime priceDate;
  final String unit;
  final String variety;
  final String grade;
  final int arrivals;

  MarketRate({
    required this.id,
    required this.productName,
    required this.category,
    required this.state,
    required this.district,
    required this.market,
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
    required this.priceDate,
    required this.unit,
    required this.variety,
    required this.grade,
    required this.arrivals,
  });

  factory MarketRate.fromJson(Map<String, dynamic> json) {
    return MarketRate(
      id: json['id'] ?? '',
      productName: json['commodity'] ?? json['productName'] ?? '',
      category: json['category'] ?? 'Others',
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      market: json['market'] ?? '',
      minPrice: _parseDoubleStatic(json['min_price'] ?? json['minPrice']),
      maxPrice: _parseDoubleStatic(json['max_price'] ?? json['maxPrice']),
      modalPrice: _parseDoubleStatic(json['modal_price'] ?? json['modalPrice']),
      priceDate: DateTime.tryParse(json['price_date'] ?? json['priceDate'] ?? '') ?? DateTime.now(),
      unit: json['unit'] ?? 'Kg',
      variety: json['variety'] ?? 'Common',
      grade: json['grade'] ?? 'FAQ',
      arrivals: _parseIntStatic(json['arrivals'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'category': category,
      'state': state,
      'district': district,
      'market': market,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'modalPrice': modalPrice,
      'priceDate': priceDate.toIso8601String(),
      'unit': unit,
      'variety': variety,
      'grade': grade,
      'arrivals': arrivals,
    };
  }

  static double _parseDoubleStatic(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    }
    return 0.0;
  }

  static int _parseIntStatic(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value.replaceAll(',', '')) ?? 0;
    }
    return 0;
  }
}

/// Price trend enum for market analysis
enum PriceTrend {
  up,
  down,
  stable,
}

/// Alert severity enum
enum AlertSeverity {
  low,
  medium,
  high,
}