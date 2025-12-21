import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:api_tech_moto/controllers/bluetooth_controller.dart';

void main() {
  late BluetoothController controller;

  setUp(() {
    Get.testMode = true;
    controller = BluetoothController();
  });

  tearDown(() {
    controller.dispose();
    Get.reset();
  });

  group('BluetoothController State Tests', () {
    test('should initialize with disconnected status', () {
      expect(
        controller.connectionStatus.value,
        equals(BluetoothConnectionStatus.disconnected),
      );
    });

    test('should initialize with empty scan results', () {
      expect(controller.scanResults.isEmpty, isTrue);
    });

    test('should initialize with isScanning false', () {
      expect(controller.isScanning.value, isFalse);
    });
  });

  group('BluetoothController Data Handling Tests', () {
    test('should initialize with empty last received data', () {
      expect(controller.lastReceivedData.value, isEmpty);
    });

    test('should have no error message initially', () {
      expect(controller.errorMessage.value, isEmpty);
    });
  });

  group('BluetoothController Cleanup Tests', () {
    test('should cleanup resources on dispose', () {
      controller.onClose();
      // Verify no exceptions thrown during cleanup
    });
  });
}
