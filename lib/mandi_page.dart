import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class MandiPricesPage extends StatefulWidget {
  @override
  _MandiPricesPageState createState() => _MandiPricesPageState();
}

class _MandiPricesPageState extends State<MandiPricesPage> {
  List<dynamic> mandiData = [];
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    fetchMandiPrices();
  }

  Future<void> fetchMandiPrices() async {
    final apiUrl =
        'https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070?api-key=579b464db66ec23bdd000001fa4f4f2800bf436b7fe56897564b6555&format=json&limit=100';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final records = data['records'] as List;

        // Get today's date in DD/MM/YYYY format
        final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

        final filtered = records.where((record) {
          return record['arrival_date'] == today;
        }).toList();

        setState(() {
          mandiData = filtered;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load data';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error fetching data: $e';
        isLoading = false;
      });
    }
  }

  Widget buildCard(dynamic item) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        title: Text('${item['commodity']} - ₹${item['modal_price']}'),
        subtitle: Text(
          '${item['market']}, ${item['district']}, ${item['state']}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Min: ₹${item['min_price']}'),
            Text('Max: ₹${item['max_price']}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Mandi Prices'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(child: Text(error))
          : mandiData.isEmpty
          ? Center(child: Text('No data for today'))
          : RefreshIndicator(
        onRefresh: fetchMandiPrices,
        child: ListView.builder(
          itemCount: mandiData.length,
          itemBuilder: (context, index) =>
              buildCard(mandiData[index]),
        ),
      ),
    );
  }
}
