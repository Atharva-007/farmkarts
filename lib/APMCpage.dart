import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApmcPage extends StatefulWidget {
  const ApmcPage({super.key});

  @override
  _ApmcPageState createState() => _ApmcPageState();
}

class _ApmcPageState extends State<ApmcPage> {
  late Future<List<dynamic>> _apmcData;

  // Fetch data from APMC API
  Future<List<dynamic>> _fetchApmcData() async {
    const apiUrl = 'https://api-url-goes-here.com'; // Replace with actual URL
    const apiKey = '579b464db66ec23bdd000001cdd3946e44ce4aad7209ff7b23ac571b';

    final response = await http.get(Uri.parse(apiUrl), headers: {
      'Authorization': 'Bearer $apiKey',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : [data]; // Ensure it returns a list
    } else {
      throw Exception('Failed to load APMC data');
    }
  }

  @override
  void initState() {
    super.initState();
    _apmcData = _fetchApmcData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('APMC Data'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _apmcData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No APMC data available.'));
          }

          final apmcData = snapshot.data!;
          return ListView.builder(
            itemCount: apmcData.length,
            itemBuilder: (context, index) {
              final item = apmcData[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 4,
                child: ListTile(
                  title: Text(
                    item['market_name'] ?? 'Market Name',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Commodity: ${item['commodity'] ?? 'N/A'}'),
                      const SizedBox(height: 4),
                      Text('Price: ₹${item['price'] ?? 'N/A'}'),
                      const SizedBox(height: 4),
                      Text('Arrival: ${item['arrival'] ?? 'N/A'}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
