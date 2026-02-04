import 'package:flutter/material.dart';
import 'models/product_model.dart';
import 'features/marketplace/functional_product_detail_page.dart';

/// Test page to demonstrate the functional product detail page
class TestFunctionalProductDetail extends StatelessWidget {
  const TestFunctionalProductDetail({super.key});

  @override
  Widget build(BuildContext context) {
    // Create a sample product for testing
    final sampleProduct = Product(
      id: 'test_product_1',
      name: 'Fresh Organic Tomatoes',
      description: 'Premium quality organic tomatoes grown without pesticides. Perfect for salads, cooking, and making fresh sauces. Harvested daily to ensure maximum freshness.',
      category: 'Vegetables',
      price: 45.0,
      unit: 'kg',
      imageUrls: [
        'https://images.unsplash.com/photo-1546470427-b2821167fcee?w=500',
        'https://images.unsplash.com/photo-1582284540020-8acbe03f4924?w=500',
      ],
      sellerId: 'seller_123',
      sellerName: 'Ramesh Kumar Farm',
      location: 'Pune, Maharashtra',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      isOrganic: true,
      isAvailable: true,
      quantity: 50,
      tags: ['fresh', 'organic', 'local', 'pesticide-free'],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Detail Test'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Test Functional Product Detail',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FunctionalProductDetailPage(
                      product: sampleProduct,
                      onContactSeller: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Contact seller functionality working! 📞'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('View Product Detail'),
            ),
            const SizedBox(height: 20),
            const Text(
              'This will open the fully functional\nproduct detail page with all features working.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}