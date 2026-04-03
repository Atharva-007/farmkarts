# FarmKarts - Complete Quick Reference Guide v2.0

## 🎨 Pure Dark Mode Implementation

## 🚀 Quick Start

### Running the App
```bash
# Get dependencies
flutter pub get

# Run on device/emulator
flutter run

# Build for production
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

## 📁 Project Structure

```
lib/
├── pages/
│   ├── inventory_page.dart                # ✅ Enhanced inventory management
│   ├── enhanced_order_tracking_page.dart  # ✅ NEW: Advanced order tracking
│   ├── help_support_page.dart             # ✅ Complete support system
│   └── ...
├── models/
│   ├── product_model.dart                 # ✅ Updated with createdAt & rating
│   ├── order_model.dart                   # ✅ Complete order model
│   └── ...
├── services/
│   ├── security_service.dart              # ✅ Comprehensive security
│   ├── order_tracking_service.dart        # ✅ Order management
│   └── ...
└── ...
```

## 🔧 Key Features Usage

### 1. Inventory Management

```dart
// Navigate to inventory page
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => InventoryPage()),
);
```

**Features:**
- ✅ View all products with statistics
- ✅ Search & filter products
- ✅ Sort by multiple criteria
- ✅ Add/Edit/Delete products
- ✅ Bulk stock updates
- ✅ Category analytics
- ✅ Low stock alerts

### 2. Order Tracking

```dart
// Navigate with tracking ID
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => EnhancedOrderTrackingPage(
      trackingId: 'FK1234567890',
    ),
  ),
);

// Or with order ID
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => EnhancedOrderTrackingPage(
      orderId: 'abc123xyz',
    ),
  ),
);
```

**Features:**
- ✅ Real-time order status updates
- ✅ Visual timeline with progress
- ✅ Estimated delivery date
- ✅ Payment information
- ✅ Contact seller/support
- ✅ Share tracking info
- ✅ Cancel orders

### 3. Help & Support

```dart
// Navigate to help page
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => HelpAndSupportPage()),
);
```

**Features:**
- ✅ Comprehensive FAQ system
- ✅ Submit support tickets
- ✅ Track ticket status
- ✅ Multiple contact channels
- ✅ Resource library
- ✅ Security reporting

### 4. Security Service

```dart
import 'package:farmkarts_new/services/security_service.dart';

final security = SecurityService();

// Sanitize user input
final clean = security.sanitizeInput(userInput);

// Validate email
if (!security.isValidEmail(email)) {
  // Show error
}

// Check rate limiting
if (!await security.checkRateLimit(userId, 'search')) {
  // Too many requests
}

// Validate tracking ID
if (!security.validateTrackingId(trackingId)) {
  // Invalid format
}

// Get security score
final score = await security.getSecurityScore();
print('Security score: $score/100');

// Get recommendations
final recommendations = await security.getSecurityRecommendations();
```

## 🎨 Theming

### Using App Theme

```dart
import 'package:farmkarts_new/theme/app_theme.dart';

// Colors
Container(
  color: AppTheme.primaryGreen,      // #4CAF50
  child: Text(
    'FarmKarts',
    style: TextStyle(color: AppTheme.textGrey),
  ),
);

// Status colors
Icon(Icons.check, color: AppTheme.success);    // Green
Icon(Icons.info, color: AppTheme.info);        // Blue
Icon(Icons.warning, color: AppTheme.warning);  // Orange
Icon(Icons.error, color: AppTheme.error);      // Red
```

## 📊 Data Models

### Product Model

```dart
final product = Product(
  id: 'prod123',
  name: 'Fresh Tomatoes',
  description: 'Farm fresh organic tomatoes',
  category: 'Vegetables',
  price: 50.0,
  unit: 'kg',
  imageUrls: ['https://...'],
  sellerId: 'user123',
  sellerName: 'John Farmer',
  location: 'Bangalore',
  timestamp: DateTime.now(),
  createdAt: DateTime.now(),
  isOrganic: true,
  isAvailable: true,
  quantity: 100,
  tags: ['organic', 'fresh'],
  rating: 4.5,
  reviewCount: 25,
);

// Save to Firestore
await firestore.collection('products').doc(product.id).set(product.toMap());
```

### Order Model

```dart
final order = OrderModel(
  id: 'order123',
  productId: 'prod123',
  productName: 'Fresh Tomatoes',
  productCategory: 'Vegetables',
  buyerId: 'buyer123',
  buyerName: 'Jane Doe',
  buyerPhone: '+919876543210',
  buyerAddress: 'Bangalore, Karnataka',
  sellerId: 'seller123',
  sellerName: 'John Farmer',
  sellerPhone: '+919123456780',
  unitPrice: 50.0,
  quantity: 5,
  unit: 'kg',
  totalAmount: 250.0,
  status: OrderStatus.pending,
  paymentStatus: PaymentStatus.paid,
  deliveryType: DeliveryType.delivery,
  orderDate: DateTime.now(),
  createdAt: DateTime.now(),
  trackingId: 'FK${DateTime.now().millisecondsSinceEpoch}',
);
```

## 🔒 Security Best Practices

### 1. Input Validation

```dart
// Always sanitize user input
final sanitized = SecurityService().sanitizeInput(userInput);

// Validate before saving
final validation = SecurityService().validateProductData(productData);
if (!validation['isValid']) {
  print('Errors: ${validation['errors']}');
  return;
}
```

### 2. Authentication Checks

```dart
// Check if user is authenticated
final user = FirebaseAuth.instance.currentUser;
if (user == null) {
  // Redirect to login
  return;
}

// Verify user has access
final hasAccess = await SecurityService().verifyAccess(
  userId: user.uid,
  resourceType: 'order',
  resourceId: orderId,
);

if (!hasAccess) {
  // Show access denied error
  return;
}
```

### 3. Rate Limiting

```dart
// Check before performing action
if (!await SecurityService().checkRateLimit(userId, 'create_order')) {
  ToastHelper.showError(context, 'Too many requests. Please wait.');
  return;
}

// Proceed with action
await createOrder();
```

## 📱 UI Components

### Toast Notifications

```dart
import 'package:farmkarts_new/utils/toast_helper.dart';

ToastHelper.showSuccess(context, 'Order placed successfully!');
ToastHelper.showError(context, 'Failed to process payment');
ToastHelper.showInfo(context, 'Processing your request...');
ToastHelper.showWarning(context, 'Low stock alert');
```

### Loading States

```dart
if (_isLoading) {
  return Center(
    child: CircularProgressIndicator(
      color: AppTheme.primaryGreen,
    ),
  );
}
```

### Empty States

```dart
if (items.isEmpty) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
        SizedBox(height: 16),
        Text('No items found', style: TextStyle(color: Colors.grey[600])),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => _addItem(),
          child: Text('Add Item'),
        ),
      ],
    ),
  );
}
```

## 🐛 Error Handling

### Standard Pattern

```dart
Future<void> _loadData() async {
  if (!mounted) return;
  
  setState(() => _isLoading = true);
  
  try {
    final data = await _fetchData()
        .timeout(
          Duration(seconds: 30),
          onTimeout: () => throw Exception('Request timeout'),
        );
    
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoading = false);
      ToastHelper.showError(context, 'Failed to load: ${e.toString()}');
    }
  }
}
```

## 🔄 Real-time Updates

### Firestore Streams

```dart
Stream<DocumentSnapshot>? _orderStream;

void _setupRealtimeTracking(String orderId) {
  _orderStream = FirebaseFirestore.instance
      .collection('orders')
      .doc(orderId)
      .snapshots();
  
  _orderStream!.listen((snapshot) {
    if (snapshot.exists && mounted) {
      final order = OrderModel.fromMap(
        snapshot.id,
        snapshot.data() as Map<String, dynamic>,
      );
      setState(() => _currentOrder = order);
    }
  });
}

@override
void dispose() {
  // Streams auto-cleanup when widget is disposed
  super.dispose();
}
```

## 📈 Performance Tips

### 1. Limit Query Results

```dart
final snapshot = await firestore
    .collection('products')
    .limit(500)  // Limit for performance
    .get();
```

### 2. Use Cached Images

```dart
CachedNetworkImage(
  imageUrl: product.imageUrls[0],
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

### 3. Optimize Rebuilds

```dart
// Use const constructors when possible
const SizedBox(height: 16),
const Icon(Icons.check),

// Use keys for lists
ListView.builder(
  itemBuilder: (context, index) {
    return ProductCard(
      key: ValueKey(products[index].id),
      product: products[index],
    );
  },
)
```

## 🧪 Testing

### Widget Test Example

```dart
testWidgets('Inventory page shows products', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(home: InventoryPage()),
  );
  
  // Wait for loading
  await tester.pump();
  
  // Verify products are shown
  expect(find.byType(ProductCard), findsWidgets);
});
```

## 🚨 Common Issues & Solutions

### Issue 1: Build Errors
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Issue 2: Firebase Connection
```dart
// Ensure Firebase is initialized
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### Issue 3: Permission Errors
```
Check Firestore security rules - see COMPLETE_FEATURE_IMPLEMENTATION.md
```

## 📞 Support

- **Documentation**: See `COMPLETE_FEATURE_IMPLEMENTATION.md`
- **Issues**: Report bugs in GitHub Issues
- **Email**: support@farmkarts.com
- **Phone**: +91 1800-123-4567

## ✅ Checklist for New Features

- [ ] Add proper error handling
- [ ] Implement loading states
- [ ] Add empty states
- [ ] Sanitize user inputs
- [ ] Add authentication checks
- [ ] Implement rate limiting
- [ ] Add analytics tracking
- [ ] Write tests
- [ ] Update documentation
- [ ] Security audit

---

**Version**: 2.0.0  
**Last Updated**: February 9, 2026  
**Status**: Production Ready ✅
