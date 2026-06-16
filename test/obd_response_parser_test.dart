import 'package:flutter_test/flutter_test.dart';
import 'package:safescan/core/models/obd_data.dart';
import 'package:safescan/core/services/obd_response_parser.dart';

void main() {
  group('DtcCode', () {
    test('decodes raw SAE bytes as hexadecimal DTC digits', () {
      expect(DtcCode.fromRawBytes(0x01, 0x33).code, 'P0133');
      expect(DtcCode.fromRawBytes(0x03, 0x01).code, 'P0301');
      expect(DtcCode.fromRawBytes(0xC1, 0x00).code, 'U0100');
    });
  });

  group('ObdResponseParser', () {
    test(
      'extracts PID payloads from spaced, compact and echoed ELM responses',
      () {
        expect(ObdResponseParser.twoBytePayload('41 0C 1A F8', 0x0C), (
          0x1A,
          0xF8,
        ));
        expect(ObdResponseParser.twoBytePayload('410C1AF8', 0x0C), (
          0x1A,
          0xF8,
        ));
        expect(
          ObdResponseParser.twoBytePayload(
            '010C SEARCHING... 41 0C 1A F8',
            0x0C,
          ),
          (0x1A, 0xF8),
        );
      },
    );

    test('parses service 03 DTC responses and ignores empty codes', () {
      final codes = ObdResponseParser.dtcCodes('03 43 01 33 03 01 00 00');

      expect(codes.map((code) => code.code), ['P0133', 'P0301']);
    });

    test('reads DTC count from service 01 PID 01 status byte', () {
      expect(ObdResponseParser.dtcCount('41 01 82 07 65 04'), 2);
    });
  });
}
