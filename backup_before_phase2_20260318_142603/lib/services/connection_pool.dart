import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Connection pool manager for efficient Firestore operations
class ConnectionPool {
  static final ConnectionPool _instance = ConnectionPool._internal();
  factory ConnectionPool() => _instance;
  ConnectionPool._internal() {
    _initialize();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Request queue for batching
  final Map<String, List<_QueuedRequest>> _requestQueue = {};
  Timer? _batchTimer;
  
  // Rate limiting
  final Map<String, DateTime> _lastRequestTime = {};
  static const Duration _minRequestInterval = Duration(milliseconds: 100);
  
  // Batch configuration
  static const int _maxBatchSize = 500;
  static const Duration _batchInterval = Duration(milliseconds: 50);

  void _initialize() {
    // Enable persistence for offline support
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    
    // Start batch processor
    _batchTimer = Timer.periodic(_batchInterval, (_) => _processBatches());
  }

  /// Queue a read request for batching
  Future<DocumentSnapshot?> queueRead(String collection, String docId) {
    final completer = Completer<DocumentSnapshot?>();
    final key = '$collection:$docId';
    
    _requestQueue.putIfAbsent(collection, () => []);
    _requestQueue[collection]!.add(_QueuedRequest(
      docId: docId,
      completer: completer,
      type: _RequestType.read,
    ));
    
    if (_requestQueue[collection]!.length >= _maxBatchSize) {
      _processBatch(collection);
    }
    
    return completer.future;
  }

  /// Batch write operations
  Future<void> batchWrite(List<WriteBatch> operations) async {
    try {
      await Future.wait(operations.map((batch) => batch.commit()));
    } catch (e) {
      debugPrint('Batch write error: $e');
      rethrow;
    }
  }

  /// Process all pending batches
  void _processBatches() {
    for (var collection in _requestQueue.keys.toList()) {
      if (_requestQueue[collection]!.isNotEmpty) {
        _processBatch(collection);
      }
    }
  }

  /// Process a single batch
  Future<void> _processBatch(String collection) async {
    final requests = _requestQueue[collection] ?? [];
    if (requests.isEmpty) return;
    
    final batch = requests.take(_maxBatchSize).toList();
    _requestQueue[collection]!.removeRange(0, batch.length);
    
    try {
      // Group by operation type
      final reads = batch.where((r) => r.type == _RequestType.read).toList();
      
      if (reads.isNotEmpty) {
        await _processBatchReads(collection, reads);
      }
    } catch (e) {
      debugPrint('Batch processing error: $e');
      for (var request in batch) {
        request.completer.completeError(e);
      }
    }
  }

  /// Process batch reads
  Future<void> _processBatchReads(String collection, List<_QueuedRequest> reads) async {
    try {
      // Fetch all documents in parallel with limited concurrency
      const concurrentLimit = 10;
      
      for (var i = 0; i < reads.length; i += concurrentLimit) {
        final chunk = reads.skip(i).take(concurrentLimit);
        await Future.wait(
          chunk.map((request) async {
            try {
              final doc = await _firestore
                  .collection(collection)
                  .doc(request.docId)
                  .get();
              request.completer.complete(doc);
            } catch (e) {
              request.completer.completeError(e);
            }
          }),
        );
      }
    } catch (e) {
      debugPrint('Batch read error: $e');
      rethrow;
    }
  }

  /// Rate-limited query execution
  Future<QuerySnapshot> rateLimitedQuery(
    Query query,
    String queryKey,
  ) async {
    final lastRequest = _lastRequestTime[queryKey];
    if (lastRequest != null) {
      final elapsed = DateTime.now().difference(lastRequest);
      if (elapsed < _minRequestInterval) {
        await Future.delayed(_minRequestInterval - elapsed);
      }
    }
    
    _lastRequestTime[queryKey] = DateTime.now();
    return await query.get();
  }

  /// Optimized pagination query
  Stream<QuerySnapshot> paginatedQuery({
    required Query query,
    required int pageSize,
    DocumentSnapshot? startAfter,
  }) {
    var paginatedQuery = query.limit(pageSize);
    
    if (startAfter != null) {
      paginatedQuery = paginatedQuery.startAfterDocument(startAfter);
    }
    
    return paginatedQuery.snapshots();
  }

  /// Cleanup resources
  void dispose() {
    _batchTimer?.cancel();
    _requestQueue.clear();
    _lastRequestTime.clear();
  }
}

enum _RequestType { read, write }

class _QueuedRequest {
  final String docId;
  final Completer<DocumentSnapshot?> completer;
  final _RequestType type;

  _QueuedRequest({
    required this.docId,
    required this.completer,
    required this.type,
  });
}
