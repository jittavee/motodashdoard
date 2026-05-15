import 'dart:async';
import '../controllers/ecu_data_controller.dart';

/// Debug-only data generator for testing without real ECU device
/// DO NOT use in production builds
class DebugDataGenerator {
  Timer? _timer;
  final ECUDataController _ecuController;

  DebugDataGenerator(this._ecuController);

  /// Start generating data at 15ms interval (stress test for UI rendering)
  void startHighFrequencyData() {
    assert(() {
      _timer?.cancel();
      int tick = 0;

      _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        tick++;

        // Simulate a realistic running engine with fast-changing values
        double rpm = 1000 + (tick % 140) * 50.0; // 1000–8000 RPM
        double speed = (tick % 80) * 1.5; // 0–120 km/h
        double tps = ((tick % 20) * 5.0).clamp(0.0, 100.0);
        double waterTemp = 85 + (tick % 30) * 0.2;

        final dataList = [
          'TECHO=${rpm.toInt()}',
          'SPEED=${speed.toStringAsFixed(1)}',
          'WATER=${waterTemp.toStringAsFixed(1)}',
          'AIR.T=${(30 + (tick % 10) * 0.3).toStringAsFixed(1)}',
          'MAP=${(80 + tps * 0.7).toStringAsFixed(1)}',
          'TPS=${tps.toInt()}',
          'BATT=${(13.0 + (tick % 8) * 0.1).toStringAsFixed(1)}',
          'IGNITI=${(12 + rpm / 800).toStringAsFixed(1)}',
          'INJECT=${(3 + tps / 25).toStringAsFixed(2)}',
          'AFR=${(13.5 + (tick % 12) * 0.1).toStringAsFixed(1)}',
          'S.TRIM=${(100 + (tick % 10 - 5)).toInt()}',
          'L.TRIM=${(100 + (tick % 20 - 10)).toInt()}',
          'IACV=${(40 - rpm / 400).clamp(5, 60).toInt()}',
        ];

        for (var data in dataList) {
          _ecuController.updateDataFromBluetooth(data);
        }
      });

      return true;
    }());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}

// Singleton generator per controller so stopDebugData() cancels the right timer
final _activeGenerators = <ECUDataController, DebugDataGenerator>{};

/// Extension for easy access in debug mode
extension ECUDataControllerDebugExtension on ECUDataController {
  DebugDataGenerator _generator() =>
      _activeGenerators.putIfAbsent(this, () => DebugDataGenerator(this));

  /// Toggle 15ms high-frequency simulation on/off
  void toggleSimulation() {
    if (isSimulating.value) {
      _activeGenerators[this]?.stop();
      isSimulating.value = false;
    } else {
      _generator().startHighFrequencyData();
      isSimulating.value = true;
    }
  }

  /// Stop all data generation
  void stopDebugData() {
    _activeGenerators[this]?.stop();
    isSimulating.value = false;
  }
}
