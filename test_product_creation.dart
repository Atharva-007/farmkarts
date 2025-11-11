import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lib/services/product_service.dart';
import 'lib/firebase_options.dart';

/// Standalone test for product creation functionality
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('🔥 Initializing Firebase...');
    
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    print('✅ Firebase initialized successfully!');
    
    // Test authentication
    print('🔐 Testing authentication...');
    final auth = FirebaseAuth.instance;
    
    try {
      // Try to sign in anonymously for testing
      final userCredential = await auth.signInAnonymously();
      print('✅ Anonymous authentication successful: ${userCredential.user?.uid}');
    } catch (authError) {
      print('⚠️  Anonymous auth failed, trying existing user: $authError');
    }
    
    final user = auth.currentUser;
    if (user == null) {
      print('❌ No authenticated user found');
      return;
    }
    
    print('👤 Authenticated user: ${user.uid}');
    
    // Test ProductService
    print('📦 Testing ProductService...');
    final productService = ProductService();
    
    // Test product creation
    print('✍️ Testing product creation...');
    final testProductId = await productService.createProduct(
      name: 'Test Product ${DateTime.now().millisecondsSinceEpoch}',
      description: 'This is a test product created by automated test',
      category: 'Vegetables',
      price: 100.0,
      unit: 'kg',
      quantity: 50,
      location: 'Test Farm Location',
      tags: ['test', 'vegetables', 'fresh'],
      isOrganic: true,
    );
    
    print('✅ Product created successfully with ID: $testProductId');
    
    // Test product retrieval
    print('📖 Testing product retrieval...');
    final products = await productService.getProducts(limit: 5);
    print('✅ Retrieved ${products.length} products');
    
    // Test selling history
    print('📈 Testing selling history...');
    final sellingHistory = await productService.getSellingHistoryByUser(user.uid);
    final historyCount = sellingHistory['history']?.length ?? 0;
    print('✅ Retrieved selling history with $historyCount records');
    
    print('🎉 All product tests passed successfully!');
    
  } catch (e) {
    print('❌ Product test failed: $e');
    print('🔍 Error details: ${e.runtimeType}');
    print('📍 Stack trace: ${StackTrace.current}');
  }
}