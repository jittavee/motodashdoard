import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:api_tech_moto/controllers/ecu_data_controller.dart';
import 'package:api_tech_moto/models/alert_threshold.dart';
import 'package:api_tech_moto/models/ecu_data.dart';

import '../helpers/fakes.dart';

/// Throttle windows ที่ controller ใช้จริง — ต้องตรงกับ ecu_data_controller.dart
const _uiThrottle = Duration(milliseconds: 50);

/// รอให้ทั้ง RPM buffer และ UI throttle flush ครบ
const _fullFlush = Duration(milliseconds: 1100);

/// ชุดข้อมูลครบ 13 พารามิเตอร์หนึ่งรอบ
const _completeCycle = [
  'TECHO=1000', 'SPEED=80', 'WATER=85', 'AIR.T=30', 'MAP=100',
  'TPS=50', 'BATT=13.5', 'IGNITI=15', 'INJECT=5', 'AFR=14.7',
  'S.TRIM=100', 'L.TRIM=100', 'IACV=50',
];

void main() {
  late ECUDataController controller;
  late FakeDatabaseHelper fakeDb;
  late FakeAlertSoundPlayer fakeAudio;

  ECUDataController build({List<AlertThreshold>? thresholds}) {
    fakeDb = FakeDatabaseHelper(thresholds: thresholds);
    fakeAudio = FakeAlertSoundPlayer();
    return ECUDataController(dbHelper: fakeDb, alertSound: fakeAudio);
  }

  setUp(() {
    Get.testMode = true;
    controller = build();
  });

  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  group('updateDataFromBluetooth - rejects bad input', () {
    // Controller ต้องไม่ผลิต currentData จากข้อมูลที่ไม่ผ่าน validation
    // แม้จะรอจน throttle window ผ่านไปแล้ว
    void expectRejected(String raw) {
      fakeAsync((async) {
        controller.updateDataFromBluetooth(raw);
        async.elapse(_fullFlush);
        expect(controller.currentData.value, isNull,
            reason: '"$raw" should not produce a data update');
      });
    }

    test('rejects empty data', () => expectRejected(''));
    test('rejects missing equals sign', () => expectRejected('TECHO1000'));
    test('rejects unknown parameter', () => expectRejected('UNKNOWN=100'));
    test('rejects non-numeric value', () => expectRejected('TECHO=abc'));
    test('rejects RPM above valid range', () => expectRejected('TECHO=25000'));
    test('rejects negative speed', () => expectRejected('SPEED=-10'));
    test('rejects battery above valid range', () => expectRejected('BATT=30'));

    test('a rejected value never reaches the buffer', () {
      fakeAsync((async) {
        // ส่งค่าที่ถูกต้องก่อน แล้วตามด้วยค่านอกช่วง — ค่าเดิมต้องคงอยู่
        controller.updateDataFromBluetooth('SPEED=80');
        async.elapse(_fullFlush);
        expect(controller.currentData.value?.speed, 80);

        controller.updateDataFromBluetooth('SPEED=500'); // out of range
        async.elapse(_fullFlush);
        expect(controller.currentData.value?.speed, 80,
            reason: 'out-of-range value must not overwrite a good one');
      });
    });
  });

  group('updateDataFromBluetooth - UI throttling', () {
    test('non-RPM value is not published before the 50ms window closes', () {
      fakeAsync((async) {
        controller.updateDataFromBluetooth('SPEED=80');

        async.elapse(const Duration(milliseconds: 49));
        expect(controller.currentData.value, isNull,
            reason: 'UI update should still be throttled');

        async.elapse(const Duration(milliseconds: 2));
        expect(controller.currentData.value?.speed, 80);
      });
    });

    test('rapid updates within one window publish only once', () {
      fakeAsync((async) {
        for (var speed = 1; speed <= 20; speed++) {
          controller.updateDataFromBluetooth('SPEED=$speed');
          async.elapse(const Duration(milliseconds: 1));
        }
        async.elapse(_uiThrottle);

        // 20 packets แต่ history ต้องได้แค่ 1 entry (นี่คือจุดประสงค์ของ throttle)
        expect(controller.dataHistory.length, 1);
        expect(controller.currentData.value?.speed, 20,
            reason: 'the newest value in the window wins');
      });
    });
  });

  group('updateDataFromBluetooth - RPM throttling', () {
    test('RPM is held for a 1000ms window before publishing', () {
      fakeAsync((async) {
        controller.updateDataFromBluetooth('TECHO=5000');

        async.elapse(const Duration(milliseconds: 900));
        expect(controller.currentData.value, isNull,
            reason: 'RPM should still be buffered');

        async.elapse(_fullFlush);
        expect(controller.currentData.value?.rpm, 5000);
      });
    });

    test('only the latest RPM in the window is published', () {
      fakeAsync((async) {
        controller.updateDataFromBluetooth('TECHO=1000');
        async.elapse(const Duration(milliseconds: 100));
        controller.updateDataFromBluetooth('TECHO=2000');
        async.elapse(const Duration(milliseconds: 100));
        controller.updateDataFromBluetooth('TECHO=3000');

        async.elapse(_fullFlush);
        expect(controller.currentData.value?.rpm, 3000);
        expect(controller.dataHistory.length, 1,
            reason: 'three RPM packets collapse into one UI update');
      });
    });

    test('non-RPM values are not delayed by the RPM window', () {
      fakeAsync((async) {
        controller.updateDataFromBluetooth('TECHO=5000');
        controller.updateDataFromBluetooth('SPEED=80');

        async.elapse(_uiThrottle);
        // SPEED ออกทันทีที่ 50ms, RPM ยังค้างอยู่ใน window 1000ms
        expect(controller.currentData.value?.speed, 80);
        expect(controller.currentData.value?.rpm, 0,
            reason: 'RPM has not flushed yet, ECUData defaults it to 0');
      });
    });
  });

  group('updateDataFromBluetooth - complete cycle', () {
    test('a full 13-parameter cycle produces one populated ECUData', () {
      fakeAsync((async) {
        for (final packet in _completeCycle) {
          controller.updateDataFromBluetooth(packet);
        }
        async.elapse(_fullFlush);

        final data = controller.currentData.value;
        expect(data, isNotNull);
        expect(data!.rpm, 1000);
        expect(data.speed, 80);
        expect(data.waterTemp, 85);
        expect(data.airTemp, 30);
        expect(data.map, 100);
        expect(data.tps, 50);
        expect(data.battery, 13.5);
        expect(data.ignition, 15);
        expect(data.inject, 5);
        expect(data.afr, 14.7);
        expect(data.shortTrim, 100);
        expect(data.longTrim, 100);
        expect(data.iacv, 50);
      });
    });

    test('buffer retains previous values across partial updates', () {
      fakeAsync((async) {
        for (final packet in _completeCycle) {
          controller.updateDataFromBluetooth(packet);
        }
        async.elapse(_fullFlush);

        // รอบถัดไปส่งมาแค่ SPEED — ค่าอื่นต้องคงเดิม ไม่ใช่ reset เป็น 0
        controller.updateDataFromBluetooth('SPEED=120');
        async.elapse(_uiThrottle);

        expect(controller.currentData.value?.speed, 120);
        expect(controller.currentData.value?.waterTemp, 85,
            reason: 'unrelated parameters must survive a partial update');
      });
    });
  });

  group('updateDataFromPacket - binary path', () {
    test('applies every value from a full packet immediately', () {
      fakeAsync((async) {
        controller.updateDataFromPacket({
          'TECHO': 1400, 'SPEED': 0, 'WATER': 90, 'AIR.T': 32,
          'MAP': 30, 'TPS': 0, 'BATT': 14.2, 'IGNITI': 6,
          'INJECT': 1.8, 'AFR': 14.7, 'S.TRIM': 2, 'L.TRIM': -3,
          'IACV': 35,
        });
        // binary packet ไม่ผ่าน RPM throttle — รอแค่ UI window
        async.elapse(_uiThrottle);

        expect(controller.currentData.value?.rpm, 1400);
        expect(controller.currentData.value?.battery, 14.2);
      });
    });

    test('skips out-of-range values but keeps the valid ones', () {
      fakeAsync((async) {
        controller.updateDataFromPacket({
          'TECHO': 99999, // out of range, ต้องถูกทิ้ง
          'SPEED': 60,    // valid
        });
        async.elapse(_uiThrottle);

        expect(controller.currentData.value?.speed, 60);
        expect(controller.currentData.value?.rpm, 0,
            reason: 'rejected RPM leaves the buffer empty, defaulting to 0');
      });
    });

    test('ignores an empty packet', () {
      fakeAsync((async) {
        controller.updateDataFromPacket({});
        async.elapse(_fullFlush);
        expect(controller.currentData.value, isNull);
      });
    });
  });

  group('history', () {
    test('caps history at 100 entries', () {
      fakeAsync((async) {
        for (var i = 0; i < 150; i++) {
          controller.updateDataFromBluetooth('SPEED=${i % 400}');
          async.elapse(_uiThrottle);
        }
        expect(controller.dataHistory.length, 100);
      });
    });

    test('drops the oldest entry when full', () {
      fakeAsync((async) {
        for (var i = 1; i <= 105; i++) {
          controller.updateDataFromBluetooth('SPEED=$i');
          async.elapse(_uiThrottle);
        }
        // entry 1-5 ถูกตัดทิ้ง เหลือ 6..105
        expect(controller.dataHistory.first.speed, 6);
        expect(controller.dataHistory.last.speed, 105);
      });
    });
  });

  group('alerts', () {
    ECUDataController buildWithThreshold(AlertThreshold threshold) {
      final c = build(thresholds: [threshold]);
      c.alertThresholds.value = [threshold];
      return c;
    }

    test('fires when a value exceeds the configured maximum', () {
      controller = buildWithThreshold(AlertThreshold(
        parameter: 'waterTemp', minValue: 0, maxValue: 100, enabled: true,
      ));

      fakeAsync((async) {
        controller.updateDataFromBluetooth('WATER=120');
        async.elapse(_uiThrottle);

        expect(controller.isAlertActive.value, isTrue);
        expect(controller.activeAlertParameters, contains('waterTemp'));
        expect(controller.activeAlertMessage.value, contains('Water Temp'));
      });
    });

    test('fires when a value drops below the configured minimum', () {
      controller = buildWithThreshold(AlertThreshold(
        parameter: 'battery', minValue: 12, maxValue: 15, enabled: true,
      ));

      fakeAsync((async) {
        controller.updateDataFromBluetooth('BATT=10');
        async.elapse(_uiThrottle);
        expect(controller.isAlertActive.value, isTrue);
      });
    });

    test('stays quiet while the value is inside the range', () {
      controller = buildWithThreshold(AlertThreshold(
        parameter: 'waterTemp', minValue: 0, maxValue: 100, enabled: true,
      ));

      fakeAsync((async) {
        controller.updateDataFromBluetooth('WATER=85');
        async.elapse(_uiThrottle);

        expect(controller.isAlertActive.value, isFalse);
        expect(controller.activeAlertParameters, isEmpty);
      });
    });

    test('a disabled threshold never fires', () {
      controller = buildWithThreshold(AlertThreshold(
        parameter: 'waterTemp', minValue: 0, maxValue: 100, enabled: false,
      ));

      fakeAsync((async) {
        controller.updateDataFromBluetooth('WATER=200');
        async.elapse(_uiThrottle);
        expect(controller.isAlertActive.value, isFalse);
      });
    });

    test('clears once the value returns to normal', () {
      controller = buildWithThreshold(AlertThreshold(
        parameter: 'waterTemp', minValue: 0, maxValue: 100, enabled: true,
      ));

      fakeAsync((async) {
        controller.updateDataFromBluetooth('WATER=120');
        async.elapse(_uiThrottle);
        expect(controller.isAlertActive.value, isTrue);

        controller.updateDataFromBluetooth('WATER=85');
        async.elapse(_uiThrottle);
        expect(controller.isAlertActive.value, isFalse);
        expect(controller.activeAlertMessage.value, isEmpty);
      });
    });

    test('plays a sound only when soundAlert is enabled', () {
      controller = buildWithThreshold(AlertThreshold(
        parameter: 'waterTemp', minValue: 0, maxValue: 100,
        enabled: true, soundAlert: true,
      ));

      fakeAsync((async) {
        controller.updateDataFromBluetooth('WATER=120');
        async.elapse(_uiThrottle);
        expect(fakeAudio.playCount, greaterThan(0));
      });
    });

    test('does not play a sound when soundAlert is disabled', () {
      controller = buildWithThreshold(AlertThreshold(
        parameter: 'waterTemp', minValue: 0, maxValue: 100,
        enabled: true, soundAlert: false,
      ));

      fakeAsync((async) {
        controller.updateDataFromBluetooth('WATER=120');
        async.elapse(_uiThrottle);
        expect(fakeAudio.playCount, 0);
      });
    });
  });

  group('logging', () {
    test('startLogging / stopLogging toggle the flag', () {
      controller.startLogging();
      expect(controller.isLogging.value, isTrue);

      controller.stopLogging();
      expect(controller.isLogging.value, isFalse);
    });

    test('writes a row once per second while logging', () {
      fakeAsync((async) {
        controller.updateDataFromBluetooth('SPEED=80');
        async.elapse(_uiThrottle);
        final baseline = fakeDb.insertedLogs.length;

        controller.startLogging();
        async.elapse(const Duration(seconds: 3));
        async.flushMicrotasks();

        expect(fakeDb.insertedLogs.length - baseline, greaterThanOrEqualTo(3));
        controller.stopLogging();
      });
    });

    test('stops writing after stopLogging', () {
      fakeAsync((async) {
        controller.updateDataFromBluetooth('SPEED=80');
        async.elapse(_uiThrottle);

        controller.startLogging();
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();
        controller.stopLogging();

        final countAtStop = fakeDb.insertedLogs.length;
        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();

        expect(fakeDb.insertedLogs.length, countAtStop);
      });
    });

    test('does not write while logging is off', () {
      fakeAsync((async) {
        controller.updateDataFromBluetooth('SPEED=80');
        async.elapse(_uiThrottle);
        async.flushMicrotasks();
        expect(fakeDb.insertedLogs, isEmpty);
      });
    });

    test('a database failure does not crash the data pipeline', () {
      fakeAsync((async) {
        fakeDb.failOnInsert = true;
        controller.startLogging();

        controller.updateDataFromBluetooth('SPEED=80');
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();

        // UI ต้องยังอัปเดตต่อได้แม้ DB ล่ม
        expect(controller.currentData.value?.speed, 80);
        controller.stopLogging();
      });
    });
  });

  group('resetData', () {
    test('clears current data and history', () {
      fakeAsync((async) {
        controller.updateDataFromBluetooth('SPEED=80');
        async.elapse(_uiThrottle);
        expect(controller.currentData.value, isNotNull);

        controller.resetData();
        expect(controller.currentData.value, isNull);
        expect(controller.dataHistory, isEmpty);
      });
    });

    test('clears the buffer so stale values do not reappear', () {
      fakeAsync((async) {
        controller.updateDataFromBluetooth('WATER=85');
        async.elapse(_uiThrottle);

        controller.resetData();

        // ส่ง SPEED ใหม่ — WATER เดิมต้องไม่กลับมา (ECU model เปลี่ยนแล้ว)
        controller.updateDataFromBluetooth('SPEED=50');
        async.elapse(_uiThrottle);
        expect(controller.currentData.value?.waterTemp, 0);
      });
    });
  });

  group('displayData', () {
    test('returns live data when not in playback mode', () {
      fakeAsync((async) {
        controller.updateDataFromBluetooth('SPEED=80');
        async.elapse(_uiThrottle);

        expect(controller.isPlaybackMode.value, isFalse);
        expect(controller.displayData?.speed, 80);
      });
    });

    test('returns the indexed log when in playback mode', () {
      fakeAsync((async) {
        controller.updateDataFromBluetooth('SPEED=80');
        async.elapse(_uiThrottle);

        controller.playbackLogs.value = [
          ECUData(
            rpm: 3000, speed: 55, waterTemp: 0, airTemp: 0, map: 0, tps: 0,
            battery: 0, ignition: 0, inject: 0, afr: 0, shortTrim: 0,
            longTrim: 0, iacv: 0, timestamp: DateTime(2026),
          ),
        ];
        controller.playbackIndex.value = 0;
        controller.isPlaybackMode.value = true;

        // dashboard อ่านผ่าน getter เดียวกัน จึงไม่ต้องรู้ว่า live หรือ replay
        expect(controller.displayData?.speed, 55);
      });
    });

    test('returns null in playback mode with no logs loaded', () {
      controller.isPlaybackMode.value = true;
      expect(controller.displayData, isNull);
    });
  });

  group('cleanup', () {
    test('onClose cancels pending timers so no update fires afterwards', () {
      fakeAsync((async) {
        controller.updateDataFromBluetooth('SPEED=80');
        controller.onClose();

        async.elapse(_fullFlush);
        expect(controller.currentData.value, isNull,
            reason: 'a cancelled throttle timer must not publish');
      });
    });
  });
}
