class DtcCode {
  final String code;
  final String description;
  final String severity;
  final String recommendation;
  final String? explanation;
  final String? technicalDescription;

  static DtcCode Function(String code)? _resolver;

  const DtcCode({
    required this.code,
    required this.description,
    required this.severity,
    required this.recommendation,
    this.explanation,
    this.technicalDescription,
  });

  static void registerResolver(DtcCode Function(String code) resolver) {
    _resolver = resolver;
  }

  static DtcCode fromRawBytes(int byte1, int byte2) {
    final prefix = _getPrefix(byte1);
    final digit = _getDigit(byte1);
    final secondDigit = (byte1 & 0x0F).toRadixString(16).toUpperCase();
    final lastTwoDigits = byte2.toRadixString(16).padLeft(2, '0').toUpperCase();
    final codeStr = '$prefix$digit$secondDigit$lastTwoDigits';
    return fromCode(codeStr);
  }

  static DtcCode fromCode(String code) {
    final normalized = code.toUpperCase();
    final resolver = _resolver;
    if (resolver != null) {
      return resolver(normalized);
    }
    return fallback(normalized);
  }

  static DtcCode fallback(String code) {
    final prefix = code.isNotEmpty ? code[0] : 'P';
    final severity = (prefix == 'B' || prefix == 'C') ? 'urgent' : 'medium';
    return DtcCode(
      code: code,
      description: 'Código de diagnóstico $prefix',
      severity: severity,
      recommendation: 'Consulta el manual del vehículo para más información.',
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'description': description,
    'severity': severity,
    'recommendation': recommendation,
    if (explanation != null) 'explanation': explanation,
    if (technicalDescription != null)
      'technical_description': technicalDescription,
  };

  factory DtcCode.fromJson(Map<String, dynamic> json) {
    return DtcCode(
      code: json['code'] as String,
      description: json['description'] as String,
      severity: json['severity'] as String,
      recommendation: json['recommendation'] as String,
      explanation: json['explanation'] as String?,
      technicalDescription: json['technical_description'] as String?,
    );
  }

  static String _getPrefix(int byte1) {
    switch ((byte1 >> 6) & 0x03) {
      case 0:
        return 'P';
      case 1:
        return 'C';
      case 2:
        return 'B';
      case 3:
        return 'U';
      default:
        return 'P';
    }
  }

  static String _getDigit(int byte1) {
    return '${(byte1 >> 4) & 0x03}';
  }
}

class VehicleData {
  final int rpm;
  final int coolantTemp;
  final int speed;
  final double batteryVoltage;
  final int engineLoad;
  final int intakeTemp;
  final int throttlePosition;
  final double fuelLevel;
  final Duration timestamp;

  const VehicleData({
    required this.rpm,
    required this.coolantTemp,
    required this.speed,
    required this.batteryVoltage,
    required this.engineLoad,
    required this.intakeTemp,
    required this.throttlePosition,
    required this.fuelLevel,
    required this.timestamp,
  });

  static const empty = VehicleData(
    rpm: 0,
    coolantTemp: 0,
    speed: 0,
    batteryVoltage: 0,
    engineLoad: 0,
    intakeTemp: 0,
    throttlePosition: 0,
    fuelLevel: 0,
    timestamp: Duration.zero,
  );

  Map<String, dynamic> toJson() => {
    'rpm': rpm,
    'coolant_temp': coolantTemp,
    'speed': speed,
    'battery_voltage': batteryVoltage,
    'engine_load': engineLoad,
    'intake_temp': intakeTemp,
    'throttle_position': throttlePosition,
    'fuel_level': fuelLevel,
    'timestamp_ms': timestamp.inMilliseconds,
  };

  factory VehicleData.fromJson(Map<String, dynamic> json) {
    return VehicleData(
      rpm: json['rpm'] as int? ?? 0,
      coolantTemp: json['coolant_temp'] as int? ?? 0,
      speed: json['speed'] as int? ?? 0,
      batteryVoltage: (json['battery_voltage'] as num?)?.toDouble() ?? 0,
      engineLoad: json['engine_load'] as int? ?? 0,
      intakeTemp: json['intake_temp'] as int? ?? 0,
      throttlePosition: json['throttle_position'] as int? ?? 0,
      fuelLevel: (json['fuel_level'] as num?)?.toDouble() ?? 0,
      timestamp: Duration(
        milliseconds: json['timestamp_ms'] as int? ?? 0,
      ),
    );
  }
}
