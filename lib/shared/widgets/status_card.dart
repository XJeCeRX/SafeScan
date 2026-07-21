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
    final hasScanned = obdManager?.hasScannedDtc ?? false;
    final dtcCount = obdManager?.dtcCodes.length ?? 0;

    String subtitle;
    if (!isConnected) {
      subtitle = 'Conecta tu adaptador WiFi';
    } else if (!hasScanned) {
      subtitle = 'Conectado — escanea para verificar alertas';
    } else if (dtcCount == 0) {
      subtitle = 'Sin alertas detectadas';
    } else {
      subtitle =
          '$dtcCount alerta${dtcCount == 1 ? '' : 's'} detectada${dtcCount == 1 ? '' : 's'}';
    }

    final statusColor = isConnected
        ? (hasScanned && dtcCount == 0
              ? AppTheme.severityLow
              : AppTheme.primary)
        : AppTheme.textHint;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected
              ? statusColor.withValues(alpha: 0.3)
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
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: isConnected
                  ? [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.4),
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
                  subtitle,
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
            Icon(
              hasScanned && dtcCount == 0
                  ? Icons.verified_outlined
                  : Icons.check_circle_outline,
              color: statusColor,
              size: 20,
            ),
        ],
      ),
    );
  }
}
