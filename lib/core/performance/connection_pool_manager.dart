import 'dart:async';

/// Connection pool manager for efficient Firestore operations
class ConnectionPoolManager {
  static final ConnectionPoolManager _instance =
      ConnectionPoolManager._internal();
  factory ConnectionPoolManager() => _instance;
  ConnectionPoolManager._internal();

  // Connection pool settings
  static const int maxConcurrentRequests = 50;
  static const Duration requestTimeout = Duration(seconds: 10);

  final _requestQueue = <_QueuedRequest>[];
  int _activeRequests = 0;

  /// Execute a Firestore query with connection pooling
  Future<T> executeQuery<T>(Future<T> Function() query,
      {String? cacheKey}) async {
    final completer = Completer<T>();

    final request = _QueuedRequest(
      execute: () async {
        try {
          final result = await query().timeout(requestTimeout);
          completer.complete(result);
        } catch (e) {
          completer.completeError(e);
        } finally {
          _activeRequests--;
          _processQueue();
        }
      },
      completer: completer,
    );

    _requestQueue.add(request);
    _processQueue();

    return completer.future;
  }

  void _processQueue() {
    while (
        _requestQueue.isNotEmpty && _activeRequests < maxConcurrentRequests) {
      final request = _requestQueue.removeAt(0);
      _activeRequests++;
      request.execute();
    }
  }

  /// Get current queue status
  Map<String, int> getStatus() {
    return {
      'queueLength': _requestQueue.length,
      'activeRequests': _activeRequests,
      'availableSlots': maxConcurrentRequests - _activeRequests,
    };
  }
}

class _QueuedRequest {
  final Future<void> Function() execute;
  final Completer completer;

  _QueuedRequest({
    required this.execute,
    required this.completer,
  });
}
