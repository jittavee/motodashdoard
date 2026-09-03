import 'package:flutter_test/flutter_test.dart';
import 'package:api_tech_moto/utils/dongle_message.dart';

void main() {
  group('DongleMessage.classify - command echo', () {
    test('classifies our own "model=N" command as echo', () {
      for (var i = 0; i <= 3; i++) {
        expect(DongleMessage.classify('model=$i'), isA<CommandEcho>(),
            reason: 'model=$i is an echo of our own command');
      }
    });

    test('echo match is case-insensitive', () {
      expect(DongleMessage.classify('MODEL=1'), isA<CommandEcho>());
    });

    test('tolerates surrounding whitespace', () {
      expect(DongleMessage.classify('  model=2\r\n'), isA<CommandEcho>());
    });

    test('"model=10" is not an echo (pattern is a single digit)', () {
      expect(DongleMessage.classify('model=10'), isNot(isA<CommandEcho>()));
    });
  });

  group('DongleMessage.classify - EcuModel ACK', () {
    test('classifies "EcuModel=N" as an ACK carrying the value', () {
      for (var i = 0; i <= 3; i++) {
        final message = DongleMessage.classify('EcuModel=$i');
        expect(message, isA<EcuModelAck>());
        expect((message as EcuModelAck).modelValue, i);
      }
    });

    test('ACK match is case-insensitive', () {
      expect(DongleMessage.classify('ecumodel=3'), isA<EcuModelAck>());
    });

    test('ACK is distinguished from our own echo', () {
      // ต่างกันแค่ prefix — จุดที่พลาดง่ายสุดของ dispatch logic
      expect(DongleMessage.classify('EcuModel=1'), isA<EcuModelAck>());
      expect(DongleMessage.classify('model=1'), isA<CommandEcho>());
    });
  });

  group('DongleMessage.classify - ECU link status', () {
    test('classifies each documented status string', () {
      for (final raw in ['Connected', 'No_response', 'Connecting...']) {
        final message = DongleMessage.classify('ECU=$raw');
        expect(message, isA<EcuStatusUpdate>(), reason: raw);
        expect((message as EcuStatusUpdate).rawStatus, raw);
      }
    });

    test('status match is case-insensitive on the key', () {
      expect(DongleMessage.classify('ecu=Connected'), isA<EcuStatusUpdate>());
    });

    test('unrecognized status text still classifies as a status update', () {
      // ปล่อยให้ EcuConnectionStatus.fromString ตัดสินใจ fallback เอง
      final message = DongleMessage.classify('ECU=Something_New');
      expect(message, isA<EcuStatusUpdate>());
      expect((message as EcuStatusUpdate).rawStatus, 'Something_New');
    });
  });

  group('DongleMessage.classify - gauge readings', () {
    test('classifies a KEY=VALUE reading as a gauge reading', () {
      final message = DongleMessage.classify('TECHO=1000');
      expect(message, isA<GaugeReading>());
      expect((message as GaugeReading).payload, 'TECHO=1000');
    });

    test('payload is trimmed for the downstream parser', () {
      final message = DongleMessage.classify('  SPEED=80\r\n');
      expect((message as GaugeReading).payload, 'SPEED=80');
    });

    test('every documented gauge key classifies as a reading', () {
      const keys = [
        'TECHO', 'SPEED', 'WATER', 'AIR.T', 'MAP', 'TPS', 'BATT',
        'IGNITI', 'INJECT', 'AFR', 'S.TRIM', 'L.TRIM', 'IACV',
      ];
      for (final key in keys) {
        expect(DongleMessage.classify('$key=1'), isA<GaugeReading>(),
            reason: key);
      }
    });

    test('garbage falls through to gauge reading for the parser to reject', () {
      // classify ไม่ validate — EcuParser เป็นคนปฏิเสธ
      expect(DongleMessage.classify('garbage'), isA<GaugeReading>());
      expect(DongleMessage.classify(''), isA<GaugeReading>());
    });
  });
}
