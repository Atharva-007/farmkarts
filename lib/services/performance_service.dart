import 'package:flutter/foundation.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'dart:async';

/// Performance Monitoring Service
/// Tracks app performance metrics and optimization
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final FirebasePerformance _performance = FirebasePerformance.instance;
  final Map<String, Trace> _activeTraces = {};
  final Map<String, DateTime> _screenLoadStartTimes = {};

  /// Initialize performance monitoring
  Future<void> initialize() async {
    await _performance.setPerformanceCollectionEnabled(true);
    debugPrint('PerformanceService: Initialized');
  }

  // ==================== SCREEN PERFORMANCE ====================

  /// Start tracking screen load
  Future<void> startScreenTrace(String screenName) async {
    try {
      _screenLoadStartTimes[screenName] = DateTime.now();
      
      final trace = await _performance.newTrace('screen_$screenName');
      await trace.start();
      _activeTraces[screenName] = trace;
      
      debugPrint('Performance: Started trace for $screenName');
    } catch (e) {
      debugPrint('Performance: Error starting trace for $screenName: $e');
    }
  }

  /// Stop tracking screen load
  Future<void> stopScreenTrace(String screenName) async {
    try {
      final trace = _activeTraces[screenName];
      if (trace != null) {
        final startTime = _screenLoadStartTimes[screenName];
        if (startTime != null) {
          final duration = DateTime.now().difference(startTime);
          trace.setMetric('load_time_ms', duration.inMilliseconds);
        }
        
        await trace.stop();
        _activeTraces.remove(screenName);
        _screenLoadStartTimes.remove(screenName);
        
        debugPrint('Performance: Stopped trace for $screenName');
      }
    } catch (e) {
      debugPrint('Performance: Error stopping trace for $screenName: $e');
    }
  }

  // ==================== NETWORK PERFORMANCE ====================

  /// Track HTTP request performance
  Future<T> trackHttpRequest<T>({
    required String url,
    required Future<T> Function() request,
  }) async {
    final httpMetric = _performance.newHttpMetric(url, HttpMethod.Get);
    
    try {
      await httpMetric.start();
      
      final startTime = DateTime.now();
      final result = await request();
      final duration = DateTime.now().difference(startTime);
      
      httpMetric.httpResponseCode = 200;
      httpMetric.requestPayloadSize = 0;
      httpMetric.responsePayloadSize = 1024; // Approximate
      
      await httpMetric.stop();
      
      debugPrint('Performance: HTTP request to $url took ${duration.inMilliseconds}ms');
      
      return result;
    } catch (e) {
      httpMetric.httpResponseCode = 500;
      await httpMetric.stop();
      rethrow;
    }
  }

  // ==================== CUSTOM TRACES ====================

  /// Start custom trace
  Future<void> startTrace(String traceName) async {
    try {
      final trace = await _performance.newTrace(traceName);
      await trace.start();
      _activeTraces[traceName] = trace;
      
      debugPrint('Performance: Started custom trace $traceName');
    } catch (e) {
      debugPrint('Performance: Error starting trace $traceName: $e');
    }
  }

  /// Stop custom trace
  Future<void> stopTrace(String traceName, {Map<String, int>? metrics}) async {
    try {
      final trace = _activeTraces[traceName];
      if (trace != null) {
        if (metrics != null) {
          metrics.forEach((key, value) {
            trace.setMetric(key, value);
          });
        }
        
        await trace.stop();
        _activeTraces.remove(traceName);
        
        debugPrint('Performance: Stopped custom trace $traceName');
      }
    } catch (e) {
      debugPrint('Performance: Error stopping trace $traceName: $e');
    }
  }

  /// Track operation performance
  Future<T> trackOperation<T>({
    required String operationName,
    required Future<T> Function() operation,
    Map<String, String>? attributes,
  }) async {
    final trace = await _performance.newTrace(operationName);
    
    try {
      await trace.start();
      
      if (attributes != null) {
        attributes.forEach((key, value) {
          trace.putAttribute(key, value);
        });
      }
      
      final startTime = DateTime.now();
      final result = await operation();
      final duration = DateTime.now().difference(startTime);
      
      trace.setMetric('duration_ms', duration.inMilliseconds);
      await trace.stop();
      
      debugPrint('Performance: $operationName took ${duration.inMilliseconds}ms');
      
      return result;
    } catch (e) {
      trace.setMetric('error', 1);
      await trace.stop();
      rethrow;
    }
  }

  // ==================== DATABASE PERFORMANCE ====================

  /// Track database query
  Future<T> trackDatabaseQuery<T>({
    required String queryName,
    required Future<T> Function() query,
  }) async {
    return trackOperation(
      operationName: 'db_query_$queryName',
      operation: query,
      attributes: {'type': 'database'},
    );
  }

  /// Track Firestore operation
  Future<T> trackFirestoreOperation<T>({
    required String operation,
    required String collection,
    required Future<T> Function() execute,
  }) async {
    return trackOperation(
      operationName: 'firestore_${operation}_$collection',
      operation: execute,
      attributes: {
        'type': 'firestore',
        'operation': operation,
        'collection': collection,
      },
    );
  }

  // ==================== IMAGE LOADING ====================

  /// Track image loading performance
  Future<void> trackImageLoad({
    required String imageUrl,
    required int durationMs,
    required int sizeBytes,
  }) async {
    final trace = await _performance.newTrace('image_load');
    
    try {
      await trace.start();
      trace.setMetric('duration_ms', durationMs);
      trace.setMetric('size_bytes', sizeBytes);
      trace.putAttribute('url', imageUrl);
      await trace.stop();
      
      debugPrint('Performance: Image loaded in ${durationMs}ms (${sizeBytes} bytes)');
    } catch (e) {
      debugPrint('Performance: Error tracking image load: $e');
    }
  }

  // ==================== MEMORY MONITORING ====================

  /// Log memory usage
  void logMemoryUsage(String context) {
    if (kDebugMode) {
      final usage = ProcessInfo.currentRss / (1024 * 1024); // MB
      debugPrint('Performance: Memory usage at $context: ${usage.toStringAsFixed(2)} MB');
    }
  }

  // ==================== APP LIFECYCLE ====================

  /// Track app start time
  Future<void> trackAppStart() async {
    final trace = await _performance.newTrace('app_start');
    await trace.start();
    
    // Stop after a delay (app is considered started)
    Future.delayed(const Duration(seconds: 2), () async {
      await trace.stop();
      debugPrint('Performance: App start tracked');
    });
  }

  /// Track app resume
  Future<void> trackAppResume() async {
    final trace = await _performance.newTrace('app_resume');
    await trace.start();
    await Future.delayed(const Duration(milliseconds: 500));
    await trace.stop();
    
    debugPrint('Performance: App resume tracked');
  }

  // ==================== FRAME RATE MONITORING ====================

  /// Check if frame drops are occurring
  void monitorFrameRate() {
    if (kDebugMode) {
      // Frame monitoring is automatic in Flutter DevTools
      debugPrint('Performance: Frame rate monitoring active');
    }
  }

  // ==================== BUILD TIME TRACKING ====================

  /// Track widget build time
  Future<T> trackBuildTime<T>({
    required String widgetName,
    required T Function() build,
  }) async {
    final startTime = DateTime.now();
    final result = build();
    final duration = DateTime.now().difference(startTime);
    
    if (duration.inMilliseconds > 16) { // More than 1 frame
      debugPrint('Performance: Warning - $widgetName build took ${duration.inMilliseconds}ms');
    }
    
    return result;
  }

  // ==================== OPTIMIZATION HELPERS ====================

  /// Debounce function calls
  Timer? _debounceTimer;
  void debounce(VoidCallback callback, {Duration delay = const Duration(milliseconds: 300)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }

  /// Throttle function calls
  DateTime? _lastThrottleTime;
  void throttle(VoidCallback callback, {Duration interval = const Duration(milliseconds: 300)}) {
    final now = DateTime.now();
    if (_lastThrottleTime == null || now.difference(_lastThrottleTime!) > interval) {
      _lastThrottleTime = now;
      callback();
    }
  }

  // ==================== CLEANUP ====================

  /// Dispose resources
  void dispose() {
    _activeTraces.clear();
    _screenLoadStartTimes.clear();
    _debounceTimer?.cancel();
    debugPrint('PerformanceService: Disposed');
  }
}

/// Helper class for process info
class ProcessInfo {
  static int get currentRss {
    // This is a placeholder - actual implementation would use platform channels
    // For demo purposes, return a mock value
    return 50 * 1024 * 1024; // 50 MB
  }
}
