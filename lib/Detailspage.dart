import 'package:flutter/material.dart';

class DetailsPage extends StatelessWidget {
  final String category;

  const DetailsPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    // Determine the list of elements based on the category
    final List<Map<String, String>> elements = category == 'Mahabej'
        ? [
      {'title': 'Mahabej Element 1', 'description': 'Description for Mahabej Element 1'},
      {'title': 'Mahabej Element 2', 'description': 'Description for Mahabej Element 2'},
      {'title': 'Mahabej Element 3', 'description': 'Description for Mahabej Element 3'},
    ]
        : [
      {'title': 'APMC Element 1', 'description': 'Description for APMC Element 1'},
      {'title': 'APMC Element 2', 'description': 'Description for APMC Element 2'},
      {'title': 'APMC Element 3', 'description': 'Description for APMC Element 3'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(category),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: elements.length,
        itemBuilder: (context, index) {
          final element = elements[index];
          return _buildElementTile(element['title']!, element['description']!);
        },
      ),
    );
  }

  Widget _buildElementTile(String title, String description) {
    return ListTile(
      leading: const Icon(Icons.info, color: Colors.blue),
      title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      subtitle: Text(description),
      onTap: () {
        // Handle tap to show details
      },
    );
  }
}

class YourHomePage extends StatelessWidget {
  const YourHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Column(
        children: <Widget>[
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DetailsPage(category: 'Mahabej'),
                ),
              );
            },
            child: const Text('Mahabej'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DetailsPage(category: 'APMC'),
                ),
              );
            },
            child: const Text('APMC'),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: YourHomePage(),
  ));
}
