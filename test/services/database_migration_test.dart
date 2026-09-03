@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:api_tech_moto/services/database_helper.dart';

/// Schema เวอร์ชัน 1 ตามที่เคยปล่อยให้ผู้ใช้ — ไม่มีคอลัมน์ ECU stats
/// และไม่มี index
const _v1Schema = '''
  CREATE TABLE performance_tests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    testType TEXT NOT NULL,
    distance REAL NOT NULL,
    time REAL NOT NULL,
    maxSpeed REAL NOT NULL,
    avgSpeed REAL NOT NULL,
    timestamp INTEGER NOT NULL,
    note TEXT
  )
''';

const _v1EcuLogs = '''
  CREATE TABLE ecu_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    rpm REAL NOT NULL,
    speed REAL NOT NULL,
    waterTemp REAL NOT NULL,
    airTemp REAL NOT NULL,
    map REAL NOT NULL,
    tps REAL NOT NULL,
    battery REAL NOT NULL,
    ignition REAL NOT NULL,
    inject REAL NOT NULL,
    afr REAL NOT NULL,
    shortTrim REAL NOT NULL,
    longTrim REAL NOT NULL,
    iacv REAL NOT NULL,
    timestamp INTEGER NOT NULL
  )
''';

/// คอลัมน์ที่ schema v3 เพิ่มเข้ามาใน performance_tests
const _v3Columns = [
  'ecuSessionStart', 'ecuSessionEnd', 'maxRpm', 'avgRpm',
  'maxWaterTemp', 'avgWaterTemp', 'maxTps', 'avgTps',
  'maxAfr', 'avgAfr', 'minBattery', 'avgBattery',
];

/// sqflite_common_ffi ใช้ handle เดียวกันสำหรับ inMemoryDatabasePath
/// จึงต้องตั้งชื่อไม่ซ้ำเมื่อต้องเปิดสอง database พร้อมกันในเทสต์เดียว
int _dbCounter = 0;
Future<Database> openBlankDatabase() {
  _dbCounter++;
  return databaseFactory.openDatabase(
    'file:migration_test_$_dbCounter?mode=memory&cache=private',
    options: OpenDatabaseOptions(singleInstance: false),
  );
}

Future<Set<String>> columnsOf(Database db, String table) async {
  final info = await db.rawQuery('PRAGMA table_info($table)');
  return info.map((c) => c['name'] as String).toSet();
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  final helper = DatabaseHelper.instance;

  /// สร้าง database จำลองสภาพเครื่องผู้ใช้ที่ยังอยู่ schema v1 พร้อมข้อมูลจริง
  Future<Database> openLegacyV1() async {
    final legacy = await openBlankDatabase();
    await legacy.execute(_v1EcuLogs);
    await legacy.execute(_v1Schema);

    await legacy.insert('performance_tests', {
      'testType': '0-100',
      'distance': 0.0,
      'time': 5.42,
      'maxSpeed': 102.0,
      'avgSpeed': 61.0,
      'timestamp': DateTime(2026, 1, 1).millisecondsSinceEpoch,
      'note': 'ทดสอบก่อนอัปเดต',
    });
    await legacy.insert('ecu_logs', {
      'rpm': 1400.0, 'speed': 0.0, 'waterTemp': 90.0, 'airTemp': 32.0,
      'map': 30.0, 'tps': 0.0, 'battery': 14.2, 'ignition': 6.0,
      'inject': 1.8, 'afr': 14.7, 'shortTrim': 2.0, 'longTrim': -3.0,
      'iacv': 35.0,
      'timestamp': DateTime(2026, 1, 1).millisecondsSinceEpoch,
    });
    return legacy;
  }

  tearDown(() async {
    await db.close();
  });

  group('migration v1 to v3', () {
    test('adds every ECU stats column to performance_tests', () async {
      db = await openLegacyV1();
      await helper.runUpgrade(db, 1, 3);

      final columns = await columnsOf(db, 'performance_tests');
      for (final column in _v3Columns) {
        expect(columns, contains(column), reason: '$column must be added');
      }
    });

    test('preserves existing performance test rows', () async {
      db = await openLegacyV1();
      await helper.runUpgrade(db, 1, 3);

      final rows = await db.query('performance_tests');
      expect(rows, hasLength(1), reason: 'migration must never drop rows');
      expect(rows.first['testType'], '0-100');
      expect(rows.first['time'], 5.42);
      expect(rows.first['note'], 'ทดสอบก่อนอัปเดต');
    });

    test('preserves existing ECU log rows', () async {
      db = await openLegacyV1();
      await helper.runUpgrade(db, 1, 3);

      final rows = await db.query('ecu_logs');
      expect(rows, hasLength(1));
      expect(rows.first['rpm'], 1400.0);
      expect(rows.first['afr'], 14.7);
    });

    test('leaves new columns null on pre-existing rows', () async {
      db = await openLegacyV1();
      await helper.runUpgrade(db, 1, 3);

      final row = (await db.query('performance_tests')).first;
      // ข้อมูลเก่าไม่มี ECU stats — ต้องเป็น null ไม่ใช่ 0 ที่อ่านผิดเป็นค่าจริง
      expect(row['maxRpm'], isNull);
      expect(row['avgBattery'], isNull);
    });

    test('creates the query indexes', () async {
      db = await openLegacyV1();
      await helper.runUpgrade(db, 1, 3);

      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index'",
      );
      final names = indexes.map((i) => i['name'] as String).toSet();
      expect(names, contains('idx_ecu_logs_timestamp'));
      expect(names, contains('idx_performance_tests_timestamp'));
      expect(names, contains('idx_performance_tests_type'));
    });
  });

  group('migration is idempotent', () {
    test('running the v3 upgrade twice does not throw', () async {
      db = await openLegacyV1();
      await helper.runUpgrade(db, 1, 3);

      // PRAGMA table_info guard ต้องกัน ALTER TABLE ซ้ำ
      await expectLater(helper.runUpgrade(db, 1, 3), completes);
    });

    test('data survives a repeated upgrade', () async {
      db = await openLegacyV1();
      await helper.runUpgrade(db, 1, 3);
      await helper.runUpgrade(db, 1, 3);

      expect(await db.query('performance_tests'), hasLength(1));
    });
  });

  group('migration v2 to v3', () {
    test('adds the ECU stats columns without touching indexes', () async {
      db = await openLegacyV1();
      await helper.runUpgrade(db, 2, 3);

      final columns = await columnsOf(db, 'performance_tests');
      expect(columns, containsAll(_v3Columns));
    });
  });

  group('fresh install (onCreate)', () {
    test('creates all three tables at the latest schema', () async {
      db = await openBlankDatabase();
      await helper.runCreate(db, 3);

      final tables = (await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      )).map((t) => t['name'] as String).toSet();

      expect(tables, containsAll(['ecu_logs', 'alert_thresholds',
        'performance_tests']));
    });

    test('performance_tests already has the v3 columns', () async {
      db = await openBlankDatabase();
      await helper.runCreate(db, 3);

      final columns = await columnsOf(db, 'performance_tests');
      expect(columns, containsAll(_v3Columns));
    });

    test('seeds default alert thresholds', () async {
      db = await openBlankDatabase();
      await helper.runCreate(db, 3);

      final alerts = await db.query('alert_thresholds');
      expect(alerts, isNotEmpty,
          reason: 'a fresh install needs sensible default thresholds');
      // default ต้องปิดไว้ก่อน ไม่ให้ผู้ใช้ใหม่โดนเสียงเตือนทันที
      expect(alerts.first['parameter'], isNotNull);
    });

    test('a fresh schema matches what the v1 upgrade path produces', () async {
      db = await openBlankDatabase();
      await helper.runCreate(db, 3);
      final freshColumns = await columnsOf(db, 'performance_tests');

      final upgraded = await openLegacyV1();
      await helper.runUpgrade(upgraded, 1, 3);
      final upgradedColumns = await columnsOf(upgraded, 'performance_tests');
      await upgraded.close();

      // ผู้ใช้เก่ากับผู้ใช้ใหม่ต้องได้ schema เดียวกัน ไม่งั้น query จะพังฝั่งเดียว
      expect(upgradedColumns, freshColumns);
    });
  });
}
