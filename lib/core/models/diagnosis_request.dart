import 'dart:convert';
import 'obd_data.dart';

enum DiagnosisStatus { pending, sending, completed, failed }

class DiagnosisRequest {
  final String id;
  final DateTime createdAt;
  final VehicleData vehicleData;
  final List<DtcCode> dtcCodes;
  final DiagnosisStatus status;
  final String? resultJson;
  final DateTime? completedAt;

  const DiagnosisRequest({
    required this.id,
    required this.createdAt,
    required this.vehicleData,
    required this.dtcCodes,
    this.status = DiagnosisStatus.pending,
    this.resultJson,
    this.completedAt,
  });

  DiagnosisRequest copyWith({
    DiagnosisStatus? status,
    String? resultJson,
    DateTime? completedAt,
  }) {
    return DiagnosisRequest(
      id: id,
      createdAt: createdAt,
      vehicleData: vehicleData,
      dtcCodes: dtcCodes,
      status: status ?? this.status,
      resultJson: resultJson ?? this.resultJson,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  String toJson() {
    final map = <String, dynamic>{
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'vehicle_data': vehicleData.toJson(),
      'dtc_codes': dtcCodes.map((c) => c.toJson()).toList(),
      'status': status.name,
      'result_json': resultJson,
      'completed_at': completedAt?.toIso8601String(),
    };
    return jsonEncode(map);
  }

  factory DiagnosisRequest.fromJson(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return DiagnosisRequest(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      vehicleData: VehicleData.fromJson(
        map['vehicle_data'] as Map<String, dynamic>,
      ),
      dtcCodes: (map['dtc_codes'] as List)
          .map((c) => DtcCode.fromJson(c as Map<String, dynamic>))
          .toList(),
      status: DiagnosisStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => DiagnosisStatus.pending,
      ),
      resultJson: map['result_json'] as String?,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
    );
  }
}
