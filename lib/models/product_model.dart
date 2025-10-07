class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final String unit;
  final String imageUrl;
  final String sellerId;
  final String sellerName;
  final String location;
  final DateTime timestamp;
  final bool isOrganic;
  final int quantity;
  final List<String> tags;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.unit,
    required this.imageUrl,
    required this.sellerId,
    required this.sellerName,
    required this.location,
    required this.timestamp,
    this.isOrganic = false,
    this.quantity = 0,
    this.tags = const [],
  });

  factory Product.fromMap(String id, Map<dynamic, dynamic> map) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      unit: map['unit'] ?? 'kg',
      imageUrl: map['imageUrl'] ?? '',
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      location: map['location'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      isOrganic: map['isOrganic'] ?? false,
      quantity: map['quantity'] ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'unit': unit,
      'imageUrl': imageUrl,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'location': location,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isOrganic': isOrganic,
      'quantity': quantity,
      'tags': tags,
    };
  }
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String location;
  final String farmName;
  final double farmSize;
  final String farmType;
  final List<String> crops;
  final String profileImageUrl;
  final DateTime joinDate;
  final double rating;
  final int totalSales;
  final bool isVerified;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.location = '',
    this.farmName = '',
    this.farmSize = 0.0,
    this.farmType = '',
    this.crops = const [],
    this.profileImageUrl = '',
    required this.joinDate,
    this.rating = 0.0,
    this.totalSales = 0,
    this.isVerified = false,
  });

  factory UserProfile.fromMap(String id, Map<dynamic, dynamic> map) {
    return UserProfile(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      location: map['location'] ?? '',
      farmName: map['farmName'] ?? '',
      farmSize: (map['farmSize'] ?? 0).toDouble(),
      farmType: map['farmType'] ?? '',
      crops: List<String>.from(map['crops'] ?? []),
      profileImageUrl: map['profileImageUrl'] ?? '',
      joinDate: DateTime.fromMillisecondsSinceEpoch(map['joinDate'] ?? 0),
      rating: (map['rating'] ?? 0).toDouble(),
      totalSales: map['totalSales'] ?? 0,
      isVerified: map['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'location': location,
      'farmName': farmName,
      'farmSize': farmSize,
      'farmType': farmType,
      'crops': crops,
      'profileImageUrl': profileImageUrl,
      'joinDate': joinDate.millisecondsSinceEpoch,
      'rating': rating,
      'totalSales': totalSales,
      'isVerified': isVerified,
    };
  }
}

class WeatherData {
  final double temperature;
  final double humidity;
  final double windSpeed;
  final String condition;
  final String description;
  final String icon;
  final double visibility;
  final double pressure;
  final DateTime timestamp;
  final List<DailyForecast> forecast;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
    required this.description,
    required this.icon,
    required this.visibility,
    required this.pressure,
    required this.timestamp,
    this.forecast = const [],
  });

  factory WeatherData.fromMap(Map<dynamic, dynamic> map) {
    return WeatherData(
      temperature: (map['temperature'] ?? 0).toDouble(),
      humidity: (map['humidity'] ?? 0).toDouble(),
      windSpeed: (map['windSpeed'] ?? 0).toDouble(),
      condition: map['condition'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '',
      visibility: (map['visibility'] ?? 0).toDouble(),
      pressure: (map['pressure'] ?? 0).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      forecast: (map['forecast'] as List<dynamic>?)
              ?.map((f) => DailyForecast.fromMap(f))
              .toList() ??
          [],
    );
  }
}

class DailyForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final String condition;
  final String icon;
  final double rainfall;

  DailyForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.condition,
    required this.icon,
    this.rainfall = 0.0,
  });

  factory DailyForecast.fromMap(Map<dynamic, dynamic> map) {
    return DailyForecast(
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      maxTemp: (map['maxTemp'] ?? 0).toDouble(),
      minTemp: (map['minTemp'] ?? 0).toDouble(),
      condition: map['condition'] ?? '',
      icon: map['icon'] ?? '',
      rainfall: (map['rainfall'] ?? 0).toDouble(),
    );
  }
}