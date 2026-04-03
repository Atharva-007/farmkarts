import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Performance optimization utility for the FarmKarts app
class PerformanceOptimizer {
  static final PerformanceOptimizer _instance = PerformanceOptimizer._internal();
  factory PerformanceOptimizer() => _instance;
  PerformanceOptimizer._internal();

  /// Debounce helper to prevent excessive function calls
  Timer? _debounceTimer;
  
  void debounce(Duration duration, VoidCallback action) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, action);
  }

  /// Throttle helper to limit function call frequency
  DateTime? _lastThrottle;
  
  void throttle(Duration duration, VoidCallback action) {
    final now = DateTime.now();
    if (_lastThrottle == null || now.difference(_lastThrottle!) >= duration) {
      _lastThrottle = now;
      action();
    }
  }

  /// Run heavy computation in isolate to prevent UI blocking
  static Future<T> runInBackground<T>(ComputeCallback<dynamic, T> callback, dynamic message) async {
    return compute(callback, message);
  }

  /// Schedule frame callback for smooth animations
  static void scheduleFrameCallback(FrameCallback callback) {
    SchedulerBinding.instance.addPostFrameCallback(callback);
  }

  /// Schedule idle callback for non-urgent tasks
  static void scheduleIdleCallback(VoidCallback callback) {
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      callback();
    });
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}

/// Lazy loading wrapper for expensive operations
class LazyLoader<T> {
  T? _value;
  final Future<T> Function() _loader;
  Future<T>? _loadingFuture;

  LazyLoader(this._loader);

  Future<T> get value async {
    if (_value != null) return _value!;
    if (_loadingFuture != null) return _loadingFuture!;
    
    _loadingFuture = _loader();
    _value = await _loadingFuture;
    _loadingFuture = null;
    return _value!;
  }

  bool get isLoaded => _value != null;

  void reset() {
    _value = null;
    _loadingFuture = null;
  }
}

/// Image caching and optimization helper
class ImageOptimizer {
  static const int maxCacheSize = 100;
  static final Map<String, dynamic> _cache = {};

  static void cacheImage(String key, dynamic image) {
    if (_cache.length >= maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = image;
  }

  static dynamic getCachedImage(String key) {
    return _cache[key];
  }

  static void clearCache() {
    _cache.clear();
  }
}

/// Memory management helper
class MemoryManager {
  static void releaseMemory() {
    ImageOptimizer.clearCache();
    // Force garbage collection hint
    if (kDebugMode) {
      print('Memory release requested');
    }
  }
}
