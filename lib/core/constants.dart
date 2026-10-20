/// Constantes globales de la aplicación SafeScan.
class AppConstants {
  AppConstants._();

  static const String appName = 'SafeScan';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Diagnóstico vehicular inteligente';

  // Configuración de red y adaptador OBD
  static const String defaultObdIp = '192.168.0.10';
  static const int defaultObdPort = 35000;
  static const Duration obdConnectTimeout = Duration(seconds: 25);
  static const Duration obdPollInterval = Duration(seconds: 5);

  // Asset de base de datos de códigos DTC
  static const String dtcAssetPath = 'assets/obd2_explicaciones.json';

  // Configuración de notificaciones
  static const String notificationChannelUrgent = 'safescan_dtc_urgent_v1';
  static const String notificationChannelMedium = 'safescan_dtc_medium_v1';
  static const String notificationChannelLow = 'safescan_dtc_low_v1';
}
