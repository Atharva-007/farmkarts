import 'package:flutter/material.dart';

class BuyPage extends StatelessWidget {
  const BuyPage({super.key});

  @override
  Widget build(BuildContext context) {
    // List of products with names, descriptions, and prices
    final List<Map<String, String>> products = [
      {'name': 'Wheat', 'description': 'High-quality wheat for bread and chapati.', 'price': '₹40/kg'},
      {'name': 'Rice', 'description': 'Premium basmati rice, ideal for biryani.', 'price': '₹60/kg'},
      {'name': 'Toor Dal', 'description': 'Organic pigeon peas, rich in protein.', 'price': '₹90/kg'},
      {'name': 'Chickpeas', 'description': 'Fresh kabuli chana for hummus or curry.', 'price': '₹80/kg'},
      {'name': 'Mustard Seeds', 'description': 'Perfect for seasoning and oil extraction.', 'price': '₹50/kg'},
      {'name': 'Groundnut Seeds', 'description': 'Raw peanuts for snacking or oil.', 'price': '₹70/kg'},
      {'name': 'Corn', 'description': 'Sweet corn for boiling, roasting, or popcorn.', 'price': '₹30/kg'},
      {'name': 'Soybean', 'description': 'Nutritious soybeans, ideal for tofu or soy milk.', 'price': '₹50/kg'},
      {'name': 'Sunflower Seeds', 'description': 'Raw seeds, great for healthy snacking.', 'price': '₹120/kg'},
      {'name': 'Barley', 'description': 'Barley grains for soups and malt beverages.', 'price': '₹35/kg'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Products'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: const Icon(Icons.shopping_cart),
                      title: Text(product['name']!),
                      subtitle: Text(product['description']!),
                      trailing: Text(product['price']!),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
