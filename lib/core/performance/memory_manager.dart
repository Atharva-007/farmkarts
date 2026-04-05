import 'dart:async';
import 'package:flutter/foundation.dart';

/// Memory manager for optimal memory usage under high load
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  final Map<String, _CacheEntry> _cache = {};
  final Map<String, List<Function>> _listeners = {};

  static const int maxCacheSize = 1000;
  static const Duration cacheExpiry = Duration(minutes: 5);

  Timer? _cleanupTimer;

  void initialize() {
    // Periodic cache cleanup
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _cleanup();
    });
  }

  /// Store data in memory cache
  void cache<T>(String key, T data, {Duration? expiry}) {
    if (_cache.length >= maxCacheSize) {
      _evictOldest();
    }

    _cache[key] = _CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      expiry: expiry ?? cacheExpiry,
    );

    _notifyListeners(key, data);
  }

  /// Retrieve cached data
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (DateTime.now().difference(entry.timestamp) > entry.expiry) {
      _cache.remove(key);
      return null;
    }

    return entry.data as T?;
  }

  /// Listen to cache updates
  void addListener(String key, Function(dynamic) callback) {
    _listeners.putIfAbsent(key, () => []).add(callback);
  }

  void removeListener(String key, Function callback) {
    _listeners[key]?.remove(callback);
  }

  void _notifyListeners(String key, dynamic data) {
    _listeners[key]?.forEach((callback) {
      try {
        callback(data);
      } catch (e) {
        debugPrint('Error in cache listener: $e');
      }
    });
  }

  void _cleanup() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) {
      return now.difference(entry.timestamp) > entry.expiry;
    });
  }

  void _evictOldest() {
    if (_cache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    _cache.forEach((key, entry) {
      if (oldestTime == null || entry.timestamp.isBefore(oldestTime!)) {
        oldestKey = key;
        oldestTime = entry.timestamp;
      }
    });

    if (oldestKey != null) {
      _cache.remove(oldestKey);
    }
  }

  /// Clear specific cache entry
  void invalidate(String key) {
    _cache.remove(key);
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    return {
      'size': _cache.length,
      'maxSize': maxCacheSize,
      'listeners': _listeners.length,
    };
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
    _listeners.clear();
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration expiry;

  _CacheEntry({
    required this.data,
    required this.timestamp,
    required this.expiry,
  });
}
