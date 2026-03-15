class PerformanceTest {
  final int? id;
  final String testType; // '0-100m', '201m', '402m', '1000m'
  final double distance; // ระยะทาง (เมตร)
  final double time; // เวลา (วินาที)
  final double maxSpeed; // ความเร็วสูงสุด
  final double avgSpeed; // ความเร็วเฉลี่ย
  final DateTime timestamp;
  final String? note;

  // ECU Data Summary
  final int? ecuSessionStart; // timestamp เริ่มต้น ECU session
  final int? ecuSessionEnd; // timestamp สิ้นสุด ECU session
  final double? maxRpm;
  final double? avgRpm;
  final double? maxWaterTemp;
  final double? avgWaterTemp;
  final double? maxTps;
  final double? avgTps;
  final double? maxAfr;
  final double? avgAfr;
  final double? minBattery;
  final double? avgBattery;

  PerformanceTest({
    this.id,
    required this.testType,
    required this.distance,
    required this.time,
    required this.maxSpeed,
    required this.avgSpeed,
    required this.timestamp,
    this.note,
    this.ecuSessionStart,
    this.ecuSessionEnd,
    this.maxRpm,
    this.avgRpm,
    this.maxWaterTemp,
    this.avgWaterTemp,
    this.maxTps,
    this.avgTps,
    this.maxAfr,
    this.avgAfr,
    this.minBattery,
    this.avgBattery,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'testType': testType,
      'distance': distance,
      'time': time,
      'maxSpeed': maxSpeed,
      'avgSpeed': avgSpeed,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'note': note,
      'ecuSessionStart': ecuSessionStart,
      'ecuSessionEnd': ecuSessionEnd,
      'maxRpm': maxRpm,
      'avgRpm': avgRpm,
      'maxWaterTemp': maxWaterTemp,
      'avgWaterTemp': avgWaterTemp,
      'maxTps': maxTps,
      'avgTps': avgTps,
      'maxAfr': maxAfr,
      'avgAfr': avgAfr,
      'minBattery': minBattery,
      'avgBattery': avgBattery,
    };
  }

  factory PerformanceTest.fromMap(Map<String, dynamic> map) {
    return PerformanceTest(
      id: map['id'],
      testType: map['testType'],
      distance: (map['distance'] ?? 0).toDouble(),
      time: (map['time'] ?? 0).toDouble(),
      maxSpeed: (map['maxSpeed'] ?? 0).toDouble(),
      avgSpeed: (map['avgSpeed'] ?? 0).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      note: map['note'],
      ecuSessionStart: map['ecuSessionStart'],
      ecuSessionEnd: map['ecuSessionEnd'],
      maxRpm: map['maxRpm']?.toDouble(),
      avgRpm: map['avgRpm']?.toDouble(),
      maxWaterTemp: map['maxWaterTemp']?.toDouble(),
      avgWaterTemp: map['avgWaterTemp']?.toDouble(),
      maxTps: map['maxTps']?.toDouble(),
      avgTps: map['avgTps']?.toDouble(),
      maxAfr: map['maxAfr']?.toDouble(),
      avgAfr: map['avgAfr']?.toDouble(),
      minBattery: map['minBattery']?.toDouble(),
      avgBattery: map['avgBattery']?.toDouble(),
    );
  }

  PerformanceTest copyWith({
    int? id,
    String? testType,
    double? distance,
    double? time,
    double? maxSpeed,
    double? avgSpeed,
    DateTime? timestamp,
    String? note,
    int? ecuSessionStart,
    int? ecuSessionEnd,
    double? maxRpm,
    double? avgRpm,
    double? maxWaterTemp,
    double? avgWaterTemp,
    double? maxTps,
    double? avgTps,
    double? maxAfr,
    double? avgAfr,
    double? minBattery,
    double? avgBattery,
  }) {
    return PerformanceTest(
      id: id ?? this.id,
      testType: testType ?? this.testType,
      distance: distance ?? this.distance,
      time: time ?? this.time,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      avgSpeed: avgSpeed ?? this.avgSpeed,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      ecuSessionStart: ecuSessionStart ?? this.ecuSessionStart,
      ecuSessionEnd: ecuSessionEnd ?? this.ecuSessionEnd,
      maxRpm: maxRpm ?? this.maxRpm,
      avgRpm: avgRpm ?? this.avgRpm,
      maxWaterTemp: maxWaterTemp ?? this.maxWaterTemp,
      avgWaterTemp: avgWaterTemp ?? this.avgWaterTemp,
      maxTps: maxTps ?? this.maxTps,
      avgTps: avgTps ?? this.avgTps,
      maxAfr: maxAfr ?? this.maxAfr,
      avgAfr: avgAfr ?? this.avgAfr,
      minBattery: minBattery ?? this.minBattery,
      avgBattery: avgBattery ?? this.avgBattery,
    );
  }
}