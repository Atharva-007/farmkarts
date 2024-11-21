import 'package:flutter/material.dart';
import 'colors.dart'; // Import the custom colors file

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.agriculture, color: Colors.white, size: 40),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Welcome to Farmer\'s Market App!',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quick Access Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickAccessButton(
                    context,
                    Icons.shopping_cart,
                    'Buy',
                    '/buy',
                    Colors.teal,
                    Colors.orange,
                  ),
                  _buildQuickAccessButton(
                    context,
                    Icons.sell,
                    'Sell',
                    '/sell',
                    Colors.teal,
                    Colors.orange,
                  ),
                  _buildQuickAccessButton(
                    context,
                    Icons.article,
                    'News',
                    '/news',
                    Colors.teal,
                    Colors.orange,
                  ),
                  _buildQuickAccessButton(
                    context,
                    Icons.settings,
                    'Settings',
                    '/settings',
                    Colors.teal,
                    Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // New Row for APMC and Mahabej
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickAccessButton(
                    context,
                    Icons.store,
                    'APMC',
                    '/apmc',
                    AppColors.deepBlue,
                    AppColors.lightBlue,
                  ),
                  _buildQuickAccessButton(
                    context,
                    Icons.grass,
                    'Mahabej',
                    '/mahabej',
                    AppColors.darkGreen,
                    AppColors.lightGreen,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Featured Products Section
              const Text(
                'Featured Products',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 150,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFeaturedProductCard('Fresh Tomatoes', 40, 'assets/tomatoes.jpg'),
                    _buildFeaturedProductCard('Organic Wheat', 30, 'assets/wheat.jpg'),
                    _buildFeaturedProductCard('Green Capsicum', 50, 'assets/capsicum.jpg'),
                    _buildFeaturedProductCard('Mangoes', 100, 'assets/mangoes.jpg'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Latest News Section
              const Text(
                'Latest News',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Column(
                children: [
                  _buildNewsTile(
                    'Government announces subsidies for organic farming',
                    'A new scheme to support organic farmers was unveiled.',
                  ),
                  _buildNewsTile(
                    'APMC prices hit record high for wheat',
                    'Wheat prices see a significant rise due to increased demand.',
                  ),
                  _buildNewsTile(
                    'New irrigation techniques improve yield',
                    'Farmers benefit from the latest drip irrigation technology.',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tips and Insights Section
              const Text(
                'Tips & Insights',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.lightGreen.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Did you know? Proper irrigation and timely use of organic fertilizers can increase crop yield by up to 30%!',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build quick access buttons
  Widget _buildQuickAccessButton(BuildContext context, IconData icon, String label, String route, Color primaryColor, Color secondaryColor) {
    return Column(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
            backgroundColor: primaryColor,
          ),
          onPressed: () {
            Navigator.pushNamed(context, route);
          },
          child: Icon(icon, size: 30, color: secondaryColor),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 16, color: secondaryColor)),
      ],
    );
  }

  // Helper method to build featured product card
  Widget _buildFeaturedProductCard(String name, int price, String imagePath) {
    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.grey, blurRadius: 4, spreadRadius: 1)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: 60, fit: BoxFit.cover),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text('₹$price/kg', style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // Helper method to build news tile
  Widget _buildNewsTile(String title, String subtitle) {
    return ListTile(
      leading: const Icon(Icons.fiber_new, color: Colors.redAccent),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () {
        // Handle tap to open news details
      },
    );
  }
}
