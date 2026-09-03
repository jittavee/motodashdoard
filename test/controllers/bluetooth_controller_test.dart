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
    Get.reset();
  });

  group('initial state', () {
    test('starts disconnected with nothing scanned', () {
      expect(controller.connectionStatus.value,
          BluetoothConnectionStatus.disconnected);
      expect(controller.scanResults, isEmpty);
      expect(controller.isScanning.value, isFalse);
      expect(controller.lastReceivedData.value, isEmpty);
      expect(controller.errorMessage.value, isEmpty);
    });

    test('starts with the ECU link reported as no response', () {
      expect(controller.ecuConnectionStatus.value,
          EcuConnectionStatus.noResponse);
      expect(controller.isEcuModelSynced.value, isFalse);
    });

    test('defaults to the simulation ECU model', () {
      // main.dart ยิง model=0 ก่อนเสมอ ค่าเริ่มต้นจึงต้องเป็น simulation
      expect(controller.currentEcuModel.value, EcuModel.simulation);
    });
  });

  group('EcuModel', () {
    test('maps each supported value to its model', () {
      expect(EcuModel.fromValue(0), EcuModel.simulation);
      expect(EcuModel.fromValue(1), EcuModel.under150cc);
      expect(EcuModel.fromValue(2), EcuModel.higher150cc);
      expect(EcuModel.fromValue(3), EcuModel.smallBikes);
    });

    test('falls back to simulation for an unknown value', () {
      // dongle รุ่นใหม่อาจส่งค่าที่แอปยังไม่รู้จัก — ต้องไม่ crash
      expect(EcuModel.fromValue(99), EcuModel.simulation);
      expect(EcuModel.fromValue(-1), EcuModel.simulation);
    });

    test('every model carries a non-empty description for the UI', () {
      for (final model in EcuModel.values) {
        expect(model.description, isNotEmpty);
      }
    });
  });

  group('EcuConnectionStatus', () {
    test('parses each documented status string from the dongle', () {
      expect(EcuConnectionStatus.fromString('Connected'),
          EcuConnectionStatus.connected);
      expect(EcuConnectionStatus.fromString('No_response'),
          EcuConnectionStatus.noResponse);
      expect(EcuConnectionStatus.fromString('Connecting...'),
          EcuConnectionStatus.connecting);
    });

    test('parsing is case-insensitive', () {
      expect(EcuConnectionStatus.fromString('connected'),
          EcuConnectionStatus.connected);
      expect(EcuConnectionStatus.fromString('CONNECTED'),
          EcuConnectionStatus.connected);
    });

    test('falls back to no response for unrecognized text', () {
      expect(EcuConnectionStatus.fromString('garbage'),
          EcuConnectionStatus.noResponse);
      expect(EcuConnectionStatus.fromString(''),
          EcuConnectionStatus.noResponse);
    });
  });

  group('cleanup', () {
    test('onClose does not throw when never connected', () {
      expect(() => controller.onClose(), returnsNormally);
    });
  });
}
