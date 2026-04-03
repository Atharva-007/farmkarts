import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Sample APMC market data
final List<Map<String, String>> apmcMarkets = [
  {
    'name': 'Pune APMC Market',
    'location': 'Pune, Maharashtra',
    'timings': '8:00 AM - 6:00 PM',
    'price': 'Wheat: ₹2200/quintal, Rice: ₹3000/quintal',
    'details': 'One of the biggest markets in Maharashtra with modern facilities and large farmer participation.'
  },
  {
    'name': 'Nagpur APMC Market',
    'location': 'Nagpur, Maharashtra',
    'timings': '9:00 AM - 5:00 PM',
    'price': 'Cotton: ₹4500/quintal, Soybean: ₹3800/quintal',
    'details': 'Famous for cotton and soybean trading, with a focus on organic produce.'
  },
  {
    'name': 'Nashik APMC Market',
    'location': 'Nashik, Maharashtra',
    'timings': '7:00 AM - 4:00 PM',
    'price': 'Onion: ₹8000/quintal, Grapes: ₹12000/quintal',
    'details': 'Key market for horticultural products with advanced cold storage.'
  },
  {
    'name': 'Solapur APMC Market',
    'location': 'Solapur, Maharashtra',
    'timings': '8:30 AM - 5:30 PM',
    'price': 'Sugarcane: ₹3000/quintal, Turmeric: ₹7000/quintal',
    'details': 'Known for sugarcane and spice trade, supporting local farmers extensively.'
  },
];

class APMCPage extends StatelessWidget {
  const APMCPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('APMC Markets'),
        backgroundColor: AppTheme.getAppBarColor(context),
        foregroundColor: AppTheme.getAppBarTextColor(context),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: apmcMarkets.length,
        itemBuilder: (context, index) {
          final market = apmcMarkets[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.getIconBackgroundColor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.store, color: AppTheme.getPrimaryAccent(context)),
              ),
              title: Text(
                market['name']!,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(market['location']!),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => APMCDetailPage(market: market),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class APMCDetailPage extends StatefulWidget {
  final Map<String, String> market;

  const APMCDetailPage({required this.market, super.key});

  @override
  State<APMCDetailPage> createState() => _APMCDetailPageState();
}

class _APMCDetailPageState extends State<APMCDetailPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final market = widget.market;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(market['name']!),
        backgroundColor: AppTheme.getAppBarColor(context),
        foregroundColor: AppTheme.getAppBarTextColor(context),
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.getIconBackgroundColor(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.store, size: 60, color: AppTheme.getPrimaryAccent(context)),
                ),
              ),
              const SizedBox(height: 32),
              _buildInfoSection(context, Icons.location_on, 'Location', market['location']!),
              _buildInfoSection(context, Icons.access_time, 'Timings', market['timings']!),
              _buildInfoSection(context, Icons.price_change, 'Current Prices', market['price']!),
              const SizedBox(height: 24),
              Text(
                'Market Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                market['details']!,
                style: TextStyle(
                  fontSize: 16, 
                  height: 1.6,
                  color: AppTheme.getTextColor(context).withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.getPrimaryAccent(context),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Back to Markets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.getPrimaryAccent(context), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
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
