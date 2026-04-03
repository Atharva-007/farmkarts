# FarmKarts Developer Quick Reference

## 🚀 Quick Start

```bash
# Setup
flutter pub get
flutter clean

# Run
flutter run

# Build
flutter build apk --release
```

---

## 📱 Key Features Access

### Navigation
```dart
// Navigate to page
Navigator.pushNamed(context, '/marketplace');

// Navigate with arguments
Navigator.pushNamed(
  context,
  '/home',
  arguments: {'initialIndex': 1},
);

// Go back
Navigator.pop(context);
```

### Services
```dart
// User State
final userState = Provider.of<UserStateService>(context);
final user = userState.currentUser;

// Language
final locale = Provider.of<LocaleService>(context);
locale.setLocale(Locale('hi')); // Hindi

// Theme
final theme = Provider.of<ThemeService>(context);
theme.setThemeMode(AppThemeMode.dark);

// Wishlist
await WishlistService.addToWishlist(productId);
await WishlistService.removeFromWishlist(productId);

// Cart
await CartService.addToCart(product, quantity);
```

### Localization
```dart
// Get translations
final l10n = AppLocalizations.of(context)!;
Text(l10n.translate('welcome'));
```

---

## 🎨 UI Components

### Universal App Bar
```dart
Scaffold(
  appBar: UniversalAppBar(
    title: 'Page Title',
    subtitle: 'Optional subtitle',
  ),
  drawer: const UniversalDrawer(),
  body: /* content */,
)
```

### Performance Optimizer
```dart
final optimizer = PerformanceOptimizer();

// Debounce
optimizer.debounce(Duration(milliseconds: 300), () {
  performSearch();
});

// Throttle
optimizer.throttle(Duration(seconds: 1), () {
  updateUI();
});

// Background task
final result = await PerformanceOptimizer.runInBackground(
  expensiveFunction,
  data,
);
```

---

## 🔥 Firebase

### Firestore Queries
```dart
// Get products
final products = await FirebaseFirestore.instance
  .collection('products')
  .where('category', isEqualTo: 'vegetables')
  .limit(20)
  .get();

// Real-time updates
FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .snapshots()
  .listen((snapshot) {
    // Handle updates
  });
```

### Authentication
```dart
// Sign in
await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email,
  password: password,
);

// Sign out
await FirebaseAuth.instance.signOut();

// Current user
final user = FirebaseAuth.instance.currentUser;
```

---

## 🐛 Debugging

### Performance
```dart
// Enable performance overlay
MaterialApp(
  showPerformanceOverlay: true,
)

// Monitor frames
SchedulerBinding.instance.addTimingsCallback((timings) {
  print('Frame: ${timings.first.totalSpan.inMilliseconds}ms');
});
```

### Logging
```dart
import 'package:flutter/foundation.dart';

if (kDebugMode) {
  print('Debug message');
}
```

---

## 📦 Common Patterns

### Async Loading
```dart
FutureBuilder<Data>(
  future: loadData(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    if (snapshot.hasError) {
      return ErrorWidget(snapshot.error);
    }
    return DataWidget(snapshot.data!);
  },
)
```

### State Management
```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Safe to call after build
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

---

## ⚡ Performance Tips

1. **Use const constructors**
```dart
const Text('Hello'); // ✅ Good
Text('Hello'); // ❌ Bad
```

2. **Extract widgets**
```dart
// ✅ Good - separate widget
class MyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Card();
}

// ❌ Bad - method
Widget _buildCard() => Card();
```

3. **Cache images**
```dart
CachedNetworkImage(
  imageUrl: url,
  memCacheWidth: 400,
);
```

4. **Limit list items**
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(); // Only builds visible items
  },
)
```

---

## 🔧 Troubleshooting

### Issue: White screen on startup
**Fix:** Check Firebase initialization

### Issue: setState during build
**Fix:** Use PostFrameCallback
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  setState(() {});
});
```

### Issue: Memory leaks
**Fix:** Dispose controllers
```dart
@override
void dispose() {
  controller.dispose();
  super.dispose();
}
```

### Issue: Slow performance
**Fix:** Profile mode + DevTools
```bash
flutter run --profile
```

---

## 📚 Resources

- [Flutter Docs](https://docs.flutter.dev)
- [Firebase Docs](https://firebase.google.com/docs)
- [Provider Docs](https://pub.dev/packages/provider)
- [Performance Guide](./PERFORMANCE_OPTIMIZATION_GUIDE.md)

---

**Last Updated:** 2026-02-13
