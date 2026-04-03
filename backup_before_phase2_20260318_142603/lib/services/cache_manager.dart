import 'dart:collection';
import 'package:flutter/foundation.dart';

/// High-performance cache manager for handling 10k+ concurrent users
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  // LRU Cache with configurable size
  final Map<String, _CacheEntry> _cache = LinkedHashMap();
  final Map<String, List<Function>> _subscribers = {};
  
  // Cache configuration
  static const int _maxCacheSize = 5000;
  static const Duration _defaultTTL = Duration(minutes: 15);
  static const Duration _longTTL = Duration(hours: 1);
  static const Duration _shortTTL = Duration(minutes: 5);

  /// Get data from cache with automatic expiry check
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    
    // Move to end (LRU)
    _cache.remove(key);
    _cache[key] = entry;
    
    return entry.data as T?;
  }

  /// Set data in cache with optional TTL
  void set(String key, dynamic data, {Duration? ttl}) {
    // Remove oldest entries if cache is full
    if (_cache.length >= _maxCacheSize) {
      final keysToRemove = _cache.keys.take((_maxCacheSize * 0.1).round()).toList();
      for (var k in keysToRemove) {
        _cache.remove(k);
      }
    }
    
    _cache[key] = _CacheEntry(
      data: data,
      expiresAt: DateTime.now().add(ttl ?? _defaultTTL),
    );
    
    // Notify subscribers
    _notifySubscribers(key, data);
  }

  /// Remove specific key from cache
  void remove(String key) {
    _cache.remove(key);
  }

  /// Remove all keys matching pattern
  void removePattern(String pattern) {
    final regex = RegExp(pattern);
    _cache.removeWhere((key, value) => regex.hasMatch(key));
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    int expired = 0;
    for (var entry in _cache.values) {
      if (entry.isExpired) expired++;
    }
    
    return {
      'size': _cache.length,
      'maxSize': _maxCacheSize,
      'expired': expired,
      'hitRate': _hitRate,
    };
  }

  /// Subscribe to cache updates
  void subscribe(String key, Function(dynamic) callback) {
    _subscribers.putIfAbsent(key, () => []);
    _subscribers[key]!.add(callback);
  }

  /// Unsubscribe from cache updates
  void unsubscribe(String key, Function callback) {
    _subscribers[key]?.remove(callback);
  }

  void _notifySubscribers(String key, dynamic data) {
    final callbacks = _subscribers[key];
    if (callbacks != null) {
      for (var callback in callbacks) {
        try {
          callback(data);
        } catch (e) {
          debugPrint('Error notifying subscriber: $e');
        }
      }
    }
  }

  // Cache hit rate tracking
  int _hits = 0;
  int _misses = 0;
  double get _hitRate => _hits + _misses == 0 ? 0 : _hits / (_hits + _misses);

  void _recordHit() => _hits++;
  void _recordMiss() => _misses++;
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiresAt;

  _CacheEntry({required this.data, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Cache keys for different data types
class CacheKeys {
  static String product(String id) => 'product_$id';
  static String productList(String category, String filter) => 'products_${category}_$filter';
  static String userProfile(String uid) => 'user_$uid';
  static String apmcPrices(String market) => 'apmc_$market';
  static String conversation(String id) => 'conversation_$id';
  static String weatherData(String location) => 'weather_$location';
}
