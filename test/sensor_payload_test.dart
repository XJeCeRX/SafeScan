import 'package:flutter_test/flutter_test.dart';
import 'package:safescan/core/models/obd_data.dart';
import 'package:safescan/core/models/sensor_payload.dart';

void main() {
  group('SensorPayload', () {
    test('serializa y deserializa datos OBD correctamente', () {
      final payload = SensorPayload(
        obdConnected: true,
        adapterIp: '192.168.0.10',
        vehicleData: const VehicleData(
          rpm: 850,
          coolantTemp: 92,
          speed: 0,
          batteryVoltage: 13.8,
          engineLoad: 18,
          intakeTemp: 35,
          throttlePosition: 12,
          fuelLevel: 62.5,
          timestamp: Duration(milliseconds: 1),
        ),
        dtcCodes: const [
          DtcCode(
            code: 'P0300',
            description: 'Fallo en cilindros',
            severity: 'urgent',
            recommendation: 'Ve a un taller lo antes posible.',
          ),
        ],
        capturedAt: DateTime.parse('2026-06-19T12:00:00.000'),
      );

      final restored = SensorPayload.fromJson(payload.toJson());

      expect(restored.obdConnected, isTrue);
      expect(restored.adapterIp, '192.168.0.10');
      expect(restored.vehicleData.rpm, 850);
      expect(restored.vehicleData.coolantTemp, 92);
      expect(restored.dtcCodes, hasLength(1));
      expect(restored.dtcCodes.first.code, 'P0300');
    });
  });
}
