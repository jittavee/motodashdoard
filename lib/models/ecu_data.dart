class ECUData {
  final double rpm; // TECHO (รอบเครื่อง)
  final double speed; // ความเร็ว
  final double waterTemp; // อุณหภูมิน้ำ (WATER)
  final double airTemp; // อุณหภูมิอากาศ (AIR.T)
  final double map; // MAP
  final double tps; // ตำแหน่งลิ้นเร่ง (TPS)
  final double battery; // แบตเตอรี่ (BATT)
  final double ignition; // จังหวะจุดระเบิด (IGNITI)
  final double inject; // เวลาฉีด (INJECT)
  final double afr; // อัตราส่วนเชื้อเพลิง (AFR)
  final double shortTrim; // Short Trim (S.TRIM)
  final double longTrim; // Long Trim (L.TRIM)
  final double iacv; // IACV
  final DateTime timestamp;

  ECUData({
    required this.rpm,
    required this.speed,
    required this.waterTemp,
    required this.airTemp,
    required this.map,
    required this.tps,
    required this.battery,
    required this.ignition,
    required this.inject,
    required this.afr,
    required this.shortTrim,
    required this.longTrim,
    required this.iacv,
    required this.timestamp,
  });

  factory ECUData.fromJson(Map<String, dynamic> json) {
    return ECUData(
      rpm: (json['TECHO'] ?? 0).toDouble(),
      speed: (json['SPEED'] ?? 0).toDouble(),
      waterTemp: (json['WATER'] ?? 0).toDouble(),
      airTemp: (json['AIR.T'] ?? 0).toDouble(),
      map: (json['MAP'] ?? 0).toDouble(),
      tps: (json['TPS'] ?? 0).toDouble(),
      battery: (json['BATT'] ?? 0).toDouble(),
      ignition: (json['IGNITI'] ?? 0).toDouble(),
      inject: (json['INJECT'] ?? 0).toDouble(),
      afr: (json['AFR'] ?? 0).toDouble(),
      shortTrim: (json['S.TRIM'] ?? 0).toDouble(),
      longTrim: (json['L.TRIM'] ?? 0).toDouble(),
      iacv: (json['IACV'] ?? 0).toDouble(),
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'TECHO': rpm,
      'SPEED': speed,
      'WATER': waterTemp,
      'AIR.T': airTemp,
      'MAP': map,
      'TPS': tps,
      'BATT': battery,
      'IGNITI': ignition,
      'INJECT': inject,
      'AFR': afr,
      'S.TRIM': shortTrim,
      'L.TRIM': longTrim,
      'IACV': iacv,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'rpm': rpm,
      'speed': speed,
      'waterTemp': waterTemp,
      'airTemp': airTemp,
      'map': map,
      'tps': tps,
      'battery': battery,
      'ignition': ignition,
      'inject': inject,
      'afr': afr,
      'shortTrim': shortTrim,
      'longTrim': longTrim,
      'iacv': iacv,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory ECUData.fromMap(Map<String, dynamic> map) {
    return ECUData(
      rpm: (map['rpm'] ?? 0).toDouble(),
      speed: (map['speed'] ?? 0).toDouble(),
      waterTemp: (map['waterTemp'] ?? 0).toDouble(),
      airTemp: (map['airTemp'] ?? 0).toDouble(),
      map: (map['map'] ?? 0).toDouble(),
      tps: (map['tps'] ?? 0).toDouble(),
      battery: (map['battery'] ?? 0).toDouble(),
      ignition: (map['ignition'] ?? 0).toDouble(),
      inject: (map['inject'] ?? 0).toDouble(),
      afr: (map['afr'] ?? 0).toDouble(),
      shortTrim: (map['shortTrim'] ?? 0).toDouble(),
      longTrim: (map['longTrim'] ?? 0).toDouble(),
      iacv: (map['iacv'] ?? 0).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }

  ECUData copyWith({
    double? rpm,
    double? speed,
    double? waterTemp,
    double? airTemp,
    double? map,
    double? tps,
    double? battery,
    double? ignition,
    double? inject,
    double? afr,
    double? shortTrim,
    double? longTrim,
    double? iacv,
    DateTime? timestamp,
  }) {
    return ECUData(
      rpm: rpm ?? this.rpm,
      speed: speed ?? this.speed,
      waterTemp: waterTemp ?? this.waterTemp,
      airTemp: airTemp ?? this.airTemp,
      map: map ?? this.map,
      tps: tps ?? this.tps,
      battery: battery ?? this.battery,
      ignition: ignition ?? this.ignition,
      inject: inject ?? this.inject,
      afr: afr ?? this.afr,
      shortTrim: shortTrim ?? this.shortTrim,
      longTrim: longTrim ?? this.longTrim,
      iacv: iacv ?? this.iacv,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}