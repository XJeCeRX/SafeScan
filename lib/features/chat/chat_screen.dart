import 'package:flutter/material.dart';

import '../../core/services/chat_manager.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/obd_manager.dart';
import '../../core/theme.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input_bar.dart';

class ChatScreen extends StatefulWidget {
  final ChatManager chatManager;
  final ObdManager obdManager;

  const ChatScreen({
    super.key,
    required this.chatManager,
    required this.obdManager,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  ChatManager get _chat => widget.chatManager;

  @override
  void initState() {
    super.initState();
    _chat.addListener(_onChatChanged);
    widget.obdManager.addListener(_onObdChanged);
    _chat.connect();
  }

  @override
  void dispose() {
    _chat.removeListener(_onChatChanged);
    widget.obdManager.removeListener(_onObdChanged);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChatChanged() {
    if (!mounted) return;
    setState(() {});
    _scrollToBottom();
  }

  void _onObdChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    await _chat.sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = _chat.connectionState;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Asistente SafeScan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 17,
              ),
            ),
            Text(
              _connectionLabel(connectionState),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                color: _connectionColor(connectionState),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Limpiar conversación',
            onPressed: _chat.messages.isEmpty ? null : _chat.clearHistory,
            icon: const Icon(Icons.delete_outline, color: AppTheme.textSecondary),
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.obdManager.isConnected)
            _VehicleContextBanner(obdManager: widget.obdManager),
          Expanded(
            child: _chat.messages.isEmpty
                ? _EmptyChatState(
                    obdConnected: widget.obdManager.isConnected,
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _chat.messages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ChatBubble(message: _chat.messages[index]),
                      );
                    },
                  ),
          ),
          ChatInputBar(
            controller: _textController,
            onSend: _sendMessage,
            isSending: _chat.isSending,
            includeSensorData: _chat.includeSensorData,
            canAttachSensors: _chat.canAttachSensors,
            onIncludeSensorDataChanged: _chat.setIncludeSensorData,
          ),
        ],
      ),
    );
  }

  String _connectionLabel(ChatConnectionState state) {
    return switch (state) {
      ChatConnectionState.connected => 'Conectado en tiempo real',
      ChatConnectionState.connecting => 'Conectando...',
      ChatConnectionState.error => 'Sin conexión con el backend',
      ChatConnectionState.disconnected => 'Desconectado',
    };
  }

  Color _connectionColor(ChatConnectionState state) {
    return switch (state) {
      ChatConnectionState.connected => AppTheme.primary,
      ChatConnectionState.connecting => AppTheme.severityMedium,
      ChatConnectionState.error => AppTheme.severityUrgent,
      ChatConnectionState.disconnected => AppTheme.textHint,
    };
  }
}

class _VehicleContextBanner extends StatelessWidget {
  final ObdManager obdManager;

  const _VehicleContextBanner({required this.obdManager});

  @override
  Widget build(BuildContext context) {
    final data = obdManager.vehicleData;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.speed, color: AppTheme.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sensores activos: ${data.rpm} RPM · ${data.coolantTemp}°C · ${data.speed} km/h',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  final bool obdConnected;

  const _EmptyChatState({required this.obdConnected});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: AppTheme.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Consulta al asistente',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              obdConnected
                  ? 'Puedes preguntar sobre códigos de falla y el asistente recibirá las lecturas OBD en tiempo real.'
                  : 'Escribe tu consulta. Conecta el adaptador OBD para enviar también datos de sensores.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
