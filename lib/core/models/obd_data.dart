class DtcCode {
  final String code;
  final String description;
  final String severity;
  final String recommendation;

  const DtcCode({
    required this.code,
    required this.description,
    required this.severity,
    required this.recommendation,
  });

  static const Map<String, _DtcInfo> _knownCodes = {
    'P0300': _DtcInfo(
      'Fallo en cilindros',
      'urgent',
      'Ve a un taller lo antes posible.',
    ),
    'P0301': _DtcInfo(
      'Fallo en cilindro 1',
      'urgent',
      'Ve a un taller lo antes posible.',
    ),
    'P0302': _DtcInfo(
      'Fallo en cilindro 2',
      'urgent',
      'Ve a un taller lo antes posible.',
    ),
    'P0303': _DtcInfo(
      'Fallo en cilindro 3',
      'urgent',
      'Ve a un taller lo antes posible.',
    ),
    'P0304': _DtcInfo(
      'Fallo en cilindro 4',
      'urgent',
      'Ve a un taller lo antes posible.',
    ),
    'P0171': _DtcInfo(
      'Mezcla de combustible pobre',
      'medium',
      'Revisa el filtro de aire y los inyectores.',
    ),
    'P0172': _DtcInfo(
      'Mezcla de combustible rica',
      'medium',
      'Revisa el filtro de aire y los inyectores.',
    ),
    'P0420': _DtcInfo(
      'Eficiencia del catalizador baja',
      'low',
      'Puedes seguir manejando, pero agenda una revisión.',
    ),
    'P0430': _DtcInfo(
      'Eficiencia del catalizador baja (banco 2)',
      'low',
      'Puedes seguir manejando, pero agenda una revisión.',
    ),
    'P0400': _DtcInfo(
      'Fallo en EGR',
      'medium',
      'Revisa el sistema de recirculación de gases.',
    ),
    'P0401': _DtcInfo(
      'Flujo EGR insuficiente',
      'medium',
      'Revisa el sistema de recirculación de gases.',
    ),
    'P0101': _DtcInfo(
      'Fallo MAF / flujo de aire',
      'medium',
      'Revisa el sensor MAF y conductos de admisión.',
    ),
    'P0113': _DtcInfo(
      'Sensor IAT / temperatura alta',
      'low',
      'Revisa el sensor de temperatura de admisión.',
    ),
    'P0128': _DtcInfo(
      'Termostato / temperatura baja',
      'medium',
      'Revisa el termostato del motor.',
    ),
    'P0135': _DtcInfo(
      'Calentador O2 banco 1',
      'medium',
      'Revisa el sensor de oxígeno banco 1.',
    ),
    'P0141': _DtcInfo(
      'Calentador O2 banco 1 sensor 2',
      'medium',
      'Revisa el sensor de oxígeno banco 1 sensor 2.',
    ),
    'P0500': _DtcInfo(
      'Sensor de velocidad',
      'medium',
      'Revisa el sensor de velocidad del vehículo.',
    ),
    'P0505': _DtcInfo(
      'Fallo IAC / ralentí',
      'medium',
      'Revisa el motor de ralentí.',
    ),
    'P0600': _DtcInfo(
      'Fallo comunicación PCM',
      'urgent',
      'Ve a un taller especializado lo antes posible.',
    ),
    'P0606': _DtcInfo(
      'Fallo interno PCM',
      'urgent',
      'Ve a un taller especializado lo antes posible.',
    ),
    'P0700': _DtcInfo(
      'Fallo transmisión',
      'urgent',
      'Revisa la transmisión en un taller.',
    ),
    'P1000': _DtcInfo(
      'Monitoreo OBD incompleto',
      'low',
      'Conduce el vehículo para completar los monitores.',
    ),
  };

  static DtcCode fromRawBytes(int byte1, int byte2) {
    final prefix = _getPrefix(byte1);
    final digit = _getDigit(byte1);
    final secondDigit = (byte1 & 0x0F).toRadixString(16).toUpperCase();
    final lastTwoDigits = byte2.toRadixString(16).padLeft(2, '0').toUpperCase();
    final codeStr = '$prefix$digit$secondDigit$lastTwoDigits';
    return fromCode(codeStr);
  }

  static DtcCode fromCode(String code) {
    final known = _knownCodes[code.toUpperCase()];
    if (known != null) {
      return DtcCode(
        code: code.toUpperCase(),
        description: known.description,
        severity: known.severity,
        recommendation: known.recommendation,
      );
    }
    final prefix = code.isNotEmpty ? code[0] : 'P';
    final sev = (prefix == 'B' || prefix == 'C') ? 'urgent' : 'medium';
    return DtcCode(
      code: code.toUpperCase(),
      description: 'Código de diagnóstico $prefix',
      severity: sev,
      recommendation: 'Consulta el manual del vehículo para más información.',
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'description': description,
    'severity': severity,
    'recommendation': recommendation,
  };

  factory DtcCode.fromJson(Map<String, dynamic> json) {
    return DtcCode(
      code: json['code'] as String,
      description: json['description'] as String,
      severity: json['severity'] as String,
      recommendation: json['recommendation'] as String,
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

class _DtcInfo {
  final String description;
  final String severity;
  final String recommendation;
  const _DtcInfo(this.description, this.severity, this.recommendation);
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
