import 'package:flutter_test/flutter_test.dart';
import 'package:api_tech_moto/utils/ecu_packet_decoder.dart';

/// สร้าง packet 20 ไบต์ที่ถูกต้อง โดยเริ่มจากค่ากลางแล้ว override เฉพาะ
/// ไบต์ที่แต่ละเทสต์สนใจ
List<int> buildPacket({
  int model = 0x30,
  int status = 0x30,
  int techoHigh = 0,
  int techoLow = 0,
  int speed = 0,
  int water = 40,   // -40 offset => 0 °C
  int airTemp = 30, // -30 offset => 0 °C
  int map = 0,
  int tps = 0,
  int batt = 0,
  int ignitiHigh = 0,
  int ignitiLow = 0,
  int inject = 0,
  int afr = 0,
  int sTrim = 128, // -128 offset => 0 %
  int lTrim = 128,
  int iacv = 0,
}) {
  return [
    EcuPacketDecoder.headerByte, // 0
    model,                       // 1
    status,                      // 2
    EcuPacketDecoder.header2Byte,// 3
    techoHigh,                   // 4
    techoLow,                    // 5
    speed,                       // 6
    water,                       // 7
    airTemp,                     // 8
    map,                         // 9
    tps,                         // 10
    batt,                        // 11
    ignitiHigh,                  // 12
    ignitiLow,                   // 13
    inject,                      // 14
    afr,                         // 15
    sTrim,                       // 16
    lTrim,                       // 17
    iacv,                        // 18
    0x00,                        // 19 end
  ];
}

void main() {
  group('EcuPacketDecoder.isBinaryPacket', () {
    test('accepts a well-formed packet', () {
      expect(EcuPacketDecoder.isBinaryPacket(buildPacket()), isTrue);
    });

    test('rejects packet with wrong length', () {
      final short = buildPacket()..removeLast();
      expect(EcuPacketDecoder.isBinaryPacket(short), isFalse);
    });

    test('rejects packet with wrong first header byte', () {
      final bad = buildPacket()..[0] = 0x40;
      expect(EcuPacketDecoder.isBinaryPacket(bad), isFalse);
    });

    test('rejects packet with wrong second header byte', () {
      final bad = buildPacket()..[3] = 0x43;
      expect(EcuPacketDecoder.isBinaryPacket(bad), isFalse);
    });

    test('rejects empty data', () {
      expect(EcuPacketDecoder.isBinaryPacket(<int>[]), isFalse);
    });

    test('rejects a UTF-8 "TECHO=1000" text frame', () {
      // ข้อความ KEY=VALUE ต้องไม่ถูกเข้าใจผิดว่าเป็น binary packet
      final text = 'TECHO=1000'.codeUnits;
      expect(EcuPacketDecoder.isBinaryPacket(text), isFalse);
    });
  });

  group('EcuPacketDecoder.modelValue / statusValue', () {
    test('decodes ASCII model digits 0-3', () {
      for (var i = 0; i <= 3; i++) {
        expect(EcuPacketDecoder.modelValue(buildPacket(model: 0x30 + i)), i);
      }
    });

    test('decodes ASCII status digits 0-2', () {
      for (var i = 0; i <= 2; i++) {
        expect(EcuPacketDecoder.statusValue(buildPacket(status: 0x30 + i)), i);
      }
    });
  });

  group('EcuPacketDecoder.decodeSensors - scaling', () {
    test('TECHO is big-endian across bytes 4 and 5', () {
      // 0x1F * 256 + 0x40 = 7936 + 64 = 8000 RPM
      final values = EcuPacketDecoder.decodeSensors(
        buildPacket(techoHigh: 0x1F, techoLow: 0x40),
      );
      expect(values['TECHO'], 8000);
    });

    test('TECHO handles maximum 16-bit value', () {
      final values = EcuPacketDecoder.decodeSensors(
        buildPacket(techoHigh: 0xFF, techoLow: 0xFF),
      );
      expect(values['TECHO'], 65535);
    });

    test('SPEED is a raw byte', () {
      expect(
        EcuPacketDecoder.decodeSensors(buildPacket(speed: 120))['SPEED'],
        120,
      );
    });

    test('WATER applies -40 offset', () {
      expect(
        EcuPacketDecoder.decodeSensors(buildPacket(water: 125))['WATER'],
        85,
      );
    });

    test('WATER can go below zero', () {
      expect(
        EcuPacketDecoder.decodeSensors(buildPacket(water: 30))['WATER'],
        -10,
      );
    });

    test('AIR.T applies -30 offset', () {
      expect(
        EcuPacketDecoder.decodeSensors(buildPacket(airTemp: 65))['AIR.T'],
        35,
      );
    });

    test('BATT divides by 10', () {
      expect(
        EcuPacketDecoder.decodeSensors(buildPacket(batt: 135))['BATT'],
        13.5,
      );
    });

    test('IGNITI applies -640 offset then divides by 10', () {
      // (2 * 256 + 128 - 640) / 10 = (512 + 128 - 640) / 10 = 0
      expect(
        EcuPacketDecoder.decodeSensors(
          buildPacket(ignitiHigh: 2, ignitiLow: 128),
        )['IGNITI'],
        0,
      );
    });

    test('IGNITI can be negative (retarded timing)', () {
      // (0 * 256 + 540 is impossible in one byte; use high=2 low=28)
      // (2 * 256 + 28 - 640) / 10 = (512 + 28 - 640) / 10 = -10
      expect(
        EcuPacketDecoder.decodeSensors(
          buildPacket(ignitiHigh: 2, ignitiLow: 28),
        )['IGNITI'],
        -10,
      );
    });

    test('INJECT divides by 10', () {
      expect(
        EcuPacketDecoder.decodeSensors(buildPacket(inject: 55))['INJECT'],
        5.5,
      );
    });

    test('AFR divides by 10', () {
      expect(
        EcuPacketDecoder.decodeSensors(buildPacket(afr: 147))['AFR'],
        14.7,
      );
    });

    test('S.TRIM applies -128 offset (signed trim)', () {
      final values = EcuPacketDecoder.decodeSensors(buildPacket(sTrim: 138));
      expect(values['S.TRIM'], 10);
    });

    test('S.TRIM can be negative', () {
      final values = EcuPacketDecoder.decodeSensors(buildPacket(sTrim: 118));
      expect(values['S.TRIM'], -10);
    });

    test('L.TRIM applies -128 offset', () {
      expect(
        EcuPacketDecoder.decodeSensors(buildPacket(lTrim: 148))['L.TRIM'],
        20,
      );
    });

    test('MAP, TPS and IACV are raw bytes', () {
      final values = EcuPacketDecoder.decodeSensors(
        buildPacket(map: 101, tps: 42, iacv: 77),
      );
      expect(values['MAP'], 101);
      expect(values['TPS'], 42);
      expect(values['IACV'], 77);
    });
  });

  group('EcuPacketDecoder.decodeSensors - contract', () {
    test('returns exactly the 13 documented parameters', () {
      final values = EcuPacketDecoder.decodeSensors(buildPacket());
      expect(values.keys.toSet(), {
        'TECHO', 'SPEED', 'WATER', 'AIR.T', 'MAP', 'TPS', 'BATT',
        'IGNITI', 'INJECT', 'AFR', 'S.TRIM', 'L.TRIM', 'IACV',
      });
    });

    test('throws on a packet that fails the header check', () {
      final bad = buildPacket()..[0] = 0x00;
      expect(
        () => EcuPacketDecoder.decodeSensors(bad),
        throwsArgumentError,
      );
    });

    test('throws on a short packet rather than reading out of bounds', () {
      expect(
        () => EcuPacketDecoder.decodeSensors([0x41, 0x30, 0x30, 0x42]),
        throwsArgumentError,
      );
    });

    test('decodes a realistic idling-engine packet end to end', () {
      final values = EcuPacketDecoder.decodeSensors(buildPacket(
        techoHigh: 5, techoLow: 120, // 5*256+120 = 1400 RPM
        speed: 0,
        water: 130,   // 90 °C
        airTemp: 62,  // 32 °C
        map: 30,
        tps: 0,
        batt: 142,    // 14.2 V
        ignitiHigh: 2, ignitiLow: 188, // (700-640)/10 = 6.0°
        inject: 18,   // 1.8 ms
        afr: 147,     // 14.7
        sTrim: 130,   // +2 %
        lTrim: 125,   // -3 %
        iacv: 35,
      ));

      expect(values['TECHO'], 1400);
      expect(values['SPEED'], 0);
      expect(values['WATER'], 90);
      expect(values['AIR.T'], 32);
      expect(values['BATT'], 14.2);
      expect(values['IGNITI'], closeTo(6.0, 0.001));
      expect(values['INJECT'], closeTo(1.8, 0.001));
      expect(values['AFR'], closeTo(14.7, 0.001));
      expect(values['S.TRIM'], 2);
      expect(values['L.TRIM'], -3);
      expect(values['IACV'], 35);
    });
  });
}
