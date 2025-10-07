import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../widgets/weather_forecast_card.dart';
// import '../../widgets/farming_advice_card.dart';
// import '../../widgets/weather_alerts_card.dart';

class WeatherDashboard extends StatefulWidget {
  const WeatherDashboard({super.key});

  @override
  State<WeatherDashboard> createState() => _WeatherDashboardState();
}

class _WeatherDashboardState extends State<WeatherDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  WeatherData? _currentWeather;
  Position? _currentPosition;
  bool _isLoading = true;
  String _locationName = 'Unknown Location';
  
  // Sample weather data for demonstration
  final WeatherData _sampleWeather = WeatherData(
    temperature: 28.5,
    humidity: 65.0,
    windSpeed: 12.0,
    condition: 'Sunny',
    description: 'Clear sky, perfect for farming',
    icon: 'sunny',
    visibility: 10.0,
    pressure: 1013.25,
    timestamp: DateTime.now(),
    forecast: [
      DailyForecast(
        date: DateTime.now().add(const Duration(days: 1)),
        maxTemp: 30,
        minTemp: 22,
        condition: 'Partly Cloudy',
        icon: 'partly_cloudy',
        rainfall: 0.0,
      ),
      DailyForecast(
        date: DateTime.now().add(const Duration(days: 2)),
        maxTemp: 29,
        minTemp: 21,
        condition: 'Light Rain',
        icon: 'rain',
        rainfall: 5.2,
      ),
      DailyForecast(
        date: DateTime.now().add(const Duration(days: 3)),
        maxTemp: 31,
        minTemp: 23,
        condition: 'Sunny',
        icon: 'sunny',
        rainfall: 0.0,
      ),
    ],
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _initializeWeather();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeWeather() async {
    await _getLocation();
    await _fetchWeatherData();
    _animationController.forward();
  }

  Future<void> _getLocation() async {
    try {
      final permission = await Permission.location.request();
      if (permission.isGranted) {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _locationName = 'Current Location';
        });
      } else {
        setState(() {
          _locationName = 'Delhi, India'; // Default location
        });
      }
    } catch (e) {
      setState(() {
        _locationName = 'Delhi, India'; // Default location
      });
    }
  }

  Future<void> _fetchWeatherData() async {
    try {
      // For now, use sample data
      setState(() {
        _currentWeather = _sampleWeather;
        _isLoading = false;
      });
      
      // In a real app, you would fetch from weather API:
      // final response = await http.get(Uri.parse('https://api.openweathermap.org/data/2.5/weather?lat=${_currentPosition?.latitude}&lon=${_currentPosition?.longitude}&appid=YOUR_API_KEY'));
      // if (response.statusCode == 200) {
      //   final data = json.decode(response.body);
      //   setState(() {
      //     _currentWeather = WeatherData.fromMap(data);
      //     _isLoading = false;
      //   });
      // }
    } catch (e) {
      setState(() {
        _currentWeather = _sampleWeather;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: _refreshWeatherData,
            color: AppTheme.primaryGreen,
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: AppConstants.defaultPadding,
                    child: Column(
                      children: [
                        if (_isLoading) ...[
                          const SizedBox(height: 100),
                          const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ] else if (_currentWeather != null) ...[
                          _buildCurrentWeatherCard(),
                          const SizedBox(height: 20),
                          _buildWeatherMetrics(),
                          const SizedBox(height: 20),
                          _buildForecastSection(),
                          const SizedBox(height: 20),
                          // const WeatherAlertsCard(),
                          // const SizedBox(height: 20),
                          // const FarmingAdviceCard(),
                          const SizedBox(height: 20),
                          _buildWeatherHistory(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.skyGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: AppConstants.defaultPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.cloud,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Weather',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.location_on, color: Colors.white),
                        onPressed: _showLocationDialog,
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: _showWeatherSettings,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _locationName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentWeatherCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: AppConstants.largePadding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: _getWeatherGradient(_currentWeather!.condition),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_currentWeather!.temperature.round()}°C',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _currentWeather!.condition,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      _currentWeather!.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                _getWeatherIcon(_currentWeather!.condition, 80),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Updated ${_formatTime(_currentWeather!.timestamp)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherMetrics() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weather Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    Icons.water_drop,
                    'Humidity',
                    '${_currentWeather!.humidity.round()}%',
                    AppTheme.skyBlue,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    Icons.air,
                    'Wind Speed',
                    '${_currentWeather!.windSpeed.round()} km/h',
                    AppTheme.lightGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    Icons.visibility,
                    'Visibility',
                    '${_currentWeather!.visibility.round()} km',
                    AppTheme.accentOrange,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    Icons.speed,
                    'Pressure',
                    '${_currentWeather!.pressure.round()} hPa',
                    AppTheme.earthBrown,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastSection() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '7-Day Forecast',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _showDetailedForecast,
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _currentWeather!.forecast.length,
                itemBuilder: (context, index) {
                  final forecast = _currentWeather!.forecast[index];
                  return WeatherForecastCard(forecast: forecast);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherHistory() {
    return Card(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weather History',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildHistoryItem('Yesterday', '26°C', 'Partly Cloudy', Icons.wb_cloudy),
            _buildHistoryItem('2 days ago', '24°C', 'Light Rain', Icons.grain),
            _buildHistoryItem('3 days ago', '29°C', 'Sunny', Icons.wb_sunny),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String date, String temp, String condition, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  condition,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            temp,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Gradient _getWeatherGradient(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return const LinearGradient(
          colors: [AppTheme.sunshine, AppTheme.accentOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'cloudy':
      case 'partly cloudy':
        return const LinearGradient(
          colors: [AppTheme.skyBlue, AppTheme.primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'rain':
      case 'light rain':
        return const LinearGradient(
          colors: [AppTheme.skyBlue, AppTheme.earthBrown],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return AppTheme.primaryGradient;
    }
  }

  Widget _getWeatherIcon(String condition, double size) {
    IconData iconData;
    Color color = Colors.white;

    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        iconData = Icons.wb_sunny;
        break;
      case 'cloudy':
      case 'partly cloudy':
        iconData = Icons.wb_cloudy;
        break;
      case 'rain':
      case 'light rain':
        iconData = Icons.grain;
        break;
      default:
        iconData = Icons.wb_sunny;
    }

    return Icon(iconData, size: size, color: color);
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  Future<void> _refreshWeatherData() async {
    await _fetchWeatherData();
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Location'),
        content: const Text('Location change feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showWeatherSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Weather Settings'),
        content: const Text('Weather settings coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDetailedForecast() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detailed Forecast'),
        content: const Text('Detailed forecast view coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}