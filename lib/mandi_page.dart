import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'dart:async';

class MandiPricesPage extends StatefulWidget {
  const MandiPricesPage({super.key});

  @override
  _MandiPricesPageState createState() => _MandiPricesPageState();
}

class _MandiPricesPageState extends State<MandiPricesPage> with SingleTickerProviderStateMixin {
  Map<String, Map<String, List<dynamic>>> mandiDataGrouped = {};
  List<dynamic> allItems = [];
  bool isLoading = true;
  String error = '';
  String searchQuery = '';
  Timer? _debounce;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    fetchMandiPrices();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchMandiPrices() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    const apiUrl =
        'https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070?api-key=579b464db66ec23bdd000001fa4f4f2800bf436b7fe56897564b6555&format=json&limit=1000';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final records = data['records'] as List;

        final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

        // Filter data for today's date
        final filtered = records.where((record) => record['arrival_date'] == today).toList();

        // Group by state and district
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
          allItems = filtered;
          isLoading = false;
        });

        _animationController.forward(from: 0);
      } else {
        setState(() {
          error = 'Failed to load data from server';
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

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        searchQuery = query;
      });
    });
  }

  List<String> getFilteredStateNames() {
    return mandiDataGrouped.keys
        .where((state) => state.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  Widget buildAnimatedCard({required Widget child, required int index}) {
    final Animation<double> animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval((index / 10), 1.0, curve: Curves.easeOut),
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  Widget buildCommodityCard(dynamic item) {
    // Safely extract fields with fallback
    final commodity = item['commodity'] ?? 'N/A';
    final market = item['market'] ?? 'N/A';
    final district = item['district'] ?? 'N/A';
    final state = item['state'] ?? 'N/A';
    final variety = item['variety'] ?? 'N/A';
    final arrivalDate = item['arrival_date'] ?? 'N/A';
    final minPrice = item['min_price'] ?? 'N/A';
    final maxPrice = item['max_price'] ?? 'N/A';
    final modalPrice = item['modal_price'] ?? 'N/A';
    final unit = item['unit'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      shadowColor: Colors.green.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(commodity,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800])),
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                InfoChip(icon: Icons.place, label: '$market, $district'),
                InfoChip(icon: Icons.location_city, label: state),
                InfoChip(icon: Icons.calendar_today, label: 'Date: $arrivalDate'),
                InfoChip(icon: Icons.category, label: 'Variety: $variety'),
              ],
            ),
            Divider(height: 16, thickness: 1, color: Colors.green[200]),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                PriceInfo(title: 'Min Price', price: minPrice, unit: unit, color: Colors.redAccent),
                PriceInfo(title: 'Max Price', price: maxPrice, unit: unit, color: Colors.blueAccent),
                PriceInfo(title: 'Modal Price', price: modalPrice, unit: unit, color: Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTopGrossing() {
    final sorted = List.from(allItems);
    sorted.sort((a, b) {
      final priceA = int.tryParse(a['modal_price'] ?? '0') ?? 0;
      final priceB = int.tryParse(b['modal_price'] ?? '0') ?? 0;
      return priceB.compareTo(priceA);
    });
    final topFive = sorted.take(5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Grossing Commodities',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[900])),
          const SizedBox(height: 6),
          ...topFive.map((item) => buildCommodityCard(item)),
        ],
      ),
    );
  }

  Widget buildLowGrossing() {
    final sorted = List.from(allItems);
    sorted.sort((a, b) {
      final priceA = int.tryParse(a['modal_price'] ?? '0') ?? 0;
      final priceB = int.tryParse(b['modal_price'] ?? '0') ?? 0;
      return priceA.compareTo(priceB);
    });
    final lowFive = sorted.take(5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Low Grossing Commodities',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[900])),
          const SizedBox(height: 6),
          ...lowFive.map((item) => buildCommodityCard(item)),
        ],
      ),
    );
  }

  Widget buildStateCard(String state, Map<String, List<dynamic>> districts, int index) {
    return buildAnimatedCard(
      index: index,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: Colors.green.withOpacity(0.4),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          title: Text(state, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green[800])),
          trailing: Icon(Icons.arrow_forward_ios, color: Colors.green[700]),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, animation, __) =>
                    FadeTransition(opacity: animation, child: StateDetailPage(state: state, districts: districts)),
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          },
        ),
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
                          ...districtEntry.value.map((item) =>
                              pw.Bullet(
                                  text:
                                  '${item['commodity']} - ₹${item['modal_price']} (Min: ₹${item['min_price']}, Max: ₹${item['max_price']}) at ${item['market']}'),
                          ),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredStates = mandiDataGrouped.entries
        .where((entry) => entry.key.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Mandi Prices'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: exportToPdf,
            tooltip: 'Export PDF',
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(child: Text(error))
          : mandiDataGrouped.isEmpty
          ? const Center(child: Text('No data for today'))
          : RefreshIndicator(
        onRefresh: fetchMandiPrices,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by State',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: onSearchChanged,
              ),
            ),
            buildTopGrossing(),
            buildLowGrossing(),
            ...filteredStates.asMap().entries.map((entry) {
              final index = entry.key;
              final stateEntry = entry.value;
              return buildStateCard(stateEntry.key, stateEntry.value, index);
            }).toList(),
          ],
        ),
      ),
    );
  }
}

// Simple reusable widget for info chips with icon and label
class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const InfoChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: Colors.green[50],
      avatar: Icon(icon, size: 16, color: Colors.green[700]),
      label: Text(label, style: TextStyle(color: Colors.green[900], fontSize: 12)),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
    );
  }
}

// Price info widget with title, price, and color for differentiation
class PriceInfo extends StatelessWidget {
  final String title;
  final String price;
  final String unit;
  final Color color;

  const PriceInfo({super.key, required this.title, required this.price, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('₹$price $unit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

// Your unchanged StateDetailPage
class StateDetailPage extends StatelessWidget {
  final String state;
  final Map<String, List<dynamic>> districts;

  const StateDetailPage({super.key, required this.state, required this.districts});

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
            title: Text(district, style: const TextStyle(fontWeight: FontWeight.bold)),
            children: items.map((item) {
              return ListTile(
                title: Text(item['commodity'] ?? 'Unknown'),
                subtitle: Text('Market: ${item['market']}, Variety: ${item['variety'] ?? 'N/A'}'),
                trailing: Text('₹${item['modal_price'] ?? '0'}', style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}
