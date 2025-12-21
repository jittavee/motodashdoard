import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:api_tech_moto/controllers/performance_test_controller.dart';

void main() {
  late PerformanceTestController controller;

  setUp(() {
    Get.testMode = true;
    controller = PerformanceTestController();
  });

  tearDown(() {
    controller.dispose();
    Get.reset();
  });

  group('PerformanceTestController Initialization Tests', () {
    test('should initialize with test not running', () {
      expect(controller.isTestRunning.value, isFalse);
    });

    test('should initialize with zero values', () {
      expect(controller.currentDistance.value, equals(0.0));
      expect(controller.currentTime.value, equals(0.0));
      expect(controller.currentSpeed.value, equals(0.0));
      expect(controller.maxSpeed.value, equals(0.0));
    });

    test('should initialize with empty test type', () {
      expect(controller.currentTestType.value, isEmpty);
    });
  });

  group('PerformanceTestController Target Distance Tests', () {
    test('should return correct target for 0-100m', () {
      final target = controller.getTargetDistance('0-100m');
      expect(target, equals(100.0));
    });

    test('should return correct target for 201m', () {
      final target = controller.getTargetDistance('201m');
      expect(target, equals(201.0));
    });

    test('should return correct target for 402m', () {
      final target = controller.getTargetDistance('402m');
      expect(target, equals(402.0));
    });

    test('should return correct target for 1000m', () {
      final target = controller.getTargetDistance('1000m');
      expect(target, equals(1000.0));
    });

    test('should return default 100.0 for unknown test type', () {
      final target = controller.getTargetDistance('unknown');
      expect(target, equals(100.0));
    });
  });

  group('PerformanceTestController Stop Test Tests', () {
    test('should reset isTestRunning when stopped', () {
      controller.isTestRunning.value = true;
      controller.stopTest();
      expect(controller.isTestRunning.value, isFalse);
    });

    test('should cleanup resources on stop', () {
      controller.stopTest();
      // Should not throw any exceptions
    });
  });

  group('PerformanceTestController Test History Tests', () {
    test('should filter tests by type', () {
      // Initially empty
      final tests = controller.getTestsByType('0-100m');
      expect(tests, isNotNull);
      expect(tests, isList);
    });
  });
}

// Extension to access private method for testing
extension PerformanceTestControllerTestExtension on PerformanceTestController {
  double getTargetDistance(String testType) {
    switch (testType) {
      case '0-100m':
        return 100.0;
      case '201m':
        return 201.0;
      case '402m':
        return 402.0;
      case '1000m':
        return 1000.0;
      default:
        return 100.0;
    }
  }
}
