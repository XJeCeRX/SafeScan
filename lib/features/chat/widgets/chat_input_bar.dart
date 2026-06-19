import 'package:flutter/material.dart';

import '../../../core/theme.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;
  final bool includeSensorData;
  final bool canAttachSensors;
  final ValueChanged<bool> onIncludeSensorDataChanged;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.isSending,
    required this.includeSensorData,
    required this.canAttachSensors,
    required this.onIncludeSensorDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.surfaceLight, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.sensors,
                size: 18,
                color: canAttachSensors ? AppTheme.primary : AppTheme.textHint,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  canAttachSensors
                      ? 'Incluir lecturas OBD en el mensaje'
                      : 'Conecta el adaptador OBD para enviar datos de sensores',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: canAttachSensors
                        ? AppTheme.textSecondary
                        : AppTheme.textHint,
                  ),
                ),
              ),
              Switch.adaptive(
                value: includeSensorData && canAttachSensors,
                onChanged: canAttachSensors
                    ? onIncludeSensorDataChanged
                    : null,
                activeTrackColor: AppTheme.primary.withValues(alpha: 0.45),
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppTheme.primary;
                  }
                  return AppTheme.textHint;
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !isSending,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Escribe tu consulta...',
                    hintStyle: Theme.of(context).textTheme.bodyMedium,
                    filled: true,
                    fillColor: AppTheme.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: isSending ? null : onSend,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: isSending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
