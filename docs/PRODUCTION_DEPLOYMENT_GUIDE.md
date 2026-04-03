# 🚀 FarmKarts Production Deployment Guide

## 📋 Table of Contents
1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Firebase Configuration](#firebase-configuration)
3. [Authentication Setup](#authentication-setup)
4. [Firestore Rules & Indexes](#firestore-rules--indexes)
5. [Performance Optimization](#performance-optimization)
6. [Scalability for 10,000+ Users](#scalability-for-10000-users)
7. [Monitoring & Analytics](#monitoring--analytics)
8. [Security Best Practices](#security-best-practices)
9. [CI/CD Pipeline](#cicd-pipeline)
10. [Troubleshooting](#troubleshooting)

---

## ✅ Pre-Deployment Checklist

### 1. Environment Setup
- [ ] Flutter SDK installed (v3.13.9+)
- [ ] Firebase CLI installed (`npm install -g firebase-tools`)
- [ ] Firebase project created
- [ ] Google Cloud Console access
- [ ] Android Studio / Xcode configured

### 2. Firebase Services Enabled
- [ ] Authentication (Email, Phone, Google)
- [ ] Cloud Firestore
- [ ] Cloud Storage
- [ ] Cloud Functions (optional)
- [ ] Firebase Analytics
- [ ] Firebase Performance Monitoring
- [ ] Firebase Crashlytics

### 3. API Keys Configured
```yaml
# android/app/google-services.json ✓
# ios/Runner/GoogleService-Info.plist ✓
# .env file created with API keys
```

---

## 🔐 Firebase Configuration

### 1. Update Firebase Config
```bash
# Login to Firebase
firebase login

# Initialize project
firebase init

# Select:
# - Firestore
# - Storage
# - Functions (optional)
```

### 2. Environment Variables
Create `.env` file:
```env
FIREBASE_API_KEY=AIzaSyAYGPfM-kQ5jIZzRNN059ASTo2Wiy-CHd8
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_STORAGE_BUCKET=your-storage-bucket
```

### 3. Android Configuration
`android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Required for Firebase
        targetSdkVersion 34
        multiDexEnabled true
    }
}

dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-analytics'
    implementation 'com.google.firebase:firebase-crashlytics'
}
```

### 4. iOS Configuration
`ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

---

## 🔑 Authentication Setup

### 1. Enable Authentication Methods

#### Email/Password
```bash
Firebase Console → Authentication → Sign-in method → Email/Password → Enable
```

#### Phone Authentication
```bash
Firebase Console → Authentication → Sign-in method → Phone → Enable

# Add Test Numbers (for development)
+1 650-555-1234 → 123456
```

#### Google Sign-In
```bash
Firebase Console → Authentication → Sign-in method → Google → Enable

# Add SHA-1 and SHA-256 fingerprints
# Get fingerprints:
cd android
./gradlew signingReport
```

### 2. Usage in App

```dart
import 'package:farmkarts_new/services/multi_auth_service.dart';

// Email/Password Sign In
final authService = MultiAuthService();
await authService.signInWithEmailOrMobile('user@example.com', 'password');

// Phone Sign In
await authService.sendOTP(
  phoneNumber: '+1234567890',
  onCodeSent: (msg) => print(msg),
  onVerificationFailed: (error) => print(error),
  onAutoVerify: (credential) => print('Auto verified'),
);
await authService.verifyOTP(otp: '123456', name: 'John', role: UserRole.farmer);

// Google Sign In
await authService.signInWithGoogle(name: 'John', role: UserRole.farmer);
```

---

## 🗄️ Firestore Rules & Indexes

### 1. Deploy Firestore Rules
```bash
firebase deploy --only firestore:rules
```

### 2. Deploy Indexes
```bash
firebase deploy --only firestore:indexes
```

### 3. Optimize Indexes for Scale

`firestore.indexes.json`:
```json
{
  "indexes": [
    {
      "collectionGroup": "products",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "category", "order": "ASCENDING" },
        { "fieldPath": "isAvailable", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "products",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "tags", "arrayConfig": "CONTAINS" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "buyerId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

---

## ⚡ Performance Optimization

### 1. Enable Caching
```dart
// In main.dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

### 2. Connection Pooling
Already implemented in `lib/services/connection_pool.dart`

### 3. Image Optimization
```dart
// Use cached_network_image
CachedNetworkImage(
  imageUrl: product.imageUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
  maxHeightDiskCache: 800,
  maxWidthDiskCache: 800,
  memCacheHeight: 400,
  memCacheWidth: 400,
);
```

### 4. Lazy Loading
```dart
// Implement pagination
ListView.builder(
  itemCount: products.length + 1,
  itemBuilder: (context, index) {
    if (index == products.length) {
      return _buildLoadMoreButton();
    }
    return ProductCard(product: products[index]);
  },
);
```

---

## 🚀 Scalability for 10,000+ Users

### 1. Firestore Optimization

#### Batch Writes
```dart
final batch = FirebaseFirestore.instance.batch();
for (var product in products) {
  final ref = FirebaseFirestore.instance.collection('products').doc();
  batch.set(ref, product.toMap());
}
await batch.commit();
```

#### Query Optimization
```dart
// Use indexes
final query = FirebaseFirestore.instance
    .collection('products')
    .where('category', isEqualTo: category)
    .where('isAvailable', isEqualTo: true)
    .orderBy('timestamp', descending: true)
    .limit(20);
```

### 2. Caching Strategy

```dart
// lib/services/cache_manager.dart is already implemented
final cacheManager = CacheManager();
final cachedProducts = await cacheManager.getProducts('category_vegetables');
```

### 3. Connection Pool
```dart
// lib/services/connection_pool.dart is already implemented
final pool = ConnectionPool();
await pool.initialize();
```

### 4. Performance Monitoring
```dart
// lib/services/performance_monitor.dart is already implemented
PerformanceMonitor.startTrace('load_products');
// ... load products
PerformanceMonitor.stopTrace('load_products');
```

### 5. Load Balancing

#### Cloud Functions (Optional)
```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.processOrder = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snap, context) => {
    const order = snap.data();
    // Process order asynchronously
    return admin.firestore()
      .collection('notifications')
      .add({
        userId: order.sellerId,
        message: `New order: ${order.productName}`,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });
  });
```

### 6. Rate Limiting
```dart
// Implement rate limiting in SecurityService
final canProceed = await SecurityService.checkRateLimit(userId, 'create_product');
if (!canProceed) {
  throw Exception('Too many requests. Please try again later.');
}
```

---

## 📊 Monitoring & Analytics

### 1. Firebase Analytics
```dart
import 'package:firebase_analytics/firebase_analytics.dart';

final analytics = FirebaseAnalytics.instance;

// Log events
await analytics.logEvent(
  name: 'product_viewed',
  parameters: {
    'product_id': product.id,
    'category': product.category,
  },
);
```

### 2. Crashlytics
```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

// Log custom errors
try {
  // code
} catch (error, stackTrace) {
  FirebaseCrashlytics.instance.recordError(error, stackTrace);
}
```

### 3. Performance Monitoring
```dart
import 'package:firebase_performance/firebase_performance.dart';

final trace = FirebasePerformance.instance.newTrace('load_marketplace');
await trace.start();
// ... load data
await trace.stop();
```

---

## 🔒 Security Best Practices

### 1. Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User data
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Products
    match /products/{productId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.sellerId;
    }
    
    // Orders
    match /orders/{orderId} {
      allow read: if request.auth.uid == resource.data.buyerId 
                  || request.auth.uid == resource.data.sellerId;
      allow create: if request.auth != null;
      allow update: if request.auth.uid == resource.data.sellerId;
    }
  }
}
```

### 2. Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /products/{productId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null
                   && request.resource.size < 5 * 1024 * 1024 // 5MB
                   && request.resource.contentType.matches('image/.*');
    }
  }
}
```

### 3. API Key Security
```dart
// Never commit API keys to version control
// Use environment variables
const apiKey = String.fromEnvironment('API_KEY');
```

### 4. Input Validation
```dart
// Validate all user inputs
final isValid = SecurityService.validateInput(userInput);
if (!isValid) {
  throw Exception('Invalid input');
}
```

---

## 🔄 CI/CD Pipeline

### 1. GitHub Actions

`.github/workflows/deploy.yml`:
```yaml
name: Deploy to Firebase

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.13.9'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run tests
        run: flutter test
      
      - name: Build APK
        run: flutter build apk --release
      
      - name: Deploy to Firebase
        uses: w9jds/firebase-action@master
        with:
          args: deploy
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
```

### 2. Automated Testing
```bash
# Run all tests
flutter test

# Run integration tests
flutter test integration_test/

# Run with coverage
flutter test --coverage
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Authentication Errors
```
Error: user-not-found
Solution: Check if user exists before sign-in
```

#### 2. Firestore Permission Denied
```
Error: PERMISSION_DENIED
Solution: Update firestore.rules and deploy
```

#### 3. Storage Upload Failed
```
Error: unauthorized
Solution: Check storage.rules and authentication status
```

#### 4. OTP Not Received
```
Solution: 
- Check phone number format (+CountryCode)
- Enable Phone Authentication in Firebase Console
- Verify SHA-256 fingerprint is added
```

### Performance Issues

#### Slow Queries
```dart
// Add indexes
// Use limit()
// Implement pagination
final query = collection.limit(20);
```

#### Memory Leaks
```dart
// Dispose controllers
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

#### High Bandwidth Usage
```dart
// Use caching
// Compress images
// Implement lazy loading
```

---

## 📱 Build & Release

### Android Release

1. **Generate Keystore**
```bash
keytool -genkey -v -keystore farmkarts-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias farmkarts
```

2. **Configure Signing**
`android/key.properties`:
```properties
storePassword=your-password
keyPassword=your-password
keyAlias=farmkarts
storeFile=farmkarts-release-key.jks
```

3. **Build Release APK**
```bash
flutter build apk --release
```

4. **Build App Bundle**
```bash
flutter build appbundle --release
```

### iOS Release

1. **Configure Xcode**
- Open `ios/Runner.xcworkspace`
- Set Team and Bundle ID
- Configure Code Signing

2. **Build Release**
```bash
flutter build ios --release
```

3. **Upload to App Store**
- Use Xcode Organizer
- Or use Fastlane

---

## 📈 Scaling Checklist

### For 10,000+ Concurrent Users

- [✓] Connection pooling implemented
- [✓] Caching layer active
- [✓] Performance monitoring enabled
- [✓] Firestore indexes optimized
- [✓] Rate limiting configured
- [✓] Security service active
- [✓] Multi-region support (optional)
- [✓] CDN for static assets
- [✓] Database sharding strategy
- [✓] Load testing completed

### Load Testing
```bash
# Use Firebase Test Lab
gcloud firebase test android run \
  --app app-debug.apk \
  --test app-debug-test.apk
```

---

## 🎯 Post-Deployment

### 1. Monitor Metrics
- Firebase Console → Analytics
- Check user engagement
- Monitor crash-free rate
- Track performance metrics

### 2. User Feedback
- Set up in-app feedback
- Monitor app store reviews
- Track support tickets

### 3. Regular Updates
- Weekly bug fixes
- Monthly feature updates
- Quarterly major releases

---

## 📞 Support

For issues or questions:
- GitHub Issues: [Your Repo]
- Email: support@farmkarts.app
- Documentation: https://docs.farmkarts.app

---

**Last Updated:** February 13, 2026
**App Version:** 1.0.0
**Flutter Version:** 3.13.9
**Firebase SDK:** Latest
