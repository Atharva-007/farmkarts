import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/firebase_options.dart';
import 'lib/services/marketplace_service.dart';
import 'lib/models/product_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(TestFirebaseApp());
}

class TestFirebaseApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Test',
      home: TestPage(),
    );
  }
}

class TestPage extends StatefulWidget {
  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  String _status = 'Testing Firebase connection...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _testFirebase();
  }

  Future<void> _testFirebase() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing Firebase connection...';
    });

    try {
      // Test 1: Check Firebase initialization
      setState(() {
        _status = 'Step 1: Firebase initialized ✓\n';
      });

      // Test 2: Test Firestore connection
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('test').doc('connection').set({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Connection test'
      });
      
      setState(() {
        _status += 'Step 2: Firestore connection ✓\n';
      });

      // Test 3: Test anonymous authentication
      final auth = FirebaseAuth.instance;
      await auth.signInAnonymously();
      
      setState(() {
        _status += 'Step 3: Anonymous auth ✓\n';
      });

      // Test 4: Test product addition
      final testProduct = Product(
        id: '',
        name: 'Test Product',
        description: 'This is a test product to validate Firebase integration',
        category: 'Vegetables',
        price: 100.0,
        unit: 'kg',
        imageUrls: [],
        sellerId: auth.currentUser!.uid,
        sellerName: 'Test Seller',
        location: 'Test Location',
        timestamp: DateTime.now(),
        isOrganic: false,
        isAvailable: true,
        quantity: 10,
        tags: ['test'],
      );

      final productId = await _marketplaceService.addProduct(testProduct, auth.currentUser!.uid);
      
      setState(() {
        _status += 'Step 4: Product added ✓ (ID: $productId)\n';
      });

      // Test 5: Test product retrieval
      final products = await _marketplaceService.getProducts();
      
      setState(() {
        _status += 'Step 5: Products retrieved ✓ (${products.length} products)\n';
      });

      // Test 6: Test selling history
      final sellingHistory = await _marketplaceService.getSellingHistoryByUser(auth.currentUser!.uid);
      
      setState(() {
        _status += 'Step 6: Selling history retrieved ✓ (${sellingHistory.length} records)\n';
      });

      setState(() {
        _status += '\n🎉 All tests passed! Firebase is working correctly.';
      });

    } catch (e) {
      setState(() {
        _status += '\n❌ Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firebase Test'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              LinearProgressIndicator(),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _status,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 14),
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _testFirebase,
                  child: Text('Run Test Again'),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await FirebaseAuth.instance.signOut();
                      setState(() {
                        _status = 'Signed out. Ready for new test.';
                      });
                    } catch (e) {
                      setState(() {
                        _status = 'Error signing out: $e';
                      });
                    }
                  },
                  child: Text('Sign Out'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}