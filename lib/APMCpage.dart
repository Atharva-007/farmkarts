import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'APMC Markets',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const APMCPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class APMCPage extends StatelessWidget {
  const APMCPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('APMC Markets in Maharashtra'),
        backgroundColor: Colors.green[700],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: apmcMarkets.length,
        itemBuilder: (context, index) {
          final market = apmcMarkets[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Hero(
                tag: market['name']! + '_icon',
                child: CircleAvatar(
                  backgroundColor: Colors.green[700],
                  child: const Icon(Icons.local_grocery_store, color: Colors.white),
                ),
              ),
              title: Hero(
                tag: market['name']!,
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    market['name']!,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              subtitle: Text(market['location']!),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        APMCDetailPage(market: market),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
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
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green[700]),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
              softWrap: true,
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final market = widget.market;

    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: market['name']!,
          child: Material(
            color: Colors.transparent,
            child: Text(
              market['name']!,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        backgroundColor: Colors.green[700],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: market['name']! + '_icon',
                  child: Icon(Icons.local_grocery_store, size: 80, color: Colors.green[700]),
                ),
                const SizedBox(height: 20),
                _buildInfoRow(Icons.location_on, 'Location', market['location']!),
                _buildInfoRow(Icons.access_time, 'Timings', market['timings']!),
                _buildInfoRow(Icons.price_change, 'Current Prices', market['price']!),
                const SizedBox(height: 20),
                Text(
                  'Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 2),
                        blurRadius: 3,
                        color: Colors.green.shade200,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  market['details']!,
                  style: const TextStyle(fontSize: 18, height: 1.4),
                ),
                const SizedBox(height: 40),
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Markets', style: TextStyle(fontSize: 16)),
                    onPressed: () => Navigator.pop(context),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
