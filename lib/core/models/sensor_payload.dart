import 'obd_data.dart';
import '../services/obd_manager.dart';

/// Datos de sensores OBD enviados junto con un mensaje de chat.
class SensorPayload {
  final bool obdConnected;
  final String? adapterIp;
  final VehicleData vehicleData;
  final List<DtcCode> dtcCodes;
  final DateTime capturedAt;

  const SensorPayload({
    required this.obdConnected,
    this.adapterIp,
    required this.vehicleData,
    required this.dtcCodes,
    required this.capturedAt,
  });

  bool get hasVehicleReadings =>
      obdConnected && vehicleData != VehicleData.empty;

  bool get hasDtcCodes => dtcCodes.isNotEmpty;

  factory SensorPayload.fromObdManager(ObdManager obdManager) {
    return SensorPayload(
      obdConnected: obdManager.isConnected,
      adapterIp: obdManager.connectedIp,
      vehicleData: obdManager.vehicleData,
      dtcCodes: List.unmodifiable(obdManager.dtcCodes),
      capturedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'obd_connected': obdConnected,
    if (adapterIp != null) 'adapter_ip': adapterIp,
    'captured_at': capturedAt.toIso8601String(),
    'vehicle': vehicleData.toJson(),
    'dtc_codes': dtcCodes.map((c) => c.toJson()).toList(),
  };

  factory SensorPayload.fromJson(Map<String, dynamic> json) {
    return SensorPayload(
      obdConnected: json['obd_connected'] as bool? ?? false,
      adapterIp: json['adapter_ip'] as String?,
      vehicleData: VehicleData.fromJson(
        json['vehicle'] as Map<String, dynamic>? ?? {},
      ),
      dtcCodes: (json['dtc_codes'] as List<dynamic>? ?? [])
          .map((e) => DtcCode.fromJson(e as Map<String, dynamic>))
          .toList(),
      capturedAt: DateTime.parse(
        json['captured_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
