import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/obd_data.dart';

/// Motor de búsqueda offline de códigos DTC desde un JSON embebido.
class DtcLookupService {
  DtcLookupService._(this._entries);

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

  int get count => _entries.length;

  static Future<DtcLookupService> load({
    String assetPath = 'assets/obd2_explicaciones.json',
  }) async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final entries = <String, _DtcEntry>{};

    for (final entry in decoded.entries) {
      final value = entry.value;
      if (value is! Map<String, dynamic>) continue;
      final code = (value['codigo'] as String? ?? entry.key).toUpperCase();
      entries[code] = _DtcEntry.fromJson(code, value);
    }

    final service = DtcLookupService._(entries);
    _instance = service;
    return service;
  }

  DtcCode? lookup(String code) {
    final entry = _entries[code.toUpperCase()];
    return entry?.toDtcCode();
  }

  DtcCode resolve(String code) {
    return lookup(code) ?? DtcCode.fallback(code.toUpperCase());
  }
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

  DtcCode toDtcCode() {
    return DtcCode(
      code: code,
      description: titulo,
      severity: _mapUrgencia(urgencia),
      recommendation: accion.isNotEmpty ? accion : explicacion,
      explanation: explicacion.isNotEmpty ? explicacion : null,
      technicalDescription:
          descripcionTecnica.isNotEmpty ? descripcionTecnica : null,
    );
  }

  static String _mapUrgencia(String urgencia) {
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
