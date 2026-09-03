/// Pure decoder for the 20-byte binary BLE packet from the ECU dongle.
///
/// Layout (ดู ESP32_BLE_Data_Protocol.md):
///   byte0  = header  (0x41 'A')
///   byte1  = EcuModel  ('0'..'3' => 0x30..0x33)
///   byte2  = ECU status ('0'..'2' => 0x30..0x32)
///   byte3  = header2 (0x42 'B')
///   byte4-18 = sensor values
///   byte19 = end (0x00)
///
/// แยกจาก BluetoothController เพื่อทดสอบ byte offset / scaling ได้
/// โดยไม่ต้องแตะ FlutterBluePlus
class EcuPacketDecoder {
  EcuPacketDecoder._();

  static const int packetLength = 20;
  static const int headerByte = 0x41;
  static const int header2Byte = 0x42;

  /// ASCII '0' — dongle ส่งตัวเลขเป็น ASCII digit ใน byte1/byte2
  static const int _asciiZero = 0x30;

  /// true ถ้า byte stream เป็น binary packet (ไม่ใช่ KEY=VALUE แบบ UTF-8)
  static bool isBinaryPacket(List<int> data) {
    return data.length == packetLength &&
        data[0] == headerByte &&
        data[3] == header2Byte;
  }

  /// ค่า EcuModel ที่ฝังมาในทุก packet (byte1)
  static int modelValue(List<int> data) => data[1] - _asciiZero;

  /// สถานะการเชื่อมต่อ dongle-ECU (byte2): 0=Connected 1=No response 2=Connecting
  static int statusValue(List<int> data) => data[2] - _asciiZero;

  /// แปลง byte4-18 เป็น map ของค่าเซนเซอร์ 13 ตัว
  ///
  /// โยน [ArgumentError] ถ้า packet ไม่ผ่าน [isBinaryPacket] — ผู้เรียกต้อง
  /// เช็คก่อนเสมอ
  static Map<String, double> decodeSensors(List<int> data) {
    if (!isBinaryPacket(data)) {
      throw ArgumentError('Not a valid ECU binary packet: $data');
    }

    final techo = (data[4] * 256) + data[5];
    final igniti = (((data[12] * 256) + data[13]) - 640) / 10.0;

    return <String, double>{
      'TECHO': techo.toDouble(),
      'SPEED': data[6].toDouble(),
      'WATER': (data[7] - 40).toDouble(),
      'AIR.T': (data[8] - 30).toDouble(),
      'MAP': data[9].toDouble(),
      'TPS': data[10].toDouble(),
      'BATT': data[11] / 10.0,
      'IGNITI': igniti,
      'INJECT': data[14] / 10.0,
      'AFR': data[15] / 10.0,
      'S.TRIM': (data[16] - 128).toDouble(),
      'L.TRIM': (data[17] - 128).toDouble(),
      'IACV': data[18].toDouble(),
    };
  }
}
