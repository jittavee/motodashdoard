import 'package:flutter/foundation.dart';

class DashboardProvider with ChangeNotifier {
   double _speed = 0.0;
  int _techo = 0; // RPM
  double _waterTemp = 0.0;
  double _airTemp = 0.0;
  double _mapValue = 0.0; // << เปลี่ยนชื่อจาก _map เป็น _mapValue
  double _tps = 0.0;
  double _battery = 0.0;
  double _ignition = 0.0;
  double _injection = 0.0;
  double _afr = 0.0;
  double _sTrim = 0.0;
  double _lTrim = 0.0;
  double _iacv = 0.0;

 // Getters for UI
  double get speed => _speed;
  int get techo => _techo;
  double get waterTemp => _waterTemp;
  double get battery => _battery;
  double get afr => _afr;
  double get tps => _tps;
  // --- เพิ่ม getter เหล่านี้เข้าไป ---
  double get mapValue => _mapValue;
  double get airTemp => _airTemp;
  double get injection => _injection;
  // ---------------------------------

  // Method to parse and update data from ESP32
  void updateValue(String data) {
    // data format: "NAME=VALUE"
    try {
      final parts = data.split('=');
      if (parts.length == 2) {
        final name = parts[0];
        final value = double.tryParse(parts[1]) ?? 0.0;

        switch (name) {
          case 'TECHO':
            _techo = value.toInt();
            break;
          case 'SPEED':
            _speed = value;
            break;
          case 'WATER':
            _waterTemp = value;
            break;
          case 'AIR.T':
            _airTemp = value;
            break;
           case 'MAP':
            _mapValue = value; // << ใช้ _mapValue
            break;
          case 'TPS':
            _tps = value;
            break;
          case 'BATT':
            _battery = value;
            break;
          case 'IGNITI':
            _ignition = value;
            break;
          case 'INJECT':
            _injection = value;
            break;
          case 'AFR':
            _afr = value;
            break;
          case 'S.TRIM':
            _sTrim = value;
            break;
          case 'L.TRIM':
            _lTrim = value;
            break;
          case 'IACV':
            _iacv = value;
            break;
        }
        // Notify all listening widgets to rebuild
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error parsing data: $e");
    }
  }
}