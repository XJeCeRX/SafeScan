import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/obd_data.dart';
import '../constants.dart';

/// Notificaciones locales pensadas para conductores:
/// - Urgente: tono corto (2 beeps), sin sirena.
/// - Moderado: chime suave.
/// - Leve: silencioso (no distrae al volante).
class DiagnosisNotificationService {
  DiagnosisNotificationService();

  static const _channelUrgent = AppConstants.notificationChannelUrgent;
  static const _channelMedium = AppConstants.notificationChannelMedium;
  static const _channelLow = AppConstants.notificationChannelLow;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Set<String> _lastNotifiedCodes = {};

  Future<void> init() async {
    if (_initialized) return;

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings();
      const linuxInit = LinuxInitializationSettings(defaultActionName: 'Open');
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
        linux: linuxInit,
      );

      await _plugin.initialize(settings: initSettings);

      if (!kIsWeb && Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await android?.requestNotificationsPermission();

        await android?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelUrgent,
            'Alertas urgentes del vehículo',
            description:
                'Fallos importantes. Tono corto de atención (no es una emergencia 911).',
            importance: Importance.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('alert_urgent'),
            enableVibration: true,
          ),
        );
        await android?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelMedium,
            'Alertas moderadas del vehículo',
            description: 'Códigos que conviene revisar. Tono suave.',
            importance: Importance.defaultImportance,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('alert_medium'),
            enableVibration: true,
          ),
        );
        await android?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelLow,
            'Avisos leves del vehículo',
            description: 'Informativos. Sin sonido para no distraer al conducir.',
            importance: Importance.low,
            playSound: false,
            enableVibration: false,
          ),
        );
      }

      _initialized = true;
    } catch (e) {
      debugPrint('DiagnosisNotificationService: no se pudieron inicializar las notificaciones: $e');
    }
  }

  /// Notifica solo si hay códigos nuevos respecto al último aviso.
  Future<void> notifyNewCodes(List<DtcCode> codes) async {
    if (!_initialized || codes.isEmpty) return;

    final current = codes.map((c) => c.code).toSet();
    final isSame = current.length == _lastNotifiedCodes.length &&
        current.containsAll(_lastNotifiedCodes);
    if (isSame) return;

    _lastNotifiedCodes = current;
    await _showSummary(codes);
  }

  Future<void> _showSummary(List<DtcCode> codes) async {
    final worst = _worstSeverity(codes);
    final urgent = codes.where((c) => c.severity == 'urgent').length;
    final medium = codes.where((c) => c.severity == 'medium').length;
    final low = codes.where((c) => c.severity == 'low').length;

    final title = switch (worst) {
      'urgent' => 'Atención: falla importante',
      'medium' => 'Alerta del vehículo',
      _ => 'Aviso del vehículo',
    };

    final parts = <String>[];
    if (urgent > 0) parts.add('$urgent urgente${urgent == 1 ? '' : 's'}');
    if (medium > 0) parts.add('$medium moderad${medium == 1 ? 'a' : 'as'}');
    if (low > 0) parts.add('$low leve${low == 1 ? '' : 's'}');

    final sample = codes.first.description;
    final body =
        '${codes.length} código${codes.length == 1 ? '' : 's'}: ${parts.join(', ')}. '
        'Ej.: ${codes.first.code} — $sample. Revisa cuando puedas con seguridad.';

    final details = _androidDetailsFor(worst);

    try {
      await _plugin.show(
        id: 1001,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(android: details),
      );
    } catch (e) {
      debugPrint('DiagnosisNotificationService: $e');
    }
  }

  AndroidNotificationDetails _androidDetailsFor(String severity) {
    switch (severity) {
      case 'urgent':
        return AndroidNotificationDetails(
          _channelUrgent,
          'Alertas urgentes del vehículo',
          channelDescription:
              'Fallos importantes. Tono corto de atención (no es una emergencia 911).',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('alert_urgent'),
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
        );
      case 'medium':
        return AndroidNotificationDetails(
          _channelMedium,
          'Alertas moderadas del vehículo',
          channelDescription: 'Códigos que conviene revisar. Tono suave.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('alert_medium'),
          enableVibration: true,
        );
      default:
        return const AndroidNotificationDetails(
          _channelLow,
          'Avisos leves del vehículo',
          channelDescription:
              'Informativos. Sin sonido para no distraer al conducir.',
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          enableVibration: false,
          silent: true,
        );
    }
  }

  static String _worstSeverity(List<DtcCode> codes) {
    var best = 'low';
    for (final code in codes) {
      if (_rank(code.severity) > _rank(best)) best = code.severity;
    }
    return best;
  }

  static int _rank(String severity) {
    switch (severity) {
      case 'urgent':
        return 3;
      case 'medium':
        return 2;
      default:
        return 1;
    }
  }

  void resetHistory() {
    _lastNotifiedCodes = {};
  }
}
