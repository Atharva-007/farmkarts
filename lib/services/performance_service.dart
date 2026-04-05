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
    try {
      await _performance.setPerformanceCollectionEnabled(true);
      debugPrint('PerformanceService: Initialized');
    } catch (e) {
      debugPrint('PerformanceService: Init error: $e');
    }
  }

  // ==================== SCREEN PERFORMANCE ====================

  /// Start tracking screen load
  Future<void> startScreenTrace(String screenName) async {
    if (kIsWeb) return; // Custom traces are buggy on web

    try {
      _screenLoadStartTimes[screenName] = DateTime.now();

      final trace = _performance.newTrace('screen_$screenName');
      await trace.start();
      _activeTraces[screenName] = trace;

      debugPrint('Performance: Started trace for $screenName');
    } catch (e) {
      debugPrint('Performance: Error starting trace for $screenName: $e');
    }
  }

  /// Stop tracking screen load
  Future<void> stopScreenTrace(String screenName) async {
    if (kIsWeb) return;

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

  // ==================== CUSTOM TRACES ====================

  /// Start custom trace
  Future<void> startTrace(String traceName) async {
    if (kIsWeb) return;

    try {
      final trace = _performance.newTrace(traceName);
      await trace.start();
      _activeTraces[traceName] = trace;

      debugPrint('Performance: Started custom trace $traceName');
    } catch (e) {
      debugPrint('Performance: Error starting trace $traceName: $e');
    }
  }

  /// Stop custom trace
  Future<void> stopTrace(String traceName, {Map<String, int>? metrics}) async {
    if (kIsWeb) return;

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
    if (kIsWeb) return await operation();

    final trace = _performance.newTrace(operationName);

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

      debugPrint(
          'Performance: $operationName took ${duration.inMilliseconds}ms');

      return result;
    } catch (e) {
      try {
        trace.setMetric('error', 1);
        await trace.stop();
      } catch (_) {}
      rethrow;
    }
  }

  // ==================== APP LIFECYCLE ====================

  /// Track app start time
  Future<void> trackAppStart() async {
    if (kIsWeb) return;

    try {
      final trace = _performance.newTrace('app_start');
      await trace.start();

      // Stop after a delay (app is considered started)
      Future.delayed(const Duration(seconds: 2), () async {
        try {
          await trace.stop();
          debugPrint('Performance: App start tracked');
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('Performance: Error tracking app start: $e');
    }
  }
}
