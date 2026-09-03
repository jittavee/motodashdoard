/// Pure parsing/validation logic for ECU data.
///
/// แยกออกจาก controller เพื่อให้ทดสอบได้โดยไม่ต้องพึ่ง GetX, Timer,
/// หรือ platform channel ใดๆ — ทุก method เป็น static pure function
class EcuParser {
  EcuParser._();

  /// Key ของพารามิเตอร์ที่ ECU dongle ส่งมา (13 ตัวต่อรอบ)
  static const Set<String> validKeys = {
    'TECHO', 'SPEED', 'WATER', 'AIR.T', 'MAP', 'TPS',
    'BATT', 'IGNITI', 'INJECT', 'AFR', 'S.TRIM', 'L.TRIM', 'IACV'
  };

  /// แยก "KEY=VALUE" เป็น record — คืน null ถ้ารูปแบบผิด, key ไม่รู้จัก,
  /// ค่าไม่ใช่ตัวเลข หรือค่าอยู่นอกช่วงที่เป็นไปได้จริง
  static ({String key, double value})? parse(String rawData) {
    if (rawData.isEmpty) return null;

    final keyValue = rawData.trim().split('=');
    if (keyValue.length != 2) return null;

    final key = keyValue[0].trim().toUpperCase();
    if (!validKeys.contains(key)) return null;

    final value = double.tryParse(keyValue[1].trim());
    if (value == null) return null;

    if (!isValueInValidRange(key, value)) return null;

    return (key: key, value: value);
  }

  /// เช็คว่าค่าอยู่ในช่วงที่เครื่องยนต์จริงเป็นไปได้ — กัน noise จาก BLE
  /// ทำให้เกจกระโดด
  static bool isValueInValidRange(String key, double value) {
    switch (key) {
      case 'TECHO': // RPM
        return value >= 0 && value <= 20000;
      case 'SPEED': // km/h
        return value >= 0 && value <= 400;
      case 'WATER': // Water temp (°C)
        return value >= -40 && value <= 500;
      case 'AIR.T': // Air temp (°C)
        return value >= -40 && value <= 150;
      case 'MAP': // kPa
        return value >= 0 && value <= 300;
      case 'TPS': // %
        return value >= 0 && value <= 100;
      case 'BATT': // Volts
        return value >= 0 && value <= 20;
      case 'IGNITI': // Degrees
        return value >= -30 && value <= 60;
      case 'INJECT': // ms
        return value >= 0 && value <= 50;
      case 'AFR': // Air-Fuel Ratio
        return value >= 5 && value <= 25;
      case 'S.TRIM': // %
        return value >= 0 && value <= 200;
      case 'L.TRIM': // %
        return value >= 0 && value <= 200;
      case 'IACV': // %
        return value >= 0 && value <= 100;
      default:
        return true;
    }
  }
}
