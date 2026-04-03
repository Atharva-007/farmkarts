import 'package:flutter_test/flutter_test.dart';
import 'package:farmkarts_new/services/performance_service.dart';

void main() {
  group('PerformanceService Tests', () {
    late PerformanceService performanceService;

    setUp(() {
      performanceService = PerformanceService();
    });

    test('Should initialize successfully', () async {
      await performanceService.initialize();
      expect(performanceService, isNotNull);
    });

    test('Should track screen load time', () async {
      const screenName = 'TestScreen';
      
      await performanceService.startScreenTrace(screenName);
      await Future.delayed(const Duration(milliseconds: 100));
      await performanceService.stopScreenTrace(screenName);
      
      // Test passes if no exceptions
      expect(true, true);
    });

    test('Should track custom operation', () async {
      final result = await performanceService.trackOperation<String>(
        operationName: 'test_operation',
        operation: () async {
          await Future.delayed(const Duration(milliseconds: 50));
          return 'success';
        },
      );
      
      expect(result, 'success');
    });

    test('Should handle operation errors gracefully', () async {
      expect(
        () => performanceService.trackOperation<void>(
          operationName: 'failing_operation',
          operation: () async {
            throw Exception('Test error');
          },
        ),
        throwsException,
      );
    });

    test('Should debounce function calls', () async {
      int callCount = 0;
      
      for (int i = 0; i < 5; i++) {
        performanceService.debounce(() => callCount++);
      }
      
      await Future.delayed(const Duration(milliseconds: 400));
      
      // Should only call once due to debouncing
      expect(callCount, 1);
    });

    test('Should throttle function calls', () {
      int callCount = 0;
      
      for (int i = 0; i < 10; i++) {
        performanceService.throttle(() => callCount++);
      }
      
      // Should only call once due to throttling
      expect(callCount, 1);
    });

    tearDown(() {
      performanceService.dispose();
    });
  });
}
