import 'package:flutter/foundation.dart';

/// Centralized logging utility for the FarmKarts app.
/// Only logs in debug mode to avoid performance overhead in production.
class AppLogger {
  /// Enable/disable all logging
  static const bool _enabled = kDebugMode;

  /// Log debug information (development only)
  static void debug(String message, [String? tag]) {
    if (_enabled) {
      final prefix = tag != null ? '[$tag]' : '[DEBUG]';
      debugPrint('$prefix $message');
    }
  }

  /// Log informational messages (development only)
  static void info(String message, [String? tag]) {
    if (_enabled) {
      final prefix = tag != null ? '[$tag]' : '[INFO]';
      debugPrint('$prefix $message');
    }
  }

  /// Log warnings (always logged)
  static void warning(String message, [String? tag]) {
    final prefix = tag != null ? '[$tag]' : '[WARN]';
    debugPrint('$prefix $message');
  }

  /// Log errors with optional error object and stack trace
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    final prefix = tag != null ? '[$tag]' : '[ERROR]';
    debugPrint('$prefix $message${error != null ? ": $error" : ""}');
    if (stackTrace != null && _enabled) {
      debugPrint('Stack trace:\n$stackTrace');
    }
  }
}
