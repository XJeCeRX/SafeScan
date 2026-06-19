import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/chat_config.dart';
import '../models/sensor_payload.dart';

enum ChatConnectionState { disconnected, connecting, connected, error }

typedef ChatEventHandler = void Function(Map<String, dynamic> event);

/// Cliente WebSocket para comunicación en tiempo real con el chatbot del backend.
class ChatService {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  bool _intentionalDisconnect = false;

  ChatConnectionState _state = ChatConnectionState.disconnected;
  String? _sessionId;
  String? _lastError;

  ChatConnectionState get state => _state;
  String? get sessionId => _sessionId;
  String? get lastError => _lastError;
  bool get isConnected => _state == ChatConnectionState.connected;

  final StreamController<Map<String, dynamic>> _eventsController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _eventsController.stream;

  Future<void> connect() async {
    if (_state == ChatConnectionState.connecting ||
        _state == ChatConnectionState.connected) {
      return;
    }

    _intentionalDisconnect = false;
    _reconnectTimer?.cancel();
    _setState(ChatConnectionState.connecting);

    try {
      final channel = WebSocketChannel.connect(Uri.parse(ChatConfig.wsUrl));
      _channel = channel;

      await channel.ready.timeout(ChatConfig.connectTimeout);

      _subscription = channel.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      _setState(ChatConnectionState.connected);
    } catch (e) {
      _lastError = e.toString();
      _setState(ChatConnectionState.error);
      _scheduleReconnect();
    }
  }

  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _sessionId = null;
    _setState(ChatConnectionState.disconnected);
  }

  void sendUserMessage({
    required String messageId,
    required String text,
    SensorPayload? sensorData,
  }) {
    if (!isConnected || _channel == null) {
      throw StateError('No hay conexión con el servidor de chat.');
    }

    final payload = <String, dynamic>{
      'type': 'user_message',
      'id': messageId,
      'text': text.trim(),
      if (sensorData != null) 'sensor_data': sensorData.toJson(),
    };

    _channel!.sink.add(jsonEncode(payload));
  }

  void _onData(dynamic data) {
    try {
      final decoded = jsonDecode(data as String) as Map<String, dynamic>;
      final type = decoded['type'] as String?;

      if (type == 'connected') {
        _sessionId = decoded['session_id'] as String?;
      }

      _eventsController.add(decoded);
    } catch (e) {
      _eventsController.add({
        'type': 'error',
        'message': 'Respuesta inválida del servidor: $e',
      });
    }
  }

  void _onError(Object error) {
    _lastError = error.toString();
    _setState(ChatConnectionState.error);
    _eventsController.add({
      'type': 'error',
      'message': 'Error de conexión: $error',
    });
    _scheduleReconnect();
  }

  void _onDone() {
    if (_intentionalDisconnect) return;
    _setState(ChatConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_intentionalDisconnect || _reconnectTimer?.isActive == true) return;

    _reconnectTimer = Timer(ChatConfig.reconnectDelay, () {
      if (!_intentionalDisconnect) {
        unawaited(connect());
      }
    });
  }

  void _setState(ChatConnectionState newState) {
    _state = newState;
  }

  Future<void> dispose() async {
    await disconnect();
    await _eventsController.close();
  }
}
