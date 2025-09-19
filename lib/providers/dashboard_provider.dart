import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../models/sensor_data.dart';
import '../services/bluetooth_service.dart';

class DashboardProvider with ChangeNotifier {
  final BluetoothService _bluetoothService = BluetoothService();
  
  SensorData _sensorData = const SensorData();
  fbp.BluetoothConnectionState _connectionState = fbp.BluetoothConnectionState.disconnected;
  String? _errorMessage;
  
  StreamSubscription<SensorData>? _sensorDataSubscription;
  StreamSubscription<fbp.BluetoothConnectionState>? _connectionStateSubscription;
  StreamSubscription<String>? _errorSubscription;

  // Getters for UI
  double get speed => _sensorData.speed;
  int get techo => _sensorData.techo;
  double get waterTemp => _sensorData.waterTemp;
  double get airTemp => _sensorData.airTemp;
  double get mapValue => _sensorData.mapValue;
  double get tps => _sensorData.tps;
  double get battery => _sensorData.battery;
  double get ignition => _sensorData.ignition;
  double get injection => _sensorData.injection;
  double get afr => _sensorData.afr;
  double get sTrim => _sensorData.sTrim;
  double get lTrim => _sensorData.lTrim;
  double get iacv => _sensorData.iacv;
  
  SensorData get sensorData => _sensorData;
  fbp.BluetoothConnectionState get connectionState => _connectionState;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _bluetoothService.isConnected;
  fbp.BluetoothDevice? get connectedDevice => _bluetoothService.connectedDevice;

  DashboardProvider() {
    _initializeSubscriptions();
  }

  void _initializeSubscriptions() {
    _sensorDataSubscription = _bluetoothService.sensorDataStream.listen((data) {
      _sensorData = data;
      notifyListeners();
    });

    _connectionStateSubscription = _bluetoothService.connectionStateStream.listen((state) {
      _connectionState = state;
      notifyListeners();
    });

    _errorSubscription = _bluetoothService.errorStream.listen((error) {
      _errorMessage = error;
      notifyListeners();
    });
  }

  Future<void> connectToDevice(fbp.BluetoothDevice device) async {
    try {
      _errorMessage = null;
      notifyListeners();
      await _bluetoothService.connectToDevice(device);
    } catch (e) {
      _errorMessage = 'Connection failed: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    try {
      await _bluetoothService.disconnect();
    } catch (e) {
      debugPrint('Disconnect error: $e');
    }
  }

  Future<List<fbp.ScanResult>> scanForDevices({Duration? timeout}) async {
    try {
      _errorMessage = null;
      notifyListeners();
      return await _bluetoothService.scanForDevices(timeout: timeout);
    } catch (e) {
      _errorMessage = 'Scan failed: $e';
      notifyListeners();
      return [];
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sensorDataSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _errorSubscription?.cancel();
    _bluetoothService.dispose();
    super.dispose();
  }
}