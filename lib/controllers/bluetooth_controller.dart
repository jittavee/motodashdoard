import 'dart:async';
import 'dart:convert';
import 'package:flutter/scheduler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import '../utils/logger.dart';
import 'ecu_data_controller.dart';

enum BluetoothConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// ECU Connection Status (Dongle ↔ Motorcycle ECU)
enum EcuConnectionStatus {
  noResponse('No_response'),
  connecting('Connecting...'),
  connected('Connected');

  final String rawValue;
  const EcuConnectionStatus(this.rawValue);

  static EcuConnectionStatus fromString(String value) {
    return EcuConnectionStatus.values.firstWhere(
      (e) => e.rawValue.toLowerCase() == value.toLowerCase(),
      orElse: () => EcuConnectionStatus.noResponse,
    );
  }
}

/// ECU Model types supported by the Dongle
enum EcuModel {
  simulation(0, 'SIMULATION'),
  under150cc(1, 'Under 150cc (Wave125, Msx)'),
  higher150cc(2, 'Higher 150cc (PCX)'),
  smallBikes(3, 'Giorno, Lead, Click, Wave110');

  final int value;
  final String description;
  const EcuModel(this.value, this.description);

  static EcuModel fromValue(int value) {
    return EcuModel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EcuModel.simulation,
    );
  }
}

class BluetoothController extends GetxController {
  final Rx<BluetoothConnectionStatus> connectionStatus =
      BluetoothConnectionStatus.disconnected.obs;

  final RxList<ScanResult> scanResults = <ScanResult>[].obs;
  final RxBool isScanning = false.obs;
  final RxString errorMessage = ''.obs;

  final Rx<BluetoothDevice?> connectedDevice = Rx<BluetoothDevice?>(null);
  BluetoothCharacteristic? dataCharacteristic;
  BluetoothCharacteristic? writeCharacteristic;
  StreamSubscription? connectionSubscription;
  StreamSubscription? dataSubscription;
  StreamSubscription? scanResultsSubscription;
  StreamSubscription? isScanningSubscription;

  final RxString lastReceivedData = ''.obs;

  // ECU Model state
  final Rx<EcuModel> currentEcuModel = EcuModel.simulation.obs;
  final RxBool isEcuModelSynced = false.obs;

  // ECU Connection Status (Dongle ↔ Motorcycle)
  final Rx<EcuConnectionStatus> ecuConnectionStatus = EcuConnectionStatus.noResponse.obs;

  // Loading state for ECU Model selection
  final RxBool isSettingEcuModel = false.obs;
  Timer? _ecuModelTimeout;

  @override
  void onInit() {
    super.onInit();
    // รอให้ UI พร้อมก่อนค่อยขอเปิด BT (ต้องมี context สำหรับ dialog)
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _checkBluetoothState();
    });
  }

  @override
  void onClose() {
    _ecuModelTimeout?.cancel();
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

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      if (GetPlatform.isAndroid) {
        await FlutterBluePlus.turnOn();
      } else {
        Get.defaultDialog(
          title: 'Bluetooth ปิดอยู่',
          middleText: 'กรุณาเปิด Bluetooth ในการตั้งค่าเพื่อใช้งานแอป',
          textConfirm: 'ตกลง',
          onConfirm: () => Get.back(),
        );
      }
    }
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
        if (GetPlatform.isAndroid) {
          // Android: เด้ง dialog ขอเปิด Bluetooth อัตโนมัติ
          await FlutterBluePlus.turnOn();
          // รอให้ BT เปิดจริงก่อนสแกน (timeout 10 วินาที)
          final turned = await FlutterBluePlus.adapterState
              .where((s) => s == BluetoothAdapterState.on)
              .first
              .timeout(const Duration(seconds: 10), onTimeout: () => BluetoothAdapterState.off);
          if (turned != BluetoothAdapterState.on) {
            errorMessage.value = 'กรุณาเปิด Bluetooth';
            isScanning.value = false;
            return;
          }
        } else {
          // iOS: ไม่สามารถเปิดแทนผู้ใช้ได้
          Get.defaultDialog(
            title: 'Bluetooth ปิดอยู่',
            middleText: 'กรุณาเปิด Bluetooth ในการตั้งค่าเพื่อสแกนอุปกรณ์',
            textConfirm: 'ตกลง',
            onConfirm: () => Get.back(),
          );
          isScanning.value = false;
          return;
        }
      }

      // เริ่มสแกน
      await FlutterBluePlus.startScan(
        androidCheckLocationServices: true,
        androidUsesFineLocation: true,
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

  // Target Service and Characteristic UUIDs for API Bluetooth Dongle
  static const String targetServiceUuid = '2916f51f-3d75-4868-9214-396d9ebb82f1';
  static const String targetCharacteristicUuid = '09e6f548-20c3-48cf-8b5c-897a2f683cc3';

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
          }

          // หา characteristic สำหรับ write
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            writeCharacteristic = characteristic;
            logger.i('Selected for data writing: ${characteristic.uuid}');
          }
        }
      }

      if (dataCharacteristic == null) {
        logger.w('No suitable characteristic found for data reception');
      }

      if (writeCharacteristic == null) {
        logger.w('No suitable characteristic found for writing data');
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

      // ตรวจสอบว่าเป็นข้อมูล EcuModel response หรือไม่
      if (_handleEcuModelResponse(dataString)) {
        return;
      }

      // ตรวจสอบว่าเป็นข้อมูล ECU connection status หรือไม่
      if (_handleEcuConnectionStatus(dataString)) {
        return;
      }

      // ส่งข้อมูลไปยัง ECU Data Controller
      try {
        final ecuController = Get.find<ECUDataController>();
        ecuController.updateDataFromBluetooth(dataString);
        logger.d('Data updated to ECU Controller');

        // ถ้ามีข้อมูล ECU เข้ามา = ECU connected แล้ว (auto-detect)
        if (ecuConnectionStatus.value != EcuConnectionStatus.connected) {
          ecuConnectionStatus.value = EcuConnectionStatus.connected;
          logger.i('ECU Connection auto-detected from data stream');
        }
      } catch (e) {
        // ECUDataController ยังไม่ถูก initialize
        logger.w('ECUDataController not found', error: e);
      }
    } catch (e) {
      errorMessage.value = 'เกิดข้อผิดพลาดในการอ่านข้อมูล: $e';
      logger.e('Error handling data', error: e);
    }
  }

  /// Handle EcuModel response from Dongle
  /// Returns true if the data was an EcuModel response
  bool _handleEcuModelResponse(String dataString) {
    // ตรวจสอบรูปแบบ EcuModel=0, EcuModel=1, EcuModel=2, EcuModel=3
    final ecuModelRegex = RegExp(r'^EcuModel=(\d)$', caseSensitive: false);
    final match = ecuModelRegex.firstMatch(dataString.trim());

    if (match != null) {
      // ยกเลิก timeout และ loading state
      _ecuModelTimeout?.cancel();
      isSettingEcuModel.value = false;

      final modelValue = int.tryParse(match.group(1) ?? '0') ?? 0;
      currentEcuModel.value = EcuModel.fromValue(modelValue);
      isEcuModelSynced.value = true;

      // Reset ECU data buffer เพื่อให้ค่าใหม่จาก ECU ใหม่แสดงผล
      try {
        final ecuController = Get.find<ECUDataController>();
        ecuController.resetData();
        logger.i('ECU data buffer cleared for new ECU Model');
      } catch (e) {
        logger.w('ECUDataController not found for reset', error: e);
      }

      logger.i('ECU Model received from Dongle: ${currentEcuModel.value.description}');

      // Get.snackbar(
      //   'ECU Model',
      //   'Dongle ตั้งค่าเป็น: ${currentEcuModel.value.description}',
      //   snackPosition: SnackPosition.BOTTOM,
      //   duration: const Duration(seconds: 2),
      // );

      return true;
    }

    return false;
  }

  /// Handle ECU Connection Status from Dongle
  /// Returns true if the data was an ECU connection status
  bool _handleEcuConnectionStatus(String dataString) {
    // ตรวจสอบรูปแบบ ECU=Connected, ECU=No_response, ECU=Connecting...
    final ecuStatusRegex = RegExp(r'^ECU=(.+)$', caseSensitive: false);
    final match = ecuStatusRegex.firstMatch(dataString.trim());

    if (match != null) {
      final statusValue = match.group(1) ?? 'No_response';
      final newStatus = EcuConnectionStatus.fromString(statusValue);

      // ถ้าสถานะปัจจุบันเป็น connected แล้ว ไม่ให้กลับไปเป็น connecting
      // (ป้องกันการกระพริบ เพราะ Dongle อาจส่ง Connecting... สลับกับข้อมูล ECU)
      if (ecuConnectionStatus.value == EcuConnectionStatus.connected &&
          newStatus == EcuConnectionStatus.connecting) {
        logger.d('Ignoring Connecting status - already connected');
        return true;
      }

      ecuConnectionStatus.value = newStatus;
      logger.i('ECU Connection Status: ${ecuConnectionStatus.value.rawValue}');

      return true;
    }

    return false;
  }

  void _handleDisconnection() {
    dataSubscription?.cancel();
    dataSubscription = null;
    dataCharacteristic = null;
    writeCharacteristic = null;
    isEcuModelSynced.value = false;
    isSettingEcuModel.value = false;
    _ecuModelTimeout?.cancel();
    ecuConnectionStatus.value = EcuConnectionStatus.noResponse;
    // Get.snackbar(
    //   'การเชื่อมต่อหลุด',
    //   'การเชื่อมต่อกับกล่อง ECU ถูกตัดขาด',
    //   snackPosition: SnackPosition.BOTTOM,
    // );
  }

  Future<void> disconnect() async {
    try {
      await dataSubscription?.cancel();
      await connectionSubscription?.cancel();
      await connectedDevice.value?.disconnect();

      connectedDevice.value = null;
      dataCharacteristic = null;
      writeCharacteristic = null;
      isEcuModelSynced.value = false;
      ecuConnectionStatus.value = EcuConnectionStatus.noResponse;
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
      if (writeCharacteristic == null) {
        errorMessage.value = 'ไม่พบ characteristic สำหรับส่งข้อมูล';
        logger.w('No write characteristic available');
        return;
      }

      if (!writeCharacteristic!.properties.write &&
          !writeCharacteristic!.properties.writeWithoutResponse) {
        errorMessage.value = 'Characteristic ไม่รองรับการเขียนข้อมูล';
        return;
      }

      List<int> bytes = utf8.encode(data);
      await writeCharacteristic!.write(bytes);
      logger.i('Data sent: $data');
    } catch (e) {
      errorMessage.value = 'เกิดข้อผิดพลาดในการส่งข้อมูล: $e';
      logger.e('Error sending data', error: e);
    }
  }

  /// Send ECU Model selection to Dongle
  /// Format: model=0, model=1, model=2, model=3
  Future<void> setEcuModel(EcuModel model) async {
    if (connectionStatus.value != BluetoothConnectionStatus.connected) {
      errorMessage.value = 'กรุณาเชื่อมต่อ Bluetooth ก่อน';
      // Get.snackbar(
      //   'ไม่ได้เชื่อมต่อ',
      //   'กรุณาเชื่อมต่อกับ Dongle ก่อนเลือก ECU Model',
      //   snackPosition: SnackPosition.BOTTOM,
      // );
      return;
    }

    // ป้องกันการกดซ้ำขณะกำลังประมวลผล
    if (isSettingEcuModel.value) {
      return;
    }

    isSettingEcuModel.value = true;

    final command = 'model=${model.value}';
    logger.i('Sending ECU Model command: $command');

    await sendData(command);

    // ตั้ง timeout 10 วินาที - ถ้า Dongle ไม่ตอบกลับจะยกเลิกการรอ
    _ecuModelTimeout?.cancel();
    _ecuModelTimeout = Timer(const Duration(seconds: 10), () {
      if (isSettingEcuModel.value) {
        isSettingEcuModel.value = false;
        logger.w('ECU Model response timeout');
        Get.snackbar(
          'หมดเวลา',
          'Dongle ไม่ตอบกลับ - กรุณาตรวจสอบการเชื่อมต่อ ECU',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    });

    // Get.snackbar(
    //   'ECU Model',
    //   'กำลังส่งคำสั่งไปยัง Dongle: ${model.description}',
    //   snackPosition: SnackPosition.BOTTOM,
    //   duration: const Duration(seconds: 2),
    // );
  }
}