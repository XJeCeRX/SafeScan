import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/sensor_payload.dart';
import 'chat_service.dart';
import 'obd_manager.dart';

/// Orquestador del módulo de chat: mensajes, sensores y conexión en tiempo real.
class ChatManager extends ChangeNotifier {
  ChatManager({
    required this._obdManager,
    ChatService? chatService,
  }) : _chatService = chatService ?? ChatService() {
    _eventSubscription = _chatService.events.listen(_handleServerEvent);
  }

  final ObdManager _obdManager;
  final ChatService _chatService;
  final _uuid = const Uuid();

  final List<ChatMessage> _messages = [];
  bool _includeSensorData = true;
  bool _isSending = false;
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;

  String? _activeAssistantMessageId;
  String? _pendingUserMessageId;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get includeSensorData => _includeSensorData;
  bool get isSending => _isSending;
  ChatConnectionState get connectionState => _chatService.state;
  String? get sessionId => _chatService.sessionId;
  String? get connectionError => _chatService.lastError;
  bool get canAttachSensors => _obdManager.isConnected;

  Future<void> connect() => _chatService.connect();

  Future<void> disconnect() => _chatService.disconnect();

  void setIncludeSensorData(bool value) {
    if (_includeSensorData == value) return;
    _includeSensorData = value;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;

    if (!_chatService.isConnected) {
      await connect();
      if (!_chatService.isConnected) {
        _appendSystemMessage(
          'No se pudo conectar al asistente. Verifica que el backend esté activo.',
        );
        return;
      }
    }

    final userMessageId = _uuid.v4();
    final attachSensors = _includeSensorData && _obdManager.isConnected;
    SensorPayload? sensorPayload;

    if (attachSensors) {
      sensorPayload = SensorPayload.fromObdManager(_obdManager);
    }

    final userMessage = ChatMessage(
      id: userMessageId,
      role: ChatRole.user,
      content: trimmed,
      createdAt: DateTime.now(),
      status: ChatMessageStatus.sending,
      includesSensorData: attachSensors,
    );

    _messages.add(userMessage);
    _isSending = true;
    _pendingUserMessageId = userMessageId;
    notifyListeners();

    try {
      _chatService.sendUserMessage(
        messageId: userMessageId,
        text: trimmed,
        sensorData: sensorPayload,
      );
      _updateMessage(
        userMessageId,
        (m) => m.copyWith(status: ChatMessageStatus.sent),
      );
    } catch (e) {
      _updateMessage(
        userMessageId,
        (m) => m.copyWith(
          status: ChatMessageStatus.error,
          errorMessage: e.toString(),
        ),
      );
      _isSending = false;
      _pendingUserMessageId = null;
      notifyListeners();
    }
  }

  void _handleServerEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;

    switch (type) {
      case 'connected':
        notifyListeners();
        break;
      case 'assistant_start':
        _beginAssistantMessage(event);
        break;
      case 'assistant_chunk':
        _appendAssistantChunk(event);
        break;
      case 'assistant_done':
        _finishAssistantMessage(event);
        break;
      case 'error':
        _handleError(event['message'] as String? ?? 'Error desconocido');
        break;
    }
  }

  void _beginAssistantMessage(Map<String, dynamic> event) {
    final id = event['id'] as String? ?? _uuid.v4();
    _activeAssistantMessageId = id;

    _messages.add(
      ChatMessage(
        id: id,
        role: ChatRole.assistant,
        content: '',
        createdAt: DateTime.now(),
        status: ChatMessageStatus.streaming,
      ),
    );
    notifyListeners();
  }

  void _appendAssistantChunk(Map<String, dynamic> event) {
    final id = _activeAssistantMessageId;
    final chunk = event['content'] as String? ?? '';
    if (id == null || chunk.isEmpty) return;

    _updateMessage(id, (message) {
      return message.copyWith(
        content: message.content + chunk,
        status: ChatMessageStatus.streaming,
      );
    });
  }

  void _finishAssistantMessage(Map<String, dynamic> event) {
    final id = _activeAssistantMessageId;
    final fullContent = event['content'] as String?;

    if (id != null) {
      _updateMessage(id, (message) {
        return message.copyWith(
          content: fullContent ?? message.content,
          status: ChatMessageStatus.sent,
        );
      });
    }

    _activeAssistantMessageId = null;
    _pendingUserMessageId = null;
    _isSending = false;
    notifyListeners();
  }

  void _handleError(String message) {
    if (_pendingUserMessageId != null) {
      _updateMessage(
        _pendingUserMessageId!,
        (m) => m.copyWith(
          status: ChatMessageStatus.error,
          errorMessage: message,
        ),
      );
    } else if (_activeAssistantMessageId != null) {
      _updateMessage(
        _activeAssistantMessageId!,
        (m) => m.copyWith(
          status: ChatMessageStatus.error,
          errorMessage: message,
        ),
      );
    } else {
      _appendSystemMessage(message);
    }

    _activeAssistantMessageId = null;
    _pendingUserMessageId = null;
    _isSending = false;
    notifyListeners();
  }

  void _appendSystemMessage(String content) {
    _messages.add(
      ChatMessage(
        id: _uuid.v4(),
        role: ChatRole.system,
        content: content,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void _updateMessage(
    String id,
    ChatMessage Function(ChatMessage message) transform,
  ) {
    final index = _messages.indexWhere((m) => m.id == id);
    if (index == -1) return;
    _messages[index] = transform(_messages[index]);
    notifyListeners();
  }

  void clearHistory() {
    _messages.clear();
    _activeAssistantMessageId = null;
    _pendingUserMessageId = null;
    _isSending = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _chatService.dispose();
    super.dispose();
  }
}
