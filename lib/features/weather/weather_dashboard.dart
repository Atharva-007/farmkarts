import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/app_theme.dart';
import '../../services/weather_service.dart';
import '../../widgets/universal_header.dart';

class WeatherDashboard extends StatefulWidget {
  const WeatherDashboard({super.key});

  @override
  State<WeatherDashboard> createState() => _WeatherDashboardState();
}

class _WeatherDashboardState extends State<WeatherDashboard>
    with SingleTickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  Position? _currentPosition;
  String _locationName = 'Loading...';
  WeatherData? _currentWeather;
  List<Map<String, dynamic>>? _agriInsights;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
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
    if (mounted) {
      _animationController.forward();
    }
  }

  Future<void> _getLocation() async {
    try {
      final permission = await Permission.location.request();
      if (permission.isGranted) {
        _currentPosition = await Geolocator.getCurrentPosition();
        setState(() {
          _locationName = 'Current Location';
        });
      } else {
        setState(() {
          _locationName = 'Delhi, India'; // Default
        });
      }
    } catch (e) {
      setState(() {
        _locationName = 'Delhi, India';
      });
    }
  }

  Future<void> _fetchWeatherData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      double lat = _currentPosition?.latitude ?? 28.6139;
      double lon = _currentPosition?.longitude ?? 77.2090;

      final data = await _weatherService.fetchWeather(lat, lon);
      final insights = _weatherService.getAgriInsights(data);

      if (mounted) {
        setState(() {
          _currentWeather = data;
          _agriInsights = insights;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _fetchWeatherData,
          color: AppTheme.primaryGreen,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              UniversalHeader(
                title: 'Weather Forecast',
                subtitle: _locationName,
                icon: Icons.wb_sunny_rounded,
                showBackButton: true,
                showProfile: true,
                actions: [
                  IconButton(
                    icon:
                        const Icon(Icons.refresh_rounded, color: Colors.white),
                    onPressed: _initializeWeather,
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: _isLoading
                    ? Padding(
                        padding: const EdgeInsets.only(top: 100),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.getPrimaryAccent(context))),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildCurrentWeatherCard(),
                            const SizedBox(height: 20),
                            _buildAgriInsightsSection(),
                            const SizedBox(height: 20),
                            _buildForecastSection(),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentWeatherCard() {
    if (_currentWeather == null) return const SizedBox.shrink();

    final temp = _currentWeather!.temperature.round();
    final condition = _currentWeather!.condition;
    final humidity = _currentWeather!.humidity;
    final wind = _currentWeather!.windSpeed;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
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
                    condition,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16),
                  ),
                ],
              ),
              const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 48),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            '$temp°C',
            style: const TextStyle(
                color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherDetail(
                  Icons.water_drop_outlined, '$humidity%', 'Humidity'),
              _buildWeatherDetail(Icons.air_rounded, '$wind m/s', 'Wind'),
              _buildWeatherDetail(Icons.compress_rounded,
                  '${_currentWeather!.pressure} hPa', 'Pressure'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
      ],
    );
  }

  Widget _buildAgriInsightsSection() {
    if (_agriInsights == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Agricultural Insights',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._agriInsights!.map((insight) => _buildInsightCard(insight)),
      ],
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight) {
    Color color;
    IconData icon;

    switch (insight['icon']) {
      case 'hot':
        color = Colors.orange;
        icon = Icons.thermostat_rounded;
        break;
      case 'cold':
        color = Colors.blue;
        icon = Icons.ac_unit_rounded;
        break;
      case 'bug':
        color = Colors.red;
        icon = Icons.bug_report_rounded;
        break;
      case 'rain':
        color = Colors.indigo;
        icon = Icons.umbrella_rounded;
        break;
      case 'seed':
        color = Colors.green;
        icon = Icons.eco_rounded;
        break;
      case 'wind':
        color = Colors.grey;
        icon = Icons.air_rounded;
        break;
      default:
        color = Colors.green;
        icon = Icons.check_circle_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(insight['title'],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(insight['desc']),
      ),
    );
  }

  Widget _buildForecastSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '7-Day Forecast',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Center(child: Text('Coming soon from our high-precision model.')),
      ],
    );
  }
}
