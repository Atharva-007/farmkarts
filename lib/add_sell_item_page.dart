import 'package:flutter/material.dart';

class AddSellItemPage extends StatefulWidget {
  final Function(String, String, String) onAddItem;

  const AddSellItemPage({super.key, required this.onAddItem});

  @override
  _AddSellItemPageState createState() => _AddSellItemPageState();
}

class _AddSellItemPageState extends State<AddSellItemPage> {
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  void _submitItem() {
    final productName = _productNameController.text.trim();
    final description = _descriptionController.text.trim();
    final price = _priceController.text.trim();

    if (productName.isNotEmpty && description.isNotEmpty && price.isNotEmpty) {
      widget.onAddItem(productName, description, price);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Item for Sale'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _productNameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (₹)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitItem,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Add Item'),
            ),
          ],
        ),
      ),
    );
  }
}
