import 'dart:async';
import 'package:flutter/foundation.dart';

/// Performance monitoring for high-traffic scenarios
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  // Metrics storage
  final Map<String, List<double>> _metrics = {};
  final Map<String, int> _errorCounts = {};
  final Map<String, DateTime> _lastErrors = {};
  
  // Active operations tracking
  int _activeOperations = 0;
  int _peakConcurrentOps = 0;
  
  // Performance thresholds
  static const Duration _slowOperationThreshold = Duration(milliseconds: 500);
  static const int _maxConcurrentOps = 1000;

  /// Track operation performance
  Future<T> trackOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final startTime = DateTime.now();
    _activeOperations++;
    
    if (_activeOperations > _peakConcurrentOps) {
      _peakConcurrentOps = _activeOperations;
    }
    
    if (_activeOperations > _maxConcurrentOps) {
      debugPrint('⚠️ WARNING: High concurrent operations: $_activeOperations');
    }
    
    try {
      final result = await operation();
      final duration = DateTime.now().difference(startTime);
      
      _recordMetric(operationName, duration.inMilliseconds.toDouble());
      
      if (duration > _slowOperationThreshold) {
        debugPrint('🐌 Slow operation "$operationName": ${duration.inMilliseconds}ms');
      }
      
      return result;
    } catch (e) {
      _recordError(operationName);
      rethrow;
    } finally {
      _activeOperations--;
    }
  }

  /// Record metric
  void _recordMetric(String name, double value) {
    _metrics.putIfAbsent(name, () => []);
    _metrics[name]!.add(value);
    
    // Keep only last 1000 entries per metric
    if (_metrics[name]!.length > 1000) {
      _metrics[name]!.removeAt(0);
    }
  }

  /// Record error
  void _recordError(String operationName) {
    _errorCounts[operationName] = (_errorCounts[operationName] ?? 0) + 1;
    _lastErrors[operationName] = DateTime.now();
  }

  /// Get performance report
  Map<String, dynamic> getReport() {
    final report = <String, dynamic>{};
    
    for (var entry in _metrics.entries) {
      final values = entry.value;
      if (values.isEmpty) continue;
      
      final avg = values.reduce((a, b) => a + b) / values.length;
      final sorted = List<double>.from(values)..sort();
      final p50 = sorted[(sorted.length * 0.5).floor()];
      final p95 = sorted[(sorted.length * 0.95).floor()];
      final p99 = sorted[(sorted.length * 0.99).floor()];
      
      report[entry.key] = {
        'avg': avg.toStringAsFixed(2),
        'p50': p50.toStringAsFixed(2),
        'p95': p95.toStringAsFixed(2),
        'p99': p99.toStringAsFixed(2),
        'count': values.length,
        'errors': _errorCounts[entry.key] ?? 0,
      };
    }
    
    report['system'] = {
      'activeOps': _activeOperations,
      'peakOps': _peakConcurrentOps,
      'totalErrors': _errorCounts.values.fold(0, (a, b) => a + b),
    };
    
    return report;
  }

  /// Print performance report
  void printReport() {
    final report = getReport();
    debugPrint('📊 Performance Report:');
    debugPrint(report.toString());
  }

  /// Reset all metrics
  void reset() {
    _metrics.clear();
    _errorCounts.clear();
    _lastErrors.clear();
    _peakConcurrentOps = 0;
  }

  /// Get current system load
  double getSystemLoad() {
    if (_maxConcurrentOps == 0) return 0;
    return _activeOperations / _maxConcurrentOps;
  }

  /// Check if system is overloaded
  bool isOverloaded() {
    return getSystemLoad() > 0.8;
  }
}

/// Performance tracking mixin for widgets
mixin PerformanceTracking {
  final _monitor = PerformanceMonitor();
  
  Future<T> trackPerformance<T>(String operation, Future<T> Function() fn) {
    return _monitor.trackOperation(operation, fn);
  }
}
