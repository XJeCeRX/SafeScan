import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:safescan/core/models/obd_data.dart';
import 'package:safescan/core/models/diagnosis_request.dart';
import 'package:safescan/core/services/diagnosis_queue.dart';

void main() {
  late Directory tempDir;
  late DiagnosisQueue queue;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    queue = DiagnosisQueue();
    await queue.init();
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('DiagnosisQueue manages request lifecycle, retry, delete, and clear', () async {
    final id = queue.addRequest(
      vehicleData: VehicleData.empty,
      dtcCodes: [
        const DtcCode(
          code: 'P0300',
          description: 'Fallo aleatorio de encendido',
          severity: 'urgent',
          recommendation: 'Revisar bujías.',
        ),
      ],
    );

    expect(queue.requests.length, 1);
    expect(queue.requests.first.status, DiagnosisStatus.pending);

    await queue.markSending(id);
    expect(queue.requests.first.status, DiagnosisStatus.sending);

    await queue.markFailed(id);
    expect(queue.requests.first.status, DiagnosisStatus.failed);

    await queue.retryRequest(id);
    expect(queue.requests.first.status, DiagnosisStatus.pending);

    await queue.markCompleted(id, '{"status":"ok"}');
    expect(queue.requests.first.status, DiagnosisStatus.completed);

    await queue.deleteRequest(id);
    expect(queue.requests.isEmpty, true);

    queue.addRequest(vehicleData: VehicleData.empty, dtcCodes: []);
    queue.addRequest(vehicleData: VehicleData.empty, dtcCodes: []);
    expect(queue.requests.length, 2);

    await queue.clearAll();
    expect(queue.requests.isEmpty, true);
  });
}
