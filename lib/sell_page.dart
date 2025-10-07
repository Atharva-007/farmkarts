import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'add_sell_item_page.dart'; // Make sure this path is correct

class SellPage extends StatefulWidget {
  const SellPage({super.key});

  @override
  _SellPageState createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://farmkart-9f4f3-default-rtdb.firebaseio.com/',
  ).ref().child('itemsForSale');

  final List<Map<String, dynamic>> _itemsForSale = [];

  @override
  void initState() {
    super.initState();
    _listenToDatabase();
  }

  void _listenToDatabase() {
    _dbRef.orderByChild('timestamp').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final List<Map<String, dynamic>> loadedItems = [];
        data.forEach((key, value) {
          loadedItems.add({
            'key': key,
            'productName': value['productName'],
            'description': value['description'],
            'price': value['price'],
            'timestamp': value['timestamp'],
          });
        });

        loadedItems.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

        setState(() {
          _itemsForSale
            ..clear()
            ..addAll(loadedItems);
        });
      } else {
        setState(() => _itemsForSale.clear());
      }
    });
  }

  void _addItemToDatabase(String productName, String description, String price) {
    final newItem = {
      'productName': productName,
      'description': description,
      'price': price,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    _dbRef.push().set(newItem);
  }

  void _navigateToAddSellItemPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSellItemPage(
          onAddItem: _addItemToDatabase,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'No items added yet!',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sell Items'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Items for Sale',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _itemsForSale.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                itemCount: _itemsForSale.length,
                itemBuilder: (context, index) {
                  final item = _itemsForSale[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        item['productName'] ?? 'No Name',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            item['description'] ?? 'No Description',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Price: ₹${item['price'] ?? '0.00'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddSellItemPage,
        tooltip: 'Add New Item',
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
