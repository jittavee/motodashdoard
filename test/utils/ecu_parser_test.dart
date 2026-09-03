import 'package:flutter_test/flutter_test.dart';
import 'package:api_tech_moto/utils/ecu_parser.dart';

void main() {
  group('EcuParser.parse - malformed input', () {
    test('rejects empty string', () {
      expect(EcuParser.parse(''), isNull);
    });

    test('rejects input with no equals sign', () {
      expect(EcuParser.parse('TECHO1000'), isNull);
    });

    test('rejects input with more than one equals sign', () {
      expect(EcuParser.parse('TECHO=10=00'), isNull);
    });

    test('rejects missing key', () {
      expect(EcuParser.parse('=1000'), isNull);
    });

    test('rejects missing value', () {
      expect(EcuParser.parse('TECHO='), isNull);
    });

    test('rejects unknown parameter key', () {
      expect(EcuParser.parse('UNKNOWN=100'), isNull);
    });

    test('rejects non-numeric value', () {
      expect(EcuParser.parse('TECHO=abc'), isNull);
    });

    test('rejects NaN literal', () {
      // double.tryParse('NaN') คืน NaN ซึ่งเทียบช่วงไม่ผ่าน จึงต้องถูกปฏิเสธ
      expect(EcuParser.parse('TECHO=NaN'), isNull);
    });

    test('rejects Infinity literal', () {
      expect(EcuParser.parse('TECHO=Infinity'), isNull);
    });
  });

  group('EcuParser.parse - well-formed input', () {
    test('parses integer value', () {
      final result = EcuParser.parse('TECHO=1000');
      expect(result?.key, 'TECHO');
      expect(result?.value, 1000);
    });

    test('parses decimal value', () {
      final result = EcuParser.parse('BATT=13.5');
      expect(result?.key, 'BATT');
      expect(result?.value, 13.5);
    });

    test('parses negative value where range allows', () {
      final result = EcuParser.parse('AIR.T=-10');
      expect(result?.value, -10);
    });

    test('uppercases lowercase key', () {
      expect(EcuParser.parse('techo=500')?.key, 'TECHO');
    });

    test('trims surrounding whitespace', () {
      final result = EcuParser.parse('  SPEED = 80  ');
      expect(result?.key, 'SPEED');
      expect(result?.value, 80);
    });

    test('accepts every documented parameter key', () {
      // ค่ากลางช่วงของแต่ละพารามิเตอร์ — ต้องผ่านทั้ง 13 ตัว
      const midRange = {
        'TECHO': '5000', 'SPEED': '80', 'WATER': '85', 'AIR.T': '30',
        'MAP': '100', 'TPS': '50', 'BATT': '13.5', 'IGNITI': '15',
        'INJECT': '5', 'AFR': '14.7', 'S.TRIM': '100', 'L.TRIM': '100',
        'IACV': '50',
      };
      expect(midRange.keys.toSet(), EcuParser.validKeys,
          reason: 'test data must cover exactly the documented key set');

      for (final entry in midRange.entries) {
        expect(EcuParser.parse('${entry.key}=${entry.value}'), isNotNull,
            reason: '${entry.key} should be accepted');
      }
    });
  });

  group('EcuParser.isValueInValidRange - boundaries', () {
    // (key, min, max) ตามช่วงจริงของเครื่องยนต์
    const ranges = <String, (double, double)>{
      'TECHO': (0, 20000),
      'SPEED': (0, 400),
      'WATER': (-40, 500),
      'AIR.T': (-40, 150),
      'MAP': (0, 300),
      'TPS': (0, 100),
      'BATT': (0, 20),
      'IGNITI': (-30, 60),
      'INJECT': (0, 50),
      'AFR': (5, 25),
      'S.TRIM': (0, 200),
      'L.TRIM': (0, 200),
      'IACV': (0, 100),
    };

    test('covers every valid key', () {
      expect(ranges.keys.toSet(), EcuParser.validKeys);
    });

    for (final entry in ranges.entries) {
      final key = entry.key;
      final (min, max) = entry.value;

      test('$key accepts inclusive bounds', () {
        expect(EcuParser.isValueInValidRange(key, min), isTrue,
            reason: 'min $min should be inclusive');
        expect(EcuParser.isValueInValidRange(key, max), isTrue,
            reason: 'max $max should be inclusive');
      });

      test('$key rejects values outside bounds', () {
        expect(EcuParser.isValueInValidRange(key, min - 1), isFalse,
            reason: 'below min should be rejected');
        expect(EcuParser.isValueInValidRange(key, max + 1), isFalse,
            reason: 'above max should be rejected');
      });
    }

    test('unknown key is permissive (no range defined)', () {
      // updateDataFromPacket พึ่ง validKeys กรอง key ก่อนแล้ว
      expect(EcuParser.isValueInValidRange('WHATEVER', 999999), isTrue);
    });
  });

  group('EcuParser.parse - noise rejection (BLE glitches)', () {
    test('rejects RPM above physical maximum', () {
      expect(EcuParser.parse('TECHO=25000'), isNull);
    });

    test('rejects negative speed', () {
      expect(EcuParser.parse('SPEED=-10'), isNull);
    });

    test('rejects impossible battery voltage', () {
      expect(EcuParser.parse('BATT=30'), isNull);
    });

    test('rejects AFR below lean-burn floor', () {
      // AFR 0 คือค่า sentinel ที่ dongle ส่งเมื่ออ่านไม่ได้ ไม่ใช่ค่าจริง
      expect(EcuParser.parse('AFR=0'), isNull);
    });
  });
}
