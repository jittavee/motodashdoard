/// Classification of a text message received from the ECU dongle.
///
/// Dongle ส่งหลายอย่างมาบน characteristic เดียวกัน — ทั้งค่าเกจ, ACK ของ
/// คำสั่งที่แอปส่งไป, สถานะลิงก์ dongle-ECU และ echo ของคำสั่งเอง
/// การแยกประเภทเป็น pure function ทำให้ทดสอบ dispatch logic ได้โดยไม่ต้อง
/// พึ่ง BLE stack
sealed class DongleMessage {
  const DongleMessage();

  /// แยกประเภทข้อความ — ลำดับสำคัญ: echo ต้องถูกกรองก่อน EcuModel
  /// เพราะ "model=1" (คำสั่งของเรา) กับ "EcuModel=1" (ACK ของ dongle)
  /// ต่างกันแค่ prefix
  static DongleMessage classify(String raw) {
    final trimmed = raw.trim();

    if (_echoPattern.hasMatch(trimmed)) {
      return const CommandEcho();
    }

    final modelMatch = _modelAckPattern.firstMatch(trimmed);
    if (modelMatch != null) {
      final value = int.tryParse(modelMatch.group(1) ?? '0') ?? 0;
      return EcuModelAck(value);
    }

    final statusMatch = _statusPattern.firstMatch(trimmed);
    if (statusMatch != null) {
      return EcuStatusUpdate(statusMatch.group(1) ?? 'No_response');
    }

    return GaugeReading(trimmed);
  }

  static final RegExp _echoPattern =
      RegExp(r'^model=\d$', caseSensitive: false);
  static final RegExp _modelAckPattern =
      RegExp(r'^EcuModel=(\d)$', caseSensitive: false);
  static final RegExp _statusPattern =
      RegExp(r'^ECU=(.+)$', caseSensitive: false);
}

/// Echo ของคำสั่งที่แอปส่งไปเอง — ทิ้ง
class CommandEcho extends DongleMessage {
  const CommandEcho();
}

/// Dongle ยืนยันว่าตั้ง ECU model เป็นค่านี้แล้ว
class EcuModelAck extends DongleMessage {
  final int modelValue;
  const EcuModelAck(this.modelValue);
}

/// สถานะลิงก์ระหว่าง dongle กับ ECU ของรถ
class EcuStatusUpdate extends DongleMessage {
  final String rawStatus;
  const EcuStatusUpdate(this.rawStatus);
}

/// ค่าเกจ "KEY=VALUE" — ส่งต่อให้ ECUDataController parse
class GaugeReading extends DongleMessage {
  final String payload;
  const GaugeReading(this.payload);
}
