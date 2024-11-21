import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddSellItemPage extends StatefulWidget {
  final Function(String, String, String) onAddItem;

  AddSellItemPage({required this.onAddItem});

  @override
  _AddSellItemPageState createState() => _AddSellItemPageState();
}

class _AddSellItemPageState extends State<AddSellItemPage> {
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _submit() async {
    final String productName = _productNameController.text.trim();
    final String description = _descriptionController.text.trim();
    final String price = _priceController.text.trim();

    if (productName.isNotEmpty && description.isNotEmpty && price.isNotEmpty) {
      try {
        await _firestore.collection('itemsForSale').add({
          'productName': productName,
          'description': description,
          'price': price,
          'createdAt': FieldValue.serverTimestamp(),
        });

        widget.onAddItem(productName, description, price); // Call the callback
        Navigator.pop(context); // Close the page
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all the fields'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _productNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Product Name',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Description',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Price',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Add Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
