import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
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

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? dataCharacteristic;
  StreamSubscription? connectionSubscription;
  StreamSubscription? dataSubscription;

  final RxString lastReceivedData = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _checkBluetoothState();
  }

  @override
  void onClose() {
    disconnect();
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
    // สำหรับ Android 12+
    if (GetPlatform.isAndroid) {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.location,
      ].request();
    } else if (GetPlatform.isIOS) {
      await Permission.bluetooth.request();
    }
  }

  Future<void> startScan() async {
    try {
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

      // รับผลการสแกน
      FlutterBluePlus.scanResults.listen((results) {
        scanResults.value = results;
      });

      // เมื่อสแกนเสร็จ
      FlutterBluePlus.isScanning.listen((scanning) {
        isScanning.value = scanning;
      });
    } catch (e) {
      errorMessage.value = 'เกิดข้อผิดพลาดในการสแกน: $e';
      isScanning.value = false;
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      isScanning.value = false;
    } catch (e) {
      errorMessage.value = 'เกิดข้อผิดพลาดในการหยุดสแกน: $e';
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
      connectedDevice = device;

      // ฟังสถานะการเชื่อมต่อ
      connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.connected) {
          connectionStatus.value = BluetoothConnectionStatus.connected;
          _discoverServices();
        } else if (state == BluetoothConnectionState.disconnected) {
          connectionStatus.value = BluetoothConnectionStatus.disconnected;
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
      if (connectedDevice == null) return;

      // ค้นหา services และ characteristics
      List<BluetoothService> services =
          await connectedDevice!.discoverServices();

      // หา characteristic ที่ใช้รับข้อมูล (ปรับตาม UUID ของกล่อง ECU)
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          // ตรวจสอบว่า characteristic รองรับ notify หรือ read
          if (characteristic.properties.notify ||
              characteristic.properties.read) {
            dataCharacteristic = characteristic;

            // เปิดการแจ้งเตือนเมื่อมีข้อมูลเข้ามา
            if (characteristic.properties.notify) {
              await characteristic.setNotifyValue(true);
              dataSubscription = characteristic.lastValueStream.listen(
                (value) {
                  _handleReceivedData(value);
                },
              );
            }
            break;
          }
        }
        if (dataCharacteristic != null) break;
      }
    } catch (e) {
      errorMessage.value = 'เกิดข้อผิดพลาดในการค้นหา services: $e';
    }
  }

  void _handleReceivedData(List<int> data) {
    try {
      // แปลงข้อมูลจาก bytes เป็น String
      String dataString = utf8.decode(data);
      lastReceivedData.value = dataString;

      // ส่งข้อมูลไปยัง ECU Data Controller
      try {
        final ecuController = Get.find<ECUDataController>();
        ecuController.updateDataFromBluetooth(dataString);
      } catch (e) {
        // ECUDataController ยังไม่ถูก initialize
        print('ECUDataController not found: $e');
      }
    } catch (e) {
      errorMessage.value = 'เกิดข้อผิดพลาดในการอ่านข้อมูล: $e';
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
      await connectedDevice?.disconnect();

      connectedDevice = null;
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