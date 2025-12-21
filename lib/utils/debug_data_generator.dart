import 'dart:async';
import '../controllers/ecu_data_controller.dart';

/// Debug-only data generator for testing without real ECU device
/// DO NOT use in production builds
class DebugDataGenerator {
  Timer? _timer;
  final ECUDataController _ecuController;

  DebugDataGenerator(this._ecuController);

  /// Start generating fake ECU data for testing
  void startGeneratingData() {
    // Ensure this only runs in debug mode
    assert(() {
      _timer?.cancel();

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (timer.tick > 30) {
          timer.cancel();
          return;
        }

        // RPM เพิ่มทีละ 500 (0, 500, 1000, 1500, ...)
        int rpm = timer.tick * 500;

        // สร้างข้อมูลแบบเรียงลำดับและส่งทีละคู่
        List<String> dataList = [
          'TECHO=$rpm',
          'SPEED=${(timer.tick * 5).toString()}',
          'WATER=${(80 + timer.tick).toString()}',
          'AIR.T=${(30 + timer.tick).toString()}',
          'MAP=${(100 + timer.tick).toString()}',
          'TPS=${(timer.tick * 2).toString()}',
          'BATT=13.5',
          'IGNITI=${(15 + timer.tick * 0.5).toString()}',
          'INJECT=${(5 + timer.tick * 0.2).toString()}',
          'AFR=14.7',
          'S.TRIM=100',
          'L.TRIM=100',
          'IACV=50',
        ];

        // ส่งข้อมูลทีละคู่ไปที่ updateDataFromBluetooth
        for (var data in dataList) {
          _ecuController.updateDataFromBluetooth(data);
        }
      });

      return true;
    }());
  }

  /// Start generating realistic varying data
  void startGeneratingRealisticData() {
    assert(() {
      _timer?.cancel();
      int tick = 0;

      _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        tick++;
        if (tick > 60) {
          timer.cancel();
          return;
        }

        // Simulate realistic engine behavior
        double rpm = 1000 + (tick % 10) * 500; // Varies between 1000-6000
        double speed = 0 + (tick / 2); // Gradually increases
        double waterTemp = 85 + (tick * 0.1); // Slowly increases
        double tps = (tick % 10) * 10; // Throttle varies

        List<String> dataList = [
          'TECHO=${rpm.toInt()}',
          'SPEED=${speed.toInt()}',
          'WATER=${waterTemp.toStringAsFixed(1)}',
          'AIR.T=${(30 + (tick * 0.05)).toStringAsFixed(1)}',
          'MAP=${(100 + (tps * 0.5)).toStringAsFixed(1)}',
          'TPS=${tps.toInt()}',
          'BATT=${(13.2 + (tick % 5) * 0.1).toStringAsFixed(1)}',
          'IGNITI=${(15 + (rpm / 1000)).toStringAsFixed(1)}',
          'INJECT=${(5 + (tps / 20)).toStringAsFixed(1)}',
          'AFR=14.7',
          'S.TRIM=${(100 + (tick % 10 - 5)).toInt()}',
          'L.TRIM=${(100 + (tick % 20 - 10)).toInt()}',
          'IACV=${(50 - (rpm / 200)).toInt()}',
        ];

        for (var data in dataList) {
          _ecuController.updateDataFromBluetooth(data);
        }
      });

      return true;
    }());
  }

  /// Start generating continuous data (won't stop automatically)
  void startContinuousData() {
    assert(() {
      _timer?.cancel();
      int tick = 0;

      _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        tick++;

        // Simulate realistic engine behavior with cycling pattern
        double rpm = 1000 + (tick % 20) * 300; // Varies between 1000-7000
        double speed = (tick % 40) * 3.0; // Varies 0-120 km/h
        double waterTemp = 85 + ((tick % 60) * 0.2); // Varies 85-97°C
        double tps = (tick % 10) * 10.0; // Throttle varies 0-100%

        List<String> dataList = [
          'TECHO=${rpm.toInt()}',
          'SPEED=${speed.toInt()}',
          'WATER=${waterTemp.toStringAsFixed(1)}',
          'AIR.T=${(30 + (tick % 20) * 0.5).toStringAsFixed(1)}',
          'MAP=${(100 + (tps * 0.5)).toStringAsFixed(1)}',
          'TPS=${tps.toInt()}',
          'BATT=${(13.2 + (tick % 5) * 0.1).toStringAsFixed(1)}',
          'IGNITI=${(15 + (rpm / 1000)).toStringAsFixed(1)}',
          'INJECT=${(5 + (tps / 20)).toStringAsFixed(1)}',
          'AFR=${(14.0 + (tick % 10) * 0.1).toStringAsFixed(1)}',
          'S.TRIM=${(100 + (tick % 10 - 5)).toInt()}',
          'L.TRIM=${(100 + (tick % 20 - 10)).toInt()}',
          'IACV=${(50 - (rpm / 200)).toInt()}',
        ];

        for (var data in dataList) {
          _ecuController.updateDataFromBluetooth(data);
        }
      });

      return true;
    }());
  }

  /// Generate idle engine data (low RPM, no movement)
  void startIdleData() {
    assert(() {
      _timer?.cancel();
      int tick = 0;

      _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        tick++;

        // Idle engine simulation
        double rpm = 800 + (tick % 5) * 20; // Idle RPM varies 800-880

        List<String> dataList = [
          'TECHO=${rpm.toInt()}',
          'SPEED=0',
          'WATER=85.0',
          'AIR.T=30.0',
          'MAP=40.0',
          'TPS=0',
          'BATT=13.8',
          'IGNITI=10.0',
          'INJECT=2.5',
          'AFR=14.7',
          'S.TRIM=100',
          'L.TRIM=100',
          'IACV=45',
        ];

        for (var data in dataList) {
          _ecuController.updateDataFromBluetooth(data);
        }
      });

      return true;
    }());
  }

  /// Generate high performance data (racing simulation)
  void startRacingData() {
    assert(() {
      _timer?.cancel();
      int tick = 0;

      _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
        tick++;

        // Racing simulation - high RPM, high speed
        double rpm = 5000 + (tick % 15) * 200; // 5000-8000 RPM
        double speed = 80 + (tick % 25) * 4.0; // 80-180 km/h
        double waterTemp = 95 + (tick % 10) * 0.5; // High temp 95-100°C

        List<String> dataList = [
          'TECHO=${rpm.toInt()}',
          'SPEED=${speed.toInt()}',
          'WATER=${waterTemp.toStringAsFixed(1)}',
          'AIR.T=${(45 + (tick % 10) * 0.3).toStringAsFixed(1)}',
          'MAP=${(150 + (tick % 10) * 5).toStringAsFixed(1)}',
          'TPS=${(70 + (tick % 10) * 3).toInt()}',
          'BATT=${(13.0 + (tick % 3) * 0.2).toStringAsFixed(1)}',
          'IGNITI=${(25 + (tick % 5) * 1.0).toStringAsFixed(1)}',
          'INJECT=${(15 + (tick % 5) * 0.5).toStringAsFixed(1)}',
          'AFR=${(12.5 + (tick % 5) * 0.2).toStringAsFixed(1)}',
          'S.TRIM=${(105 + (tick % 5)).toInt()}',
          'L.TRIM=${(98 + (tick % 8)).toInt()}',
          'IACV=${(20 + (tick % 5)).toInt()}',
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

/// Extension for easy access in debug mode
extension ECUDataControllerDebugExtension on ECUDataController {
  /// Generate basic incremental test data (stops after 30 seconds)
  void startDebugDataGeneration() {
    final generator = DebugDataGenerator(this);
    generator.startGeneratingData();
  }

  /// Generate realistic varying data (stops after 60 ticks)
  void startRealisticDebugData() {
    final generator = DebugDataGenerator(this);
    generator.startGeneratingRealisticData();
  }

  /// Generate continuous cycling data (won't stop automatically)
  void startContinuousData() {
    final generator = DebugDataGenerator(this);
    generator.startContinuousData();
  }

  /// Generate idle engine data
  void startIdleData() {
    final generator = DebugDataGenerator(this);
    generator.startIdleData();
  }

  /// Generate racing/high performance data
  void startRacingData() {
    final generator = DebugDataGenerator(this);
    generator.startRacingData();
  }

  /// Stop all data generation
  void stopDebugData() {
    // Note: This creates a new instance just to stop,
    // but since Timer is cancelled, it's safe
    final generator = DebugDataGenerator(this);
    generator.stop();
  }
}
