import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/ecu_data.dart';
import '../models/alert_threshold.dart';
import '../models/performance_test.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ecu_gauge.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Incremented version for migration
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Migration logic for future schema changes
    if (oldVersion < 2) {
      // Add indexes for better query performance
      await _createIndexes(db);
    }
  }

  Future<void> _createIndexes(Database db) async {
    // Index for ECU logs timestamp (frequently queried)
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_ecu_logs_timestamp
      ON ecu_logs(timestamp DESC)
    ''');

    // Index for performance tests timestamp
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_performance_tests_timestamp
      ON performance_tests(timestamp DESC)
    ''');

    // Index for performance tests type (for filtering)
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_performance_tests_type
      ON performance_tests(testType)
    ''');

    // Composite index for ECU logs date range queries
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_ecu_logs_timestamp_range
      ON ecu_logs(timestamp)
    ''');
  }

  Future<void> _createDB(Database db, int version) async {
    // ตาราง ECU Data Logs
    await db.execute('''
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
    ''');

    // ตาราง Alert Thresholds
    await db.execute('''
      CREATE TABLE alert_thresholds (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        parameter TEXT NOT NULL,
        minValue REAL NOT NULL,
        maxValue REAL NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1,
        soundAlert INTEGER NOT NULL DEFAULT 1,
        popupAlert INTEGER NOT NULL DEFAULT 1,
        flashAlert INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // ตาราง Performance Tests
    await db.execute('''
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
    ''');

    // เพิ่ม default alert thresholds
    await _insertDefaultAlerts(db);

    // Create indexes
    await _createIndexes(db);
  }

  Future<void> _insertDefaultAlerts(Database db) async {
    final defaultAlerts = [
      {
        'parameter': 'rpm',
        'minValue': 0.0,
        'maxValue': 15000.0,
        'enabled': 1,
        'soundAlert': 1,
        'popupAlert': 1,
        'flashAlert': 1,
      },
      {
        'parameter': 'waterTemp',
        'minValue': 0.0,
        'maxValue': 120.0,
        'enabled': 1,
        'soundAlert': 1,
        'popupAlert': 1,
        'flashAlert': 1,
      },
      {
        'parameter': 'battery',
        'minValue': 11.0,
        'maxValue': 15.0,
        'enabled': 1,
        'soundAlert': 1,
        'popupAlert': 1,
        'flashAlert': 1,
      },
    ];

    for (var alert in defaultAlerts) {
      await db.insert('alert_thresholds', alert);
    }
  }

  // ECU Data Methods
  Future<int> insertECUData(ECUData data) async {
    final db = await database;
    return await db.insert('ecu_logs', data.toMap());
  }

  Future<List<ECUData>> getECULogs({
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause = 'timestamp BETWEEN ? AND ?';
      whereArgs = [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch
      ];
    }

    final maps = await db.query(
      'ecu_logs',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit ?? 100, // Default limit to prevent loading too much data
      offset: offset,
    );

    return maps.map((map) => ECUData.fromMap(map)).toList();
  }

  // Get total count of ECU logs (for pagination)
  Future<int> getECULogsCount({DateTime? startDate, DateTime? endDate}) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause = ' WHERE timestamp BETWEEN ? AND ?';
      whereArgs = [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch
      ];
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM ecu_logs$whereClause',
      whereArgs.isEmpty ? null : whereArgs,
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> deleteECULogsBefore(DateTime date) async {
    final db = await database;
    return await db.delete(
      'ecu_logs',
      where: 'timestamp < ?',
      whereArgs: [date.millisecondsSinceEpoch],
    );
  }

  Future<int> deleteAllECULogs() async {
    final db = await database;
    return await db.delete('ecu_logs');
  }

  // Alert Threshold Methods
  Future<int> insertAlertThreshold(AlertThreshold alert) async {
    final db = await database;
    return await db.insert('alert_thresholds', alert.toMap());
  }

  Future<List<AlertThreshold>> getAllAlertThresholds() async {
    final db = await database;
    final maps = await db.query('alert_thresholds');
    return maps.map((map) => AlertThreshold.fromMap(map)).toList();
  }

  Future<int> updateAlertThreshold(AlertThreshold alert) async {
    final db = await database;
    return await db.update(
      'alert_thresholds',
      alert.toMap(),
      where: 'id = ?',
      whereArgs: [alert.id],
    );
  }

  Future<int> deleteAlertThreshold(int id) async {
    final db = await database;
    return await db.delete(
      'alert_thresholds',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Performance Test Methods
  Future<int> insertPerformanceTest(PerformanceTest test) async {
    final db = await database;
    return await db.insert('performance_tests', test.toMap());
  }

  Future<List<PerformanceTest>> getAllPerformanceTests({
    String? testType,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    final maps = await db.query(
      'performance_tests',
      where: testType != null ? 'testType = ?' : null,
      whereArgs: testType != null ? [testType] : null,
      orderBy: 'timestamp DESC',
      limit: limit ?? 50, // Default limit
      offset: offset,
    );
    return maps.map((map) => PerformanceTest.fromMap(map)).toList();
  }

  // Get total count of performance tests
  Future<int> getPerformanceTestsCount({String? testType}) async {
    final db = await database;

    String whereClause = '';
    List<dynamic>? whereArgs;

    if (testType != null) {
      whereClause = ' WHERE testType = ?';
      whereArgs = [testType];
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM performance_tests$whereClause',
      whereArgs,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> deletePerformanceTest(int id) async {
    final db = await database;
    return await db.delete(
      'performance_tests',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}