import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../core/constants.dart';
import '../models/sensor_data.dart';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  StreamSubscription<List<int>>? _valueSubscription;
  StreamSubscription<fbp.BluetoothConnectionState>? _connectionStateSubscription;
  fbp.BluetoothDevice? _connectedDevice;

  final StreamController<SensorData> _sensorDataController = StreamController<SensorData>.broadcast();
  final StreamController<fbp.BluetoothConnectionState> _connectionStateController = StreamController<fbp.BluetoothConnectionState>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();

  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;
  Stream<fbp.BluetoothConnectionState> get connectionStateStream => _connectionStateController.stream;
  Stream<String> get errorStream => _errorController.stream;

  SensorData _currentSensorData = const SensorData();
  SensorData get currentSensorData => _currentSensorData;

  bool get isConnected => _connectedDevice?.isConnected ?? false;
  fbp.BluetoothDevice? get connectedDevice => _connectedDevice;

  Future<void> connectToDevice(fbp.BluetoothDevice device) async {
    try {
      debugPrint('Connecting to device: ${device.platformName}');
      await device.connect();
      _connectedDevice = device;
      
      _connectionStateSubscription = device.connectionState.listen((state) {
        _connectionStateController.add(state);
        if (state == fbp.BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      await _discoverServicesAndSubscribe(device);
    } catch (e) {
      debugPrint('Connection failed: $e');
      _errorController.add('Connection failed: $e');
      rethrow;
    }
  }

  Future<void> _discoverServicesAndSubscribe(fbp.BluetoothDevice device) async {
    try {
      debugPrint("Starting service discovery for ${device.platformName}");
      List<fbp.BluetoothService> services = await device.discoverServices();
      debugPrint("Found ${services.length} services.");

      debugPrint("--- Discovered Services and Characteristics ---");
      for (var s in services) {
        debugPrint("[INFO] Found Service: ${s.uuid.toString().toLowerCase()}");
        for (var c in s.characteristics) {
          debugPrint("  > Found Characteristic: ${c.uuid.toString().toLowerCase()}");
        }
      }
      debugPrint("---------------------------------------------");

      bool found = false;
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == AppConstants.serviceUUID) {
          debugPrint("✅ Matching Service Found: ${service.uuid}");
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() == AppConstants.characteristicUUID) {
              debugPrint("✅ Matching Characteristic Found: ${characteristic.uuid}");
              await characteristic.setNotifyValue(true);
              debugPrint("🟢 Subscribed to characteristic successfully!");

              _valueSubscription = characteristic.lastValueStream.listen((value) {
                String data = utf8.decode(value);
                debugPrint(">> RAW DATA RECEIVED: $data");
                _parseAndUpdateSensorData(data);
              });
              found = true;
              break;
            }
          }
        }
        if (found) break;
      }

      if (!found) {
        debugPrint("❌ ERROR: Did not find matching service/characteristic. Please check UUIDs.");
        _errorController.add('Service Discovery Failed: Could not find the required Bluetooth service. Please ensure the device is compatible.');
      }
    } catch (e) {
      debugPrint("🔴 EXCEPTION during discovery/subscription: $e");
      _errorController.add('Connection Error: Failed to establish connection: $e');
    }
  }

  void _parseAndUpdateSensorData(String data) {
    try {
      final parts = data.split('=');
      if (parts.length == 2) {
        final name = parts[0];
        final value = double.tryParse(parts[1]) ?? 0.0;

        SensorData updatedData;
        switch (name) {
          case SensorKeys.techo:
            updatedData = _currentSensorData.copyWith(techo: value.toInt());
            break;
          case SensorKeys.speed:
            updatedData = _currentSensorData.copyWith(speed: value);
            break;
          case SensorKeys.water:
            updatedData = _currentSensorData.copyWith(waterTemp: value);
            break;
          case SensorKeys.airTemp:
            updatedData = _currentSensorData.copyWith(airTemp: value);
            break;
          case SensorKeys.map:
            updatedData = _currentSensorData.copyWith(mapValue: value);
            break;
          case SensorKeys.tps:
            updatedData = _currentSensorData.copyWith(tps: value);
            break;
          case SensorKeys.battery:
            updatedData = _currentSensorData.copyWith(battery: value);
            break;
          case SensorKeys.ignition:
            updatedData = _currentSensorData.copyWith(ignition: value);
            break;
          case SensorKeys.injection:
            updatedData = _currentSensorData.copyWith(injection: value);
            break;
          case SensorKeys.afr:
            updatedData = _currentSensorData.copyWith(afr: value);
            break;
          case SensorKeys.sTrim:
            updatedData = _currentSensorData.copyWith(sTrim: value);
            break;
          case SensorKeys.lTrim:
            updatedData = _currentSensorData.copyWith(lTrim: value);
            break;
          case SensorKeys.iacv:
            updatedData = _currentSensorData.copyWith(iacv: value);
            break;
          default:
            return; // Unknown sensor key, ignore
        }

        _currentSensorData = updatedData;
        _sensorDataController.add(_currentSensorData);
      }
    } catch (e) {
      debugPrint("Error parsing sensor data: $e");
      _errorController.add("Error parsing sensor data: $e");
    }
  }

  void _handleDisconnection() {
    debugPrint("Device disconnected");
    _cleanup();
    _connectionStateController.add(fbp.BluetoothConnectionState.disconnected);
  }

  Future<void> disconnect() async {
    try {
      if (_connectedDevice?.isConnected == true) {
        await _connectedDevice!.disconnect();
      }
    } catch (e) {
      debugPrint("Error during disconnect: $e");
    } finally {
      _cleanup();
    }
  }

  void _cleanup() {
    _valueSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _valueSubscription = null;
    _connectionStateSubscription = null;
    _connectedDevice = null;
  }

  Future<List<fbp.ScanResult>> scanForDevices({Duration? timeout}) async {
    try {
      await fbp.FlutterBluePlus.startScan(
        timeout: timeout ?? const Duration(seconds: AppConstants.scanTimeoutSeconds),
      );
      
      final completer = Completer<List<fbp.ScanResult>>();
      late StreamSubscription subscription;
      
      subscription = fbp.FlutterBluePlus.scanResults.listen((results) {
        final namedDevices = results.where((r) => r.device.platformName.isNotEmpty).toList();
        if (namedDevices.isNotEmpty || !fbp.FlutterBluePlus.isScanningNow) {
          subscription.cancel();
          completer.complete(namedDevices);
        }
      });

      return await completer.future;
    } catch (e) {
      debugPrint("Scan error: $e");
      _errorController.add("Scan error: $e");
      return [];
    }
  }

  void dispose() {
    _cleanup();
    _sensorDataController.close();
    _connectionStateController.close();
    _errorController.close();
  }
}