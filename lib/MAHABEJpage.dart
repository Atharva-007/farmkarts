import 'package:flutter/material.dart';

class MahabejPage extends StatelessWidget {
  const MahabejPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mahabej'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildElementTile('Mahabej Element 1', 'Description for Element 1'),
          _buildElementTile('Mahabej Element 2', 'Description for Element 2'),
          _buildElementTile('Mahabej Element 3', 'Description for Element 3'),
          // Add more elements as needed
        ],
      ),
    );
  }

  Widget _buildElementTile(String title, String subtitle) {
    return ListTile(
      leading: const Icon(Icons.grass, color: Colors.green),
      title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      onTap: () {
        // Handle tap to show details
      },
    );
  }
}
