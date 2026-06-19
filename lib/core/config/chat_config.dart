/// Configuración del servicio de chat con el backend.
///
/// URL por defecto para emulador Android (`10.0.2.2` = localhost del host).
/// Sobrescribir en compilación:
/// `flutter run --dart-define=CHAT_WS_URL=ws://192.168.1.10:8000/ws/chat`
class ChatConfig {
  ChatConfig._();

  static const String _defaultWsUrl = 'ws://10.0.2.2:8000/ws/chat';

  static const String wsUrl = String.fromEnvironment(
    'CHAT_WS_URL',
    defaultValue: _defaultWsUrl,
  );

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration reconnectDelay = Duration(seconds: 3);
}
