import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import '../utils/logger.dart';
import '../services/permission_service.dart';
import 'ecu_data_controller.dart';

enum BluetoothConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class BluetoothController extends GetxController {
  final Rx<BluetoothConnectionStatus> connectionStatus =
      BluetoothConnectionStatus.disconnected.obs;

  final RxList<ScanResult> scanResults = <ScanResult>[].obs;
  final RxBool isScanning = false.obs;
  final RxString errorMessage = ''.obs;

  final Rx<BluetoothDevice?> connectedDevice = Rx<BluetoothDevice?>(null);
  BluetoothCharacteristic? dataCharacteristic;
  StreamSubscription? connectionSubscription;
  StreamSubscription? dataSubscription;
  StreamSubscription? scanResultsSubscription;
  StreamSubscription? isScanningSubscription;

  final RxString lastReceivedData = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _checkBluetoothState();
  }

  @override
  void onClose() {
    disconnect();
    scanResultsSubscription?.cancel();
    isScanningSubscription?.cancel();
    super.onClose();
  }

  Future<void> _checkBluetoothState() async {
    // ตรวจสอบสถานะ Bluetooth
    final isSupported = await FlutterBluePlus.isSupported;
    if (!isSupported) {
      errorMessage.value = 'Bluetooth ไม่รองรับบนอุปกรณ์นี้';
      return;
    }

    // ขอ permission
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final permissionService = PermissionService.instance;
    await permissionService.requestBluetoothPermissions();
  }

  Future<void> startScan() async {
    try {
      // Cancel existing subscriptions first
      await scanResultsSubscription?.cancel();
      await isScanningSubscription?.cancel();

      scanResults.clear();
      isScanning.value = true;
      errorMessage.value = '';

      // ตรวจสอบว่า Bluetooth เปิดอยู่หรือไม่
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        errorMessage.value = 'กรุณาเปิด Bluetooth';
        isScanning.value = false;
        return;
      }

      // เริ่มสแกน
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
      );

      // รับผลการสแกน - store subscription to cancel later
      scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
        scanResults.value = results;
      });

      // เมื่อสแกนเสร็จ - store subscription to cancel later
      isScanningSubscription = FlutterBluePlus.isScanning.listen((scanning) {
        isScanning.value = scanning;
      });
    } catch (e) {
      errorMessage.value = 'เกิดข้อผิดพลาดในการสแกน: $e';
      isScanning.value = false;
      logger.e('Error starting scan', error: e);
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      await scanResultsSubscription?.cancel();
      await isScanningSubscription?.cancel();
      scanResultsSubscription = null;
      isScanningSubscription = null;
      isScanning.value = false;
    } catch (e) {
      errorMessage.value = 'เกิดข้อผิดพลาดในการหยุดสแกน: $e';
      logger.e('Error stopping scan', error: e);
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      connectionStatus.value = BluetoothConnectionStatus.connecting;
      errorMessage.value = '';

      // เชื่อมต่อกับอุปกรณ์
      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: 15),
        mtu: null,
      );
      connectedDevice.value = device;

      // ฟังสถานะการเชื่อมต่อ
      connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.connected) {
          connectionStatus.value = BluetoothConnectionStatus.connected;
          logger.i('Bluetooth Connected: ${device.platformName} (${device.remoteId})');
          _discoverServices();

          // กลับไปหน้า Dashboard ที่เปิดอยู่ก่อนหน้า
          Get.back();
        } else if (state == BluetoothConnectionState.disconnected) {
          connectionStatus.value = BluetoothConnectionStatus.disconnected;
          logger.w('Bluetooth Disconnected');
          _handleDisconnection();
        }
      });
    } catch (e) {
      connectionStatus.value = BluetoothConnectionStatus.error;
      errorMessage.value = 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e';
    }
  }

  Future<void> _discoverServices() async {
    try {
      if (connectedDevice.value == null) return;

      logger.i('Discovering services...');

      // ค้นหา services และ characteristics
      List<BluetoothService> services =
          await connectedDevice.value!.discoverServices();

      logger.i('Found ${services.length} services');

      // หา characteristic ที่ใช้รับข้อมูล (ปรับตาม UUID ของกล่อง ECU)
      for (var service in services) {
        logger.d('Service UUID: ${service.uuid}');
        logger.d('Characteristics: ${service.characteristics.length}');

        for (var characteristic in service.characteristics) {
          logger.d('└─ Characteristic UUID: ${characteristic.uuid}');
          logger.d('   Properties: Read=${characteristic.properties.read}, '
                'Write=${characteristic.properties.write}, '
                'Notify=${characteristic.properties.notify}, '
                'Indicate=${characteristic.properties.indicate}');

          // ตรวจสอบว่า characteristic รองรับ notify (ให้ความสำคัญกับ notify ก่อน)
          if (characteristic.properties.notify) {
            dataCharacteristic = characteristic;
            logger.i('Selected for data reception (Notify): ${characteristic.uuid}');

            // เปิดการแจ้งเตือนเมื่อมีข้อมูลเข้ามา
            await characteristic.setNotifyValue(true);
            dataSubscription = characteristic.lastValueStream.listen(
              (value) {
                _handleReceivedData(value);
              },
            );
            logger.i('Notification enabled');
            break;
          }
        }
        if (dataCharacteristic != null) break;
      }

      if (dataCharacteristic == null) {
        logger.w('No suitable characteristic found for data reception');
      }
    } catch (e) {
      errorMessage.value = 'เกิดข้อผิดพลาดในการค้นหา services: $e';
      logger.e('Error discovering services', error: e);
    }
  }


  void _handleReceivedData(List<int> data) {
    try {
      // Validate data is not empty
      if (data.isEmpty) {
        logger.w('Received empty data');
        return;
      }

      // แปลงข้อมูลจาก bytes เป็น String with error handling
      String dataString;
      try {
        dataString = utf8.decode(data, allowMalformed: false);
      } catch (e) {
        logger.e('Invalid UTF-8 data received', error: e);
        errorMessage.value = 'ข้อมูลที่รับไม่ถูกต้อง';
        return;
      }

      lastReceivedData.value = dataString;

      // Log ข้อมูลที่รับได้
      logger.d('Bluetooth Data Received: $dataString');

      // ส่งข้อมูลไปยัง ECU Data Controller
      try {
        final ecuController = Get.find<ECUDataController>();
        ecuController.updateDataFromBluetooth(dataString);
        logger.d('Data updated to ECU Controller');
      } catch (e) {
        // ECUDataController ยังไม่ถูก initialize
        logger.w('ECUDataController not found', error: e);
      }
    } catch (e) {
      errorMessage.value = 'เกิดข้อผิดพลาดในการอ่านข้อมูล: $e';
      logger.e('Error handling data', error: e);
    }
  }

  void _handleDisconnection() {
    dataSubscription?.cancel();
    dataSubscription = null;
    dataCharacteristic = null;
    Get.snackbar(
      'การเชื่อมต่อหลุด',
      'การเชื่อมต่อกับกล่อง ECU ถูกตัดขาด',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> disconnect() async {
    try {
      await dataSubscription?.cancel();
      await connectionSubscription?.cancel();
      await connectedDevice.value?.disconnect();

      connectedDevice.value = null;
      dataCharacteristic = null;
      connectionStatus.value = BluetoothConnectionStatus.disconnected;
    } catch (e) {
      errorMessage.value = 'เกิดข้อผิดพลาดในการตัดการเชื่อมต่อ: $e';
    }
  }

  // ฟังก์ชันสำหรับเชื่อมต่ออัตโนมัติกับอุปกรณ์ที่เคยเชื่อมต่อ
  Future<void> autoConnect({String? deviceName}) async {
    try {
      await startScan();

      // รอให้สแกนเสร็จ
      await Future.delayed(const Duration(seconds: 5));

      // หาอุปกรณ์ที่ต้องการ
      for (var result in scanResults) {
        if (deviceName != null) {
          if (result.device.platformName == deviceName) {
            await connectToDevice(result.device);
            return;
          }
        } else {
          // เชื่อมต่อกับอุปกรณ์แรกที่เจอ (สามารถปรับเงื่อนไขได้)
          if (result.device.platformName.isNotEmpty) {
            await connectToDevice(result.device);
            return;
          }
        }
      }

      errorMessage.value = 'ไม่พบอุปกรณ์ที่ต้องการ';
    } catch (e) {
      errorMessage.value = 'เกิดข้อผิดพลาดในการเชื่อมต่ออัตโนมัติ: $e';
    }
  }

  // ส่งข้อมูลไปยังกล่อง ECU
  Future<void> sendData(String data) async {
    try {
      if (dataCharacteristic == null) {
        errorMessage.value = 'ไม่พบ characteristic สำหรับส่งข้อมูล';
        return;
      }

      if (!dataCharacteristic!.properties.write &&
          !dataCharacteristic!.properties.writeWithoutResponse) {
        errorMessage.value = 'Characteristic ไม่รองรับการเขียนข้อมูล';
        return;
      }

      List<int> bytes = utf8.encode(data);
      await dataCharacteristic!.write(bytes);
    } catch (e) {
      errorMessage.value = 'เกิดข้อผิดพลาดในการส่งข้อมูล: $e';
    }
  }
}