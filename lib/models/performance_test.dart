class PerformanceTest {
  final int? id;
  final String testType; // '0-100m', '201m', '402m', '1000m'
  final double distance; // ระยะทาง (เมตร)
  final double time; // เวลา (วินาที)
  final double maxSpeed; // ความเร็วสูงสุด
  final double avgSpeed; // ความเร็วเฉลี่ย
  final DateTime timestamp;
  final String? note;

  PerformanceTest({
    this.id,
    required this.testType,
    required this.distance,
    required this.time,
    required this.maxSpeed,
    required this.avgSpeed,
    required this.timestamp,
    this.note,
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
    );
  }
}