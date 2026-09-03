import 'package:api_tech_moto/services/alert_sound_player.dart';
import 'package:api_tech_moto/models/alert_threshold.dart';
import 'package:api_tech_moto/models/ecu_data.dart';
import 'package:api_tech_moto/services/database_helper.dart';

/// In-memory stand-in for [DatabaseHelper] — บันทึกทุก call ไว้ตรวจสอบ
/// โดยไม่แตะ sqflite (ซึ่งไม่มี platform channel ใน unit test)
class FakeDatabaseHelper extends DatabaseHelper {
  FakeDatabaseHelper({List<AlertThreshold>? thresholds})
      : thresholds = thresholds ?? <AlertThreshold>[],
        super.forTesting();

  final List<AlertThreshold> thresholds;
  final List<ECUData> insertedLogs = <ECUData>[];

  /// ตั้งค่าให้ insert ล้มเหลว เพื่อทดสอบ error path
  bool failOnInsert = false;

  @override
  Future<List<AlertThreshold>> getAllAlertThresholds() async => thresholds;

  @override
  Future<int> insertECUData(ECUData data) async {
    if (failOnInsert) throw Exception('simulated database failure');
    insertedLogs.add(data);
    return insertedLogs.length;
  }
}

/// นับจำนวนครั้งที่เล่นเสียงเตือน แทนการเรียก audio platform channel
class FakeAlertSoundPlayer implements AlertSoundPlayer {
  int playCount = 0;

  @override
  Future<void> playAlert() async => playCount++;

  @override
  Future<void> dispose() async {}
}
