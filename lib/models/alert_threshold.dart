class AlertThreshold {
  final int? id;
  final String parameter; // rpm, waterTemp, etc.
  final double minValue;
  final double maxValue;
  final bool enabled;
  final bool soundAlert;
  final bool popupAlert;
  final bool flashAlert;

  AlertThreshold({
    this.id,
    required this.parameter,
    required this.minValue,
    required this.maxValue,
    this.enabled = true,
    this.soundAlert = true,
    this.popupAlert = true,
    this.flashAlert = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parameter': parameter,
      'minValue': minValue,
      'maxValue': maxValue,
      'enabled': enabled ? 1 : 0,
      'soundAlert': soundAlert ? 1 : 0,
      'popupAlert': popupAlert ? 1 : 0,
      'flashAlert': flashAlert ? 1 : 0,
    };
  }

  factory AlertThreshold.fromMap(Map<String, dynamic> map) {
    return AlertThreshold(
      id: map['id'],
      parameter: map['parameter'],
      minValue: (map['minValue'] ?? 0).toDouble(),
      maxValue: (map['maxValue'] ?? 0).toDouble(),
      enabled: (map['enabled'] ?? 1) == 1,
      soundAlert: (map['soundAlert'] ?? 1) == 1,
      popupAlert: (map['popupAlert'] ?? 1) == 1,
      flashAlert: (map['flashAlert'] ?? 1) == 1,
    );
  }

  AlertThreshold copyWith({
    int? id,
    String? parameter,
    double? minValue,
    double? maxValue,
    bool? enabled,
    bool? soundAlert,
    bool? popupAlert,
    bool? flashAlert,
  }) {
    return AlertThreshold(
      id: id ?? this.id,
      parameter: parameter ?? this.parameter,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      enabled: enabled ?? this.enabled,
      soundAlert: soundAlert ?? this.soundAlert,
      popupAlert: popupAlert ?? this.popupAlert,
      flashAlert: flashAlert ?? this.flashAlert,
    );
  }
}