import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/obd_data.dart';

/// Motor de búsqueda offline de códigos DTC desde un JSON embebido.
///
/// Resolución en cascada:
/// 1. Match exacto por clave (`P0301`).
/// 2. Orientación por familia SAE (`P03xx`) si hay vecinos en la base.
/// 3. Fallback genérico si no hay ficha ni familia.
///
/// Al crecer el JSON, no hace falta tocar esta lógica: el índice de familias
/// se reconstruye en cada [load].
class DtcLookupService {
  DtcLookupService._(this._entries, this._familyIndex);

  static DtcLookupService? _instance;

  static bool get isInitialized => _instance != null;

  static DtcLookupService get instance {
    final service = _instance;
    if (service == null) {
      throw StateError(
        'DtcLookupService no está inicializado. Llama a load() en main().',
      );
    }
    return service;
  }

  final Map<String, _DtcEntry> _entries;
  final Map<String, List<_DtcEntry>> _familyIndex;

  int get count => _entries.length;

  static Future<DtcLookupService> load({
    String assetPath = 'assets/obd2_explicaciones.json',
  }) async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final entries = <String, _DtcEntry>{};
    final familyIndex = <String, List<_DtcEntry>>{};

    for (final entry in decoded.entries) {
      final value = entry.value;
      if (value is! Map<String, dynamic>) continue;
      final code = (value['codigo'] as String? ?? entry.key).toUpperCase();
      final dtcEntry = _DtcEntry.fromJson(code, value);
      entries[code] = dtcEntry;

      final family = familyKeyFor(code);
      if (family != null) {
        familyIndex.putIfAbsent(family, () => <_DtcEntry>[]).add(dtcEntry);
      }
    }

    final service = DtcLookupService._(entries, familyIndex);
    _instance = service;
    return service;
  }

  /// Prefijo de familia SAE: primeras 3 caracteres de un DTC de 5 (`P0301` → `P03`).
  static String? familyKeyFor(String code) {
    final normalized = code.toUpperCase().trim();
    if (normalized.length < 3) return null;
    return normalized.substring(0, 3);
  }

  DtcCode? lookup(String code) {
    final entry = _entries[code.toUpperCase()];
    return entry?.toDtcCode(matchType: DtcMatchType.exact);
  }

  DtcCode resolve(String code) {
    final normalized = code.toUpperCase().trim();
    final exact = lookup(normalized);
    if (exact != null) return exact;

    final family = _resolveByFamily(normalized);
    if (family != null) return family;

    return DtcCode.fallback(normalized);
  }

  DtcCode? _resolveByFamily(String code) {
    final key = familyKeyFor(code);
    if (key == null) return null;

    final siblings = _familyIndex[key];
    if (siblings == null || siblings.isEmpty) return null;

    final related = _pickRelatedEntry(siblings, key);
    final familyLabel = _familyLabelFor(key);
    final severity = _mostUrgentSeverity(siblings);

    final samples = siblings
        .take(3)
        .map((e) => '• ${e.code}: ${e.titulo}')
        .join('\n');

    return DtcCode(
      code: code,
      description: 'Orientación por familia $key — $familyLabel',
      severity: severity,
      recommendation:
          'No hay ficha exacta de $code. Revisa códigos similares de la '
          'familia $key (p. ej. ${related.code}) y consulta un taller si '
          'el síntoma continúa.',
      explanation:
          'No encontramos la explicación exacta de $code en la base local. '
          'Sí hay códigos de la misma familia SAE ($key: $familyLabel).\n\n'
          'Esto es solo orientación, no un diagnóstico exacto.\n\n'
          'Ejemplos cercanos en la base:\n$samples',
      technicalDescription: related.descripcionTecnica.isNotEmpty
          ? 'Referencia de familia (${related.code}): ${related.descripcionTecnica}'
          : null,
      matchType: DtcMatchType.family,
      relatedCode: related.code,
      familyKey: key,
      familyLabel: familyLabel,
    );
  }

  /// Prefiere el código genérico de familia (`P0300`) si existe; si no, el primero.
  static _DtcEntry _pickRelatedEntry(List<_DtcEntry> siblings, String familyKey) {
    final generic = '${familyKey}00';
    for (final entry in siblings) {
      if (entry.code == generic) return entry;
    }
    return siblings.first;
  }

  static String _mostUrgentSeverity(List<_DtcEntry> siblings) {
    var best = 'low';
    for (final entry in siblings) {
      final mapped = _DtcEntry.mapUrgencia(entry.urgencia);
      if (_severityRank(mapped) > _severityRank(best)) {
        best = mapped;
      }
    }
    return best;
  }

  static int _severityRank(String severity) {
    switch (severity) {
      case 'urgent':
        return 3;
      case 'medium':
        return 2;
      default:
        return 1;
    }
  }

  static String _familyLabelFor(String familyKey) {
    return _familyLabels[familyKey] ?? _genericFamilyLabel(familyKey);
  }

  static String _genericFamilyLabel(String familyKey) {
    final letter = familyKey.isNotEmpty ? familyKey[0] : 'P';
    switch (letter) {
      case 'C':
        return 'Sistema de chasis';
      case 'B':
        return 'Carrocería / habitáculo';
      case 'U':
        return 'Red de comunicación del vehículo';
      case 'P':
      default:
        return 'Sistema del motor / transmisión';
    }
  }

  /// Etiquetas legibles para familias SAE frecuentes.
  /// Familias no listadas usan [_genericFamilyLabel]; al crecer el JSON
  /// siguen resolviéndose por prefijo aunque no tengan etiqueta propia.
  static const Map<String, String> _familyLabels = {
    'P00': 'Sensores de combustible y aire',
    'P01': 'Mezcla de combustible',
    'P02': 'Inyectores y circuito de combustible',
    'P03': 'Fallos de encendido',
    'P04': 'Control de emisiones auxiliares',
    'P05': 'Control de velocidad / ralentí',
    'P06': 'Circuitos de control del ECM',
    'P07': 'Transmisión',
    'P08': 'Transmisión',
    'P09': 'Transmisión',
    'P0A': 'Sistema híbrido',
    'P0B': 'Sistema híbrido / batería',
    'P0C': 'Sistema híbrido',
    'P10': 'Códigos específicos del fabricante (motor)',
    'P11': 'Códigos específicos del fabricante (motor)',
    'P12': 'Códigos específicos del fabricante (motor)',
    'P13': 'Códigos específicos del fabricante (motor)',
    'P14': 'Códigos específicos del fabricante (motor)',
    'P15': 'Códigos específicos del fabricante (motor)',
    'P16': 'Códigos específicos del fabricante (motor)',
    'P17': 'Códigos específicos del fabricante (transmisión)',
    'P18': 'Códigos específicos del fabricante (transmisión)',
    'P19': 'Códigos específicos del fabricante (transmisión)',
    'P20': 'Control de emisiones / reductor',
    'P21': 'Control de emisiones',
    'P22': 'Control de emisiones',
    'P24': 'Control de emisiones',
    'P26': 'Circuitos de control del motor',
    'C00': 'ABS / frenos',
    'C01': 'ABS / frenos',
    'C02': 'Suspensión / dirección',
    'B00': 'Airbag / retención',
    'B01': 'Carrocería',
    'U00': 'Red de comunicación',
    'U01': 'Pérdida de comunicación con módulos',
    'U02': 'Red de comunicación',
    'U03': 'Software / configuración de red',
  };
}

class _DtcEntry {
  const _DtcEntry({
    required this.code,
    required this.titulo,
    required this.explicacion,
    required this.accion,
    required this.urgencia,
    required this.descripcionTecnica,
  });

  final String code;
  final String titulo;
  final String explicacion;
  final String accion;
  final String urgencia;
  final String descripcionTecnica;

  factory _DtcEntry.fromJson(String code, Map<String, dynamic> json) {
    return _DtcEntry(
      code: code,
      titulo: json['titulo'] as String? ?? 'Código $code',
      explicacion: json['explicacion'] as String? ?? '',
      accion: json['accion'] as String? ?? '',
      urgencia: json['urgencia'] as String? ?? 'amarillo',
      descripcionTecnica: json['descripcion_tecnica'] as String? ?? '',
    );
  }

  DtcCode toDtcCode({DtcMatchType matchType = DtcMatchType.exact}) {
    return DtcCode(
      code: code,
      description: titulo,
      severity: mapUrgencia(urgencia),
      recommendation: accion.isNotEmpty ? accion : explicacion,
      explanation: explicacion.isNotEmpty ? explicacion : null,
      technicalDescription:
          descripcionTecnica.isNotEmpty ? descripcionTecnica : null,
      matchType: matchType,
      familyKey: DtcLookupService.familyKeyFor(code),
    );
  }

  static String mapUrgencia(String urgencia) {
    switch (urgencia.toLowerCase()) {
      case 'rojo':
        return 'urgent';
      case 'verde':
        return 'low';
      case 'amarillo':
      default:
        return 'medium';
    }
  }
}
