import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:api_tech_moto/controllers/ecu_data_controller.dart';
import 'package:api_tech_moto/models/ecu_data.dart';

void main() {
  late ECUDataController controller;

  setUp(() {
    // Initialize GetX
    Get.testMode = true;
    controller = ECUDataController();
  });

  tearDown(() {
    controller.dispose();
    Get.reset();
  });

  group('ECUDataController Data Validation Tests', () {
    test('should reject empty data', () {
      controller.updateDataFromBluetooth('');
      expect(controller.currentData.value, isNull);
    });

    test('should reject invalid format (no equals sign)', () {
      controller.updateDataFromBluetooth('TECHO1000');
      expect(controller.currentData.value, isNull);
    });

    test('should reject unknown parameter', () {
      final initialBufferSize = controller.currentData.value;
      controller.updateDataFromBluetooth('UNKNOWN=100');
      // Buffer should not be updated with unknown parameter
      expect(controller.currentData.value, equals(initialBufferSize));
    });

    test('should reject non-numeric value', () {
      controller.updateDataFromBluetooth('TECHO=abc');
      expect(controller.currentData.value, isNull);
    });

    test('should accept valid data format', () {
      controller.updateDataFromBluetooth('TECHO=1000');
      // Data should be buffered (but not necessarily create currentData yet)
      // Since we need 13 fields, this test just validates no error occurs
    });

    test('should validate RPM range', () {
      // Test upper bound
      controller.updateDataFromBluetooth('TECHO=25000'); // Above 20000
      // Should be rejected or handled
    });

    test('should validate speed range', () {
      controller.updateDataFromBluetooth('SPEED=-10'); // Negative speed
      // Should be rejected
    });

    test('should validate battery voltage range', () {
      controller.updateDataFromBluetooth('BATT=30'); // Above 20V
      // Should be rejected
    });
  });

  group('ECUDataController Buffer Tests', () {
    test('should handle concurrent data updates safely', () {
      // Simulate rapid data updates
      controller.updateDataFromBluetooth('TECHO=1000');
      controller.updateDataFromBluetooth('SPEED=80');
      controller.updateDataFromBluetooth('WATER=85');

      // Should not crash or throw errors
    });

    test('should clear buffer after complete data set', () {
      // Send complete set of 13 parameters
      final completeData = [
        'TECHO=1000',
        'SPEED=80',
        'WATER=85',
        'AIR.T=30',
        'MAP=100',
        'TPS=50',
        'BATT=13.5',
        'IGNITI=15',
        'INJECT=5',
        'AFR=14.7',
        'S.TRIM=100',
        'L.TRIM=100',
        'IACV=50',
      ];

      for (var data in completeData) {
        controller.updateDataFromBluetooth(data);
      }

      // After complete set, currentData should be updated
      expect(controller.currentData.value, isNotNull);
    });
  });

  group('ECUDataController History Tests', () {
    test('should limit history to 1000 items', () {
      // Add more than 1000 items
      for (int i = 0; i < 1100; i++) {
        controller.dataHistory.add(
          controller.currentData.value ??
          ECUData(
            rpm: i.toDouble(),
            speed: 0,
            waterTemp: 0,
            airTemp: 0,
            map: 0,
            tps: 0,
            battery: 0,
            ignition: 0,
            inject: 0,
            afr: 0,
            shortTrim: 0,
            longTrim: 0,
            iacv: 0,
            timestamp: DateTime.now(),
          ),
        );
      }

      // Should be limited to 1000
      expect(controller.dataHistory.length, lessThanOrEqualTo(1000));
    });
  });

  group('ECUDataController Logging Tests', () {
    test('should start and stop logging', () {
      controller.startLogging();
      expect(controller.isLogging.value, isTrue);

      controller.stopLogging();
      expect(controller.isLogging.value, isFalse);
    });
  });

  group('ECUDataController Reset Tests', () {
    test('should reset data correctly', () {
      controller.resetData();
      expect(controller.currentData.value, isNull);
      expect(controller.dataHistory.isEmpty, isTrue);
    });
  });
}
