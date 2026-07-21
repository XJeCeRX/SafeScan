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
    test('loads v5 OBD corpus from asset', () {
      expect(DtcLookupService.instance.count, greaterThanOrEqualTo(4100));
    });

    test('resolves known code with Spanish content', () {
      final code = DtcLookupService.instance.resolve('P0301');

      expect(code.code, 'P0301');
      expect(code.description, contains('cilindro'));
      expect(code.severity, 'urgent'); // v5: P0301 recalibrado a rojo
      expect(code.recommendation, isNotEmpty);
      expect(code.explanation, isNotEmpty);
      expect(code.matchType, DtcMatchType.exact);
      expect(code.isExactMatch, isTrue);
    });

    test('maps urgencia rojo to urgent severity', () {
      final code = DtcLookupService.instance.lookup('P0210');
      expect(code, isNotNull);
      expect(code!.severity, 'urgent');
      expect(code.matchType, DtcMatchType.exact);
    });

    test('P0171 urgency is consistent across repeated lookups', () {
      const expectedUrgencia = 'urgent'; // v5: amarillo → rojo

      for (var i = 0; i < 5; i++) {
        final code = DtcLookupService.instance.resolve('P0171');
        expect(code.code, 'P0171');
        expect(code.severity, expectedUrgencia);
        expect(code.description, contains('Mezcla'));
        expect(code.matchType, DtcMatchType.exact);
      }

      expect(DtcLookupService.instance.resolve('p0171').severity, expectedUrgencia);
    });

    test('uses family orientation when exact code is missing but siblings exist', () {
      // P0399 no está en el JSON actual; la familia P03 sí tiene vecinos.
      final code = DtcLookupService.instance.resolve('P0399');

      expect(code.code, 'P0399');
      expect(code.matchType, DtcMatchType.family);
      expect(code.isFamilyMatch, isTrue);
      expect(code.familyKey, 'P03');
      expect(code.familyLabel, contains('encendido'));
      expect(code.relatedCode, 'P0300');
      expect(code.description, contains('familia P03'));
      expect(code.explanation, contains('no un diagnóstico exacto'));
      expect(code.recommendation, isNotEmpty);
    });

    test('falls back to unknown when code and family are missing', () {
      final code = DtcLookupService.instance.resolve('P9999');

      expect(code.code, 'P9999');
      expect(code.matchType, DtcMatchType.unknown);
      expect(code.isUnknownMatch, isTrue);
      expect(code.description, contains('P'));
      expect(code.recommendation, isNotEmpty);
    });

    test('familyKeyFor extracts SAE prefix', () {
      expect(DtcLookupService.familyKeyFor('P0301'), 'P03');
      expect(DtcLookupService.familyKeyFor('u0100'), 'U01');
      expect(DtcLookupService.familyKeyFor('AB'), isNull);
    });
  });

  group('DtcCode.fromCode', () {
    test('uses lookup service when registered', () {
      final code = DtcCode.fromCode('P0301');
      expect(code.description, isNot(equals('Código de diagnóstico P')));
      expect(code.matchType, DtcMatchType.exact);
    });

    test('serializes match metadata', () {
      const code = DtcCode(
        code: 'P0399',
        description: 'Orientación por familia',
        severity: 'medium',
        recommendation: 'Revisa en taller',
        matchType: DtcMatchType.family,
        relatedCode: 'P0300',
        familyKey: 'P03',
        familyLabel: 'Fallos de encendido',
      );

      final restored = DtcCode.fromJson(code.toJson());
      expect(restored.matchType, DtcMatchType.family);
      expect(restored.relatedCode, 'P0300');
      expect(restored.familyKey, 'P03');
      expect(restored.familyLabel, 'Fallos de encendido');
    });
  });
}
