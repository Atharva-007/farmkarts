import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Batch processor for efficient bulk operations
class BatchProcessor {
  static const int maxBatchSize = 500;
  static const Duration batchDelay = Duration(milliseconds: 100);

  final FirebaseFirestore _firestore;
  final List<_BatchOperation> _operations = [];
  Timer? _batchTimer;

  BatchProcessor(this._firestore);

  /// Add operation to batch
  Future<void> addOperation(_BatchOperation operation) async {
    _operations.add(operation);

    if (_operations.length >= maxBatchSize) {
      await _processBatch();
    } else {
      _scheduleBatch();
    }
  }

  void _scheduleBatch() {
    _batchTimer?.cancel();
    _batchTimer = Timer(batchDelay, _processBatch);
  }

  Future<void> _processBatch() async {
    if (_operations.isEmpty) return;

    _batchTimer?.cancel();

    final batch = _firestore.batch();
    final operationsToProcess = List<_BatchOperation>.from(_operations);
    _operations.clear();

    try {
      for (final operation in operationsToProcess) {
        switch (operation.type) {
          case _OperationType.set:
            batch.set(operation.reference, operation.data!);
            break;
          case _OperationType.update:
            batch.update(operation.reference, operation.data!);
            break;
          case _OperationType.delete:
            batch.delete(operation.reference);
            break;
        }
      }

      await batch.commit();
      debugPrint('Batch processed: ${operationsToProcess.length} operations');
    } catch (e) {
      debugPrint('Batch processing error: $e');
      // Re-add failed operations
      _operations.addAll(operationsToProcess);
      rethrow;
    }
  }

  /// Flush all pending operations
  Future<void> flush() async {
    await _processBatch();
  }

  void dispose() {
    _batchTimer?.cancel();
  }
}

enum _OperationType { set, update, delete }

class _BatchOperation {
  final DocumentReference reference;
  final _OperationType type;
  final Map<String, dynamic>? data;

  _BatchOperation({
    required this.reference,
    required this.type,
  });
}
