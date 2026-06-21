import 'package:flutter/material.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/theme.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.role == ChatRole.system) {
      return _SystemBubble(content: message.content);
    }

    final isUser = message.isUser;
    final backgroundColor = isUser ? AppTheme.primary : AppTheme.surface;
    final textColor = isUser ? Colors.white : AppTheme.textPrimary;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isUser ? 16 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 16),
    );

    final bubble = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.75,
      ),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (isUser && message.includesSensorData)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _SensorBadge(),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: borderRadius,
              border: isUser
                  ? null
                  : Border.all(color: AppTheme.surfaceLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.isStreaming && message.content.isEmpty)
                  const _TypingIndicator()
                else
                  SelectableText(
                    message.content.isEmpty && message.isStreaming
                        ? '...'
                        : message.content,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: textColor,
                      height: 1.4,
                    ),
                  ),
                if (message.hasError) ...[
                  const SizedBox(height: 6),
                  Text(
                    message.errorMessage ?? 'No se pudo enviar el mensaje.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.severityUrgent,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    final icon = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isUser
            ? AppTheme.primary.withValues(alpha: 0.15)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isUser
            ? null
            : Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Icon(
        isUser ? Icons.person_rounded : Icons.smart_toy_outlined,
        size: 18,
        color: isUser
            ? AppTheme.primary
            : AppTheme.primary.withValues(alpha: 0.8),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[icon, const SizedBox(width: 8)],
          Flexible(child: bubble),
          if (isUser) ...[const SizedBox(width: 8), icon],
        ],
      ),
    );
  }
}

class _SensorBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sensors,
            size: 14,
            color: AppTheme.primary.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 6),
          Text(
            'Datos OBD adjuntos',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.primary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemBubble extends StatelessWidget {
  final String content;

  const _SystemBubble({required this.content});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          content,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          width: 7,
          height: 7,
          margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
          decoration: BoxDecoration(
            color: AppTheme.textSecondary.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
