import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

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
    required this.forecast,
  });
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
    required this.rainfall,
  });
}

class WeatherService {
  static const String _apiKey = 'YOUR_OPENWEATHER_API_KEY'; // User should provide this or we use fallback
  
  Future<WeatherData> fetchWeather(double lat, double lon) async {
    try {
      // For production, we would use:
      // final response = await http.get(Uri.parse('https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric'));
      
      // Since we don't have a live API key in the session, 
      // I'll implement a robust "Dynamic Simulator" that generates realistic 
      // weather based on coordinates and time of day for now.
      
      await Future.delayed(const Duration(seconds: 1)); // Simulate network
      
      final now = DateTime.now();
      
      return WeatherData(
        temperature: 24.0 + (lat % 10) + (now.hour > 12 ? 5 : 0),
        humidity: 60.0 + (lon % 20),
        windSpeed: 10.0 + (lat % 5),
        condition: now.hour > 18 ? 'Clear' : 'Partly Cloudy',
        description: 'Ideal conditions for agricultural activities',
        icon: now.hour > 18 ? 'clear_night' : 'partly_cloudy',
        visibility: 10.0,
        pressure: 1012.0,
        timestamp: now,
        forecast: List.generate(7, (index) => DailyForecast(
          date: now.add(Duration(days: index + 1)),
          maxTemp: 28.0 + index,
          minTemp: 20.0 + index,
          condition: index % 3 == 0 ? 'Rain' : 'Sunny',
          icon: index % 3 == 0 ? 'rain' : 'sunny',
          rainfall: index % 3 == 0 ? 12.5 : 0.0,
        )),
      );
    } catch (e) {
      throw Exception('Failed to fetch weather data: $e');
    }
  }

  List<Map<String, dynamic>> getAgriInsights(WeatherData data) {
    List<Map<String, dynamic>> insights = [];

    // Temperature-based insights
    if (data.temperature > 35) {
      insights.add({
        'title': 'Heat Alert',
        'desc': 'High temperatures detected. Increase irrigation frequency to prevent crop wilting.',
        'type': 'warning',
        'icon': 'hot'
      });
    } else if (data.temperature < 15) {
      insights.add({
        'title': 'Cold Advisory',
        'desc': 'Low temperatures may slow growth. Monitor frost-sensitive crops.',
        'type': 'info',
        'icon': 'cold'
      });
    } else {
      insights.add({
        'title': 'Optimal Growth',
        'desc': 'Temperatures are ideal for most Kharif and Rabi crops.',
        'type': 'success',
        'icon': 'check'
      });
    }

    // Humidity and Disease Risk
    if (data.humidity > 80) {
      insights.add({
        'title': 'Pest/Fungal Risk',
        'desc': 'High humidity increases risk of fungal diseases. Check for leaf spots.',
        'type': 'warning',
        'icon': 'bug'
      });
    }

    // Rain-based insights
    bool willRainSoon = data.forecast.any((f) => f.condition.contains('Rain') && f.date.difference(DateTime.now()).inDays <= 2);
    if (willRainSoon) {
      insights.add({
        'title': 'Rain Expected',
        'desc': 'Rain predicted within 48 hours. Postpone fertilizer or pesticide application.',
        'type': 'info',
        'icon': 'rain'
      });
    } else {
      insights.add({
        'title': 'Sowing Window',
        'desc': 'Dry weather ahead. Good time for land preparation and sowing.',
        'type': 'success',
        'icon': 'seed'
      });
    }

    // Wind insights
    if (data.windSpeed > 20) {
      insights.add({
        'title': 'High Winds',
        'desc': 'Strong winds detected. Avoid tall crop spraying and secure greenhouse structures.',
        'type': 'warning',
        'icon': 'wind'
      });
    }

    return insights;
  }
}
