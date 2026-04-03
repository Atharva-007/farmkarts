import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Temporarily disabled

class MandiPricesPage extends StatefulWidget {
  const MandiPricesPage({super.key});

  @override
  _MandiPricesPageState createState() => _MandiPricesPageState();
}

class _MandiPricesPageState extends State<MandiPricesPage>
    with SingleTickerProviderStateMixin {
  Map<String, Map<String, List<dynamic>>> mandiDataGrouped = {};
  bool isLoading = true;
  String error = '';
  String searchQuery = '';
  List<dynamic> allItems = [];

  // Filters
  String selectedCommodity = 'All';
  String selectedMarket = 'All';

  // All unique commodities & markets for filter dropdowns
  List<String> commodities = ['All'];
  List<String> markets = ['All'];

  // Map controller & markers
  GoogleMapController? mapController;
  Set<Marker> mapMarkers = {};

  // Notification plugin - temporarily disabled
  // late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _initNotifications();
    fetchMandiPrices();
  }

  void _initNotifications() {
    // Temporarily disabled
    /*
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    flutterLocalNotificationsPlugin.initialize(settings);
    */
  }

  Future<void> showNotification(String title, String body) async {
    // Temporarily disabled
    /*
    const androidDetails = AndroidNotificationDetails(
      'mandi_price_channel',
      'Mandi Price Alerts',
      channelDescription: 'Notifications for mandi price changes',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
    */
  }

  @override
  void dispose() {
    _animationController.dispose();
    mapController?.dispose();
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

        final filtered = records.where((record) {
          final arrivalDate = record['arrival_date'] ?? '';
          return arrivalDate == today;
        }).toList();

        final grouped = <String, Map<String, List<dynamic>>>{};

        // Extract unique commodities and markets for filters
        Set<String> uniqueCommodities = {};
        Set<String> uniqueMarkets = {};

        for (var record in filtered) {
          final state = record['state'] ?? 'Unknown';
          final district = record['district'] ?? 'Unknown';

          grouped.putIfAbsent(state, () => {});
          grouped[state]!.putIfAbsent(district, () => []);
          grouped[state]![district]!.add(record);

          uniqueCommodities.add(record['commodity'] ?? 'Unknown');
          uniqueMarkets.add(record['market'] ?? 'Unknown');
        }

        setState(() {
          mandiDataGrouped = grouped;
          isLoading = false;
          allItems = filtered;
          commodities = ['All'] + uniqueCommodities.toList()..sort();
          markets = ['All'] + uniqueMarkets.toList()..sort();

          _animationController.forward(from: 0);

          // Update map markers for all items
          updateMapMarkers(filtered);

          // Simulate a notification for highest price commodity of today
          if (filtered.isNotEmpty) {
            var topItem = filtered.reduce((curr, next) {
              final currPrice = int.tryParse(curr['modal_price'] ?? '0') ?? 0;
              final nextPrice = int.tryParse(next['modal_price'] ?? '0') ?? 0;
              return (currPrice > nextPrice) ? curr : next;
            });
            showNotification(
                "Top Commodity Today",
                "${topItem['commodity']} at ₹${topItem['modal_price']} in ${topItem['market']}");
          }
        });
      } else {
        setState(() {
          error = 'Failed to load data. Status code: ${response.statusCode}';
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

  void updateMapMarkers(List<dynamic> items) {
    Set<Marker> markers = {};

    // Note: The data source doesn’t have lat/lng so here
    // we simulate by geocoding state+district or market to fixed coordinates.
    // In real app, you need proper lat/lng from API or external geocode service.

    // Simple mock lat/lng for demonstration (randomly assigned)
    Map<String, LatLng> fakeCoordinates = {
      "Delhi": const LatLng(28.7041, 77.1025),
      "Mumbai": const LatLng(19.0760, 72.8777),
      "Kolkata": const LatLng(22.5726, 88.3639),
      "Chennai": const LatLng(13.0827, 80.2707),
      "Bangalore": const LatLng(12.9716, 77.5946),
      "Hyderabad": const LatLng(17.3850, 78.4867),
      "Ahmedabad": const LatLng(23.0225, 72.5714),
      "Pune": const LatLng(18.5204, 73.8567),
    };

    for (var item in items) {
      final marketName = item['market'] ?? '';
      final latLng = fakeCoordinates[marketName] ??
          const LatLng(20.5937, 78.9629); // Default India center coords

      markers.add(
        Marker(
          markerId: MarkerId(marketName + (item['commodity'] ?? '')),
          position: latLng,
          infoWindow: InfoWindow(
            title: item['commodity'],
            snippet:
            '${item['market']}, ₹${item['modal_price'] ?? 'N/A'}',
          ),
        ),
      );
    }

    setState(() {
      mapMarkers = markers;
    });
  }

  List<dynamic> getTopGrossing(int count) {
    final filtered = _applyFilters(allItems);
    final sortedItems = List.from(filtered);
    sortedItems.sort((a, b) {
      final priceA = int.tryParse(a['modal_price'] ?? '0') ?? 0;
      final priceB = int.tryParse(b['modal_price'] ?? '0') ?? 0;
      return priceB.compareTo(priceA);
    });
    return sortedItems.take(count).toList();
  }

  List<dynamic> getLowGrossing(int count) {
    final filtered = _applyFilters(allItems);
    final sortedItems = List.from(filtered);
    sortedItems.sort((a, b) {
      final priceA = int.tryParse(a['modal_price'] ?? '0') ?? 0;
      final priceB = int.tryParse(b['modal_price'] ?? '0') ?? 0;
      return priceA.compareTo(priceB);
    });
    return sortedItems.take(count).toList();
  }

  List<dynamic> _applyFilters(List<dynamic> items) {
    return items.where((item) {
      final commodity = item['commodity'] ?? '';
      final market = item['market'] ?? '';

      bool matchesCommodity =
          selectedCommodity == 'All' || commodity == selectedCommodity;
      bool matchesMarket = selectedMarket == 'All' || market == selectedMarket;

      bool matchesSearch = searchQuery.isEmpty ||
          (item['state'] ?? '')
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase());

      return matchesCommodity && matchesMarket && matchesSearch;
    }).toList();
  }

  Future<void> exportToPdf() async {
    final pdf = pw.Document();
    final now = DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Mandi Prices Report - $now')),
          ...mandiDataGrouped.entries.map((stateEntry) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(stateEntry.key,
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ...stateEntry.value.entries.map((districtEntry) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('  ${districtEntry.key}',
                      style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold)),
                  ...districtEntry.value
                      .where((item) {
                    final commodity = item['commodity'] ?? '';
                    final market = item['market'] ?? '';
                    if (selectedCommodity != 'All' &&
                        commodity != selectedCommodity) {
                      return false;
                    }
                    if (selectedMarket != 'All' &&
                        market != selectedMarket) {
                      return false;
                    }
                    if (searchQuery.isNotEmpty &&
                        !(item['state'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(searchQuery.toLowerCase())) {
                      return false;
                    }
                    return true;
                  })
                      .map((item) => pw.Bullet(
                      text:
                      '${item['commodity']} - ₹${item['modal_price']} at ${item['market']}'))
                      .toList(),
                ],
              )),
              pw.SizedBox(height: 10),
            ],
          ))
        ],
      ),
    );

    final status = await Permission.storage.request();
    if (status.isGranted) {
      final directory = await getExternalStorageDirectory();
      final path =
          '${directory!.path}/mandi_prices_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      final xFile = XFile(file.path);
      Share.shareXFiles([xFile], text: 'Mandi Prices PDF Report');
    } else {
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredStates = mandiDataGrouped.entries.where((entry) {
      return entry.key.toLowerCase().contains(searchQuery.toLowerCase());
    });

    // Apply filters to all items for top/low grossing and map
    final filteredItems = _applyFilters(allItems);
    updateMapMarkers(filteredItems);

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
          ? Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: ListView.builder(
          itemCount: 6,
          itemBuilder: (_, __) => Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      )
          : error.isNotEmpty
          ? Center(child: Text(error))
          : RefreshIndicator(
        onRefresh: fetchMandiPrices,
        child: ListView(
          padding: const EdgeInsets.only(top: 12),
          children: [
            // Existing Top and Low grossing chips
            buildGrossingChips('Top Grossing', Icons.trending_up,
                getTopGrossing(5)),
            buildGrossingChips('Low Grossing', Icons.trending_down,
                getLowGrossing(5)),








            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filters',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800])),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Commodity',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                          ),
                          value: selectedCommodity,
                          items: commodities
                              .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCommodity = value ?? 'All';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Market',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                          ),
                          value: selectedMarket,
                          items: markets
                              .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m),
                          ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedMarket = value ?? 'All';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search by State',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      setState(() {
                        searchQuery = val.trim();
                      });
                    },
                  ),
                ],
              ),
            ),

            // Map Section
            Container(
              height: 250,
              margin:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green),
              ),
              child: GoogleMap(
                onMapCreated: (controller) {
                  mapController = controller;
                },
                initialCameraPosition: const CameraPosition(
                  target: LatLng(20.5937, 78.9629), // Center of India
                  zoom: 4.5,
                ),
                markers: mapMarkers,
                myLocationButtonEnabled: false,
              ),
            ),

            // List of states and markets as before with animation
            ...filteredStates.map((stateEntry) {
              final filteredDistricts = stateEntry.value.entries
                  .where((districtEntry) {
                final anyMatch = districtEntry.value.any((item) {
                  final commodity = item['commodity'] ?? '';
                  final market = item['market'] ?? '';
                  if (selectedCommodity != 'All' &&
                      commodity != selectedCommodity) {
                    return false;
                  }
                  if (selectedMarket != 'All' &&
                      market != selectedMarket) {
                    return false;
                  }
                  if (searchQuery.isNotEmpty &&
                      !(item['state'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase())) {
                    return false;
                  }
                  return true;
                });
                return anyMatch;
              });

              if (filteredDistricts.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stateEntry.key,
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900])),
                    const SizedBox(height: 6),
                    ...filteredDistricts.map((districtEntry) {
                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                        margin:
                        const EdgeInsets.symmetric(vertical: 6),
                        child: ExpansionTile(
                          title: Text(districtEntry.key,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          children: districtEntry.value
                              .where((item) {
                            final commodity = item['commodity'] ?? '';
                            final market = item['market'] ?? '';
                            if (selectedCommodity != 'All' &&
                                commodity != selectedCommodity) {
                              return false;
                            }
                            if (selectedMarket != 'All' &&
                                market != selectedMarket) {
                              return false;
                            }
                            if (searchQuery.isNotEmpty &&
                                !(item['state'] ?? '')
                                    .toString()
                                    .toLowerCase()
                                    .contains(searchQuery.toLowerCase())) {
                              return false;
                            }
                            return true;
                          })
                              .map((item) => ListTile(
                            title: Text(item['commodity']),
                            subtitle: Text(
                                'Market: ${item['market']}'),
                            trailing: Text(
                              '₹${item['modal_price']}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700]),
                            ),
                          ))
                              .toList(),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget buildGrossingChips(
      String label, IconData icon, List<dynamic> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green[800])),
          const SizedBox(height: 6),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return Chip(
                  avatar: Icon(icon, size: 18, color: Colors.white),
                  backgroundColor: Colors.green,
                  label: Text(
                    '${item['commodity']} ₹${item['modal_price']}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

