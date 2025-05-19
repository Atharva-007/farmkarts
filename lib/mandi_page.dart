import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class MandiPricesPage extends StatefulWidget {
  @override
  _MandiPricesPageState createState() => _MandiPricesPageState();
}

class _MandiPricesPageState extends State<MandiPricesPage> {
  Map<String, Map<String, List<dynamic>>> mandiDataGrouped = {};
  bool isLoading = true;
  String error = '';
  String searchQuery = '';
  List<dynamic> allItems = [];

  @override
  void initState() {
    super.initState();
    fetchMandiPrices();
  }

  Future<void> fetchMandiPrices() async {
    final apiUrl =
        'https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070?api-key=579b464db66ec23bdd000001fa4f4f2800bf436b7fe56897564b6555&format=json&limit=1000';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final records = data['records'] as List;

        final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

        final filtered = records.where((record) {
          return record['arrival_date'] == today;
        }).toList();

        final grouped = <String, Map<String, List<dynamic>>>{};

        for (var record in filtered) {
          final state = record['state'] ?? 'Unknown';
          final district = record['district'] ?? 'Unknown';

          grouped.putIfAbsent(state, () => {});
          grouped[state]!.putIfAbsent(district, () => []);
          grouped[state]![district]!.add(record);
        }

        setState(() {
          mandiDataGrouped = grouped;
          isLoading = false;
          allItems = filtered;
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

  List<String> getFilteredStateNames() {
    return mandiDataGrouped.keys
        .where((state) => state.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  Widget buildTopGrossing() {
    final sortedItems = List.from(allItems);
    sortedItems.sort((a, b) {
      final priceA = int.tryParse(a['modal_price'] ?? '0') ?? 0;
      final priceB = int.tryParse(b['modal_price'] ?? '0') ?? 0;
      return priceB.compareTo(priceA);
    });

    final topGrossing = sortedItems.take(5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Grossing Commodities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          ...topGrossing.map((item) => ListTile(
            leading: Icon(Icons.trending_up, color: Colors.red),
            title: Text('${item['commodity']}'),
            subtitle: Text('${item['market']} (${item['state']})'),
            trailing: Text('₹${item['modal_price']}', style: TextStyle(fontWeight: FontWeight.bold)),
          )),
        ],
      ),
    );
  }

  Widget buildStateCard(String state, Map<String, List<dynamic>> districts) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(state, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.green[700]),
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  StateDetailPage(state: state, districts: districts),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                final tween = Tween(begin: Offset(1.0, 0.0), end: Offset.zero);
                final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
                return SlideTransition(position: tween.animate(curvedAnimation), child: child);
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> exportToPdf() async {
    final pdf = pw.Document();
    final now = DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Mandi Prices Report - $now')),
          ...mandiDataGrouped.entries.map((stateEntry) =>
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(stateEntry.key, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  ...stateEntry.value.entries.map((districtEntry) =>
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('  ${districtEntry.key}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          ...districtEntry.value.map((item) => pw.Bullet(text: '${item['commodity']} - ₹${item['modal_price']} at ${item['market']}')),
                        ],
                      ),
                  ),
                  pw.SizedBox(height: 10),
                ],
              ),
          )
        ],
      ),
    );

    final status = await Permission.storage.request();
    if (status.isGranted) {
      final directory = await getExternalStorageDirectory();
      final path = '${directory!.path}/mandi_prices_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      Share.shareFiles([file.path], text: 'Mandi Prices PDF Report');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Storage permission is required to save PDF')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredStates = mandiDataGrouped.entries.where((entry) {
      return entry.key.toLowerCase().contains(searchQuery.toLowerCase());
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Live Mandi Prices'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: exportToPdf,
            tooltip: 'Export PDF',
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(child: Text(error))
          : mandiDataGrouped.isEmpty
          ? Center(child: Text('No data for today'))
          : RefreshIndicator(
        onRefresh: fetchMandiPrices,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by State',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),
            buildTopGrossing(),
            Expanded(
              child: ListView(
                children:
                filteredStates.map((entry) => buildStateCard(entry.key, entry.value)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StateDetailPage extends StatelessWidget {
  final String state;
  final Map<String, List<dynamic>> districts;

  StateDetailPage({required this.state, required this.districts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(state),
        backgroundColor: Colors.green[700],
      ),
      body: ListView(
        children: districts.entries.map((entry) {
          final district = entry.key;
          final items = entry.value;
          return ExpansionTile(
            title: Text(district, style: TextStyle(fontWeight: FontWeight.bold)),
            children: items.map((item) {
              return ListTile(
                title: Text(item['commodity'] ?? 'Unknown'),
                subtitle: Text('Market: ${item['market']}, Variety: ${item['variety'] ?? 'N/A'}'),
                trailing: Text('₹${item['modal_price'] ?? '0'}', style: TextStyle(fontWeight: FontWeight.bold)),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}