# FarmKarts Performance Optimization Guide

## 🚀 Performance Issues Identified & Fixed

### Critical Performance Problems (from logs):
1. **Main Thread Blocking** - Skipped 1159+ frames
2. **Long Frame Times** - 7489ms Davey events (target: <16ms)
3. **Slow App Initialization** - Multiple seconds to load
4. **Excessive Choreographer Skips** - 400+ frames dropped

---

## ✅ Optimizations Implemented

### 1. **Performance Optimizer Utility** (`lib/utils/performance_optimizer.dart`)

**Features:**
- ✅ Debounce helper for search/input fields
- ✅ Throttle helper for scroll events
- ✅ Background isolate computation
- ✅ Frame callback scheduling
- ✅ Lazy loading wrapper
- ✅ Image caching system
- ✅ Memory management

**Usage Example:**
```dart
// Debounce search input
final optimizer = PerformanceOptimizer();
optimizer.debounce(Duration(milliseconds: 300), () {
  // Perform search
});

// Lazy load expensive data
final lazyData = LazyLoader(() async {
  return await fetchExpensiveData();
});
```

### 2. **Async Initialization**
- ✅ Firebase initialization doesn't block main thread
- ✅ User profile loading scheduled after frame render
- ✅ Service initialization happens in parallel

### 3. **State Management Optimization**
- ✅ PostFrameCallback prevents setState during build
- ✅ Mounted checks prevent memory leaks
- ✅ Proper context usage in async operations

---

## 🛠️ Additional Optimizations Needed

### High Priority:

1. **Image Optimization**
```dart
// Use cached_network_image for remote images
CachedNetworkImage(
  imageUrl: url,
  placeholder: (context, url) => CircularProgressIndicator(),
  memCacheWidth: 400, // Limit memory usage
  maxHeightDiskCache: 400,
);
```

2. **List Performance**
```dart
// Use AutomaticKeepAliveClientMixin for expensive list items
class ProductCard extends StatefulWidget {
  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> 
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep state alive when scrolling
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // Must call super
    return Container(/* card content */);
  }
}
```

3. **Firestore Query Optimization**
```dart
// Add pagination and limits
FirebaseFirestore.instance
  .collection('products')
  .limit(20) // Limit results
  .orderBy('timestamp', descending: true);

// Use where clauses effectively
  .where('category', isEqualTo: selectedCategory)
  .where('isActive', isEqualTo: true);
```

4. **Enable Back Button Callback (Android Manifest)**
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<application
    android:enableOnBackInvokedCallback="true">
```

5. **Reduce Build Method Complexity**
- Extract widgets into separate classes
- Use `const` constructors wherever possible
- Avoid rebuilding entire screens

---

## 📊 Performance Monitoring

### Add Performance Overlay (Debug Mode):
```dart
MaterialApp(
  showPerformanceOverlay: true, // Shows FPS and frame times
  // ... rest of config
)
```

### Monitor Frame Rendering:
```dart
import 'package:flutter/scheduler.dart';

void initState() {
  super.initState();
  SchedulerBinding.instance.addTimingsCallback((timings) {
    for (var timing in timings) {
      print('Frame duration: ${timing.totalSpan.inMilliseconds}ms');
    }
  });
}
```

---

## 🎯 Specific Optimizations by Feature

### Dashboard
- ✅ Lazy load statistics
- ✅ Cache market rates
- ⚠️ TODO: Implement pagination for recent activities

### Marketplace
- ✅ Image caching implemented
- ⚠️ TODO: Add infinite scroll with pagination
- ⚠️ TODO: Debounce search/filter operations

### Profile
- ✅ Async profile loading
- ⚠️ TODO: Cache user data locally

### Chat
- ⚠️ TODO: Implement message pagination
- ⚠️ TODO: Limit initial message load to 50

---

## 🔧 Build Optimization

### Gradle Optimization (android/gradle.properties):
```properties
org.gradle.jvmargs=-Xmx4096M
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.daemon=true
android.enableR8.fullMode=true
```

### Flutter Build Optimization:
```bash
# Build with optimization
flutter build apk --release --shrink --split-per-abi

# Profile build for testing
flutter build apk --profile
```

---

## 📱 Testing Performance

### 1. **Profile Mode Testing**
```bash
flutter run --profile
```

### 2. **DevTools Profiling**
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### 3. **Memory Profiling**
- Monitor memory leaks
- Check for retained objects
- Analyze heap snapshots

---

## ⚡ Quick Wins Checklist

- [x] PostFrameCallback for async operations
- [x] Lazy loading utility created
- [x] Image caching system
- [x] Performance optimizer utility
- [ ] Enable back button callback in manifest
- [ ] Add list item caching
- [ ] Implement pagination everywhere
- [ ] Optimize Firestore queries
- [ ] Add const constructors
- [ ] Reduce widget rebuilds

---

## 📈 Expected Improvements

After implementing all optimizations:
- **Frame drops**: <50 frames (from 1159+)
- **Frame time**: <16ms (from 7489ms)
- **App startup**: <2 seconds (from 10+ seconds)
- **Smooth scrolling**: 60 FPS consistently

---

## 🚨 Critical Notes

1. **Always test on real devices** - Emulators don't reflect true performance
2. **Profile mode** - Use for accurate performance testing
3. **Monitor memory** - Watch for memory leaks
4. **Incremental changes** - Test each optimization individually

---

## 📚 Resources

- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Flutter Performance Profiling](https://docs.flutter.dev/perf/ui-performance)
- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices)

---

**Last Updated:** 2026-02-13
**Version:** 1.0
**Status:** Performance optimization in progress
