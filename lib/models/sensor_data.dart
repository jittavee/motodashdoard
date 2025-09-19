class SensorData {
  final double speed;
  final int techo;
  final double waterTemp;
  final double airTemp;
  final double mapValue;
  final double tps;
  final double battery;
  final double ignition;
  final double injection;
  final double afr;
  final double sTrim;
  final double lTrim;
  final double iacv;

  const SensorData({
    this.speed = 0.0,
    this.techo = 0,
    this.waterTemp = 0.0,
    this.airTemp = 0.0,
    this.mapValue = 0.0,
    this.tps = 0.0,
    this.battery = 0.0,
    this.ignition = 0.0,
    this.injection = 0.0,
    this.afr = 0.0,
    this.sTrim = 0.0,
    this.lTrim = 0.0,
    this.iacv = 0.0,
  });

  SensorData copyWith({
    double? speed,
    int? techo,
    double? waterTemp,
    double? airTemp,
    double? mapValue,
    double? tps,
    double? battery,
    double? ignition,
    double? injection,
    double? afr,
    double? sTrim,
    double? lTrim,
    double? iacv,
  }) {
    return SensorData(
      speed: speed ?? this.speed,
      techo: techo ?? this.techo,
      waterTemp: waterTemp ?? this.waterTemp,
      airTemp: airTemp ?? this.airTemp,
      mapValue: mapValue ?? this.mapValue,
      tps: tps ?? this.tps,
      battery: battery ?? this.battery,
      ignition: ignition ?? this.ignition,
      injection: injection ?? this.injection,
      afr: afr ?? this.afr,
      sTrim: sTrim ?? this.sTrim,
      lTrim: lTrim ?? this.lTrim,
      iacv: iacv ?? this.iacv,
    );
  }

  @override
  String toString() {
    return 'SensorData(speed: $speed, techo: $techo, waterTemp: $waterTemp, airTemp: $airTemp, mapValue: $mapValue, tps: $tps, battery: $battery, ignition: $ignition, injection: $injection, afr: $afr, sTrim: $sTrim, lTrim: $lTrim, iacv: $iacv)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SensorData &&
        other.speed == speed &&
        other.techo == techo &&
        other.waterTemp == waterTemp &&
        other.airTemp == airTemp &&
        other.mapValue == mapValue &&
        other.tps == tps &&
        other.battery == battery &&
        other.ignition == ignition &&
        other.injection == injection &&
        other.afr == afr &&
        other.sTrim == sTrim &&
        other.lTrim == lTrim &&
        other.iacv == iacv;
  }

  @override
  int get hashCode {
    return Object.hash(
      speed,
      techo,
      waterTemp,
      airTemp,
      mapValue,
      tps,
      battery,
      ignition,
      injection,
      afr,
      sTrim,
      lTrim,
      iacv,
    );
  }
}