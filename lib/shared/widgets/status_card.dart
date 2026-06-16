import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/services/obd_manager.dart';

class StatusCard extends StatelessWidget {
  final ObdManager? obdManager;
  final VoidCallback? onConnectTap;

  const StatusCard({super.key, this.obdManager, this.onConnectTap});

  @override
  Widget build(BuildContext context) {
    final isConnected = obdManager?.isConnected ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected
              ? AppTheme.primary.withValues(alpha: 0.3)
              : AppTheme.textHint.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isConnected ? AppTheme.primary : AppTheme.textHint,
              shape: BoxShape.circle,
              boxShadow: isConnected
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? 'OBD Conectado' : 'Sin conexión OBD',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isConnected
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                ),
                Text(
                  isConnected
                      ? 'Leyendo datos del vehículo'
                      : 'Conecta tu adaptador WiFi',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          if (!isConnected && onConnectTap != null)
            TextButton(
              onPressed: onConnectTap,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
              child: const Text('Conectar'),
            ),
          if (isConnected)
            Icon(Icons.check_circle_outline, color: AppTheme.primary, size: 20),
        ],
      ),
    );
  }
}
