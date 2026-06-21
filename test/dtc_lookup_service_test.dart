import 'package:flutter_test/flutter_test.dart';
import 'package:safescan/core/models/obd_data.dart';
import 'package:safescan/core/services/dtc_lookup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    DtcCode.registerResolver((_) => DtcCode.fallback('P0000'));
    await DtcLookupService.load();
    DtcCode.registerResolver(DtcLookupService.instance.resolve);
  });

  group('DtcLookupService', () {
    test('loads thousands of OBD codes from asset', () {
      expect(DtcLookupService.instance.count, greaterThan(3000));
    });

    test('resolves known code with Spanish content', () {
      final code = DtcLookupService.instance.resolve('P0301');

      expect(code.code, 'P0301');
      expect(code.description, contains('cilindro'));
      expect(code.severity, 'medium');
      expect(code.recommendation, isNotEmpty);
      expect(code.explanation, isNotEmpty);
    });

    test('maps urgencia rojo to urgent severity', () {
      final code = DtcLookupService.instance.lookup('P0210');
      expect(code, isNotNull);
      expect(code!.severity, 'urgent');
    });

    test('falls back for unknown codes', () {
      final code = DtcLookupService.instance.resolve('P9999');

      expect(code.code, 'P9999');
      expect(code.description, contains('P'));
      expect(code.recommendation, isNotEmpty);
    });
  });

  group('DtcCode.fromCode', () {
    test('uses lookup service when registered', () {
      final code = DtcCode.fromCode('P0301');
      expect(code.description, isNot(equals('Código de diagnóstico P')));
    });
  });
}
