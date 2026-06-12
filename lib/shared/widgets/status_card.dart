import 'package:flutter/material.dart';
import '../../core/theme.dart';

class StatusCard extends StatelessWidget {
  final bool isConnected;
  final VoidCallback? onConnectTap;

  const StatusCard({super.key, required this.isConnected, this.onConnectTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected
              ? AppTheme.primary.withOpacity(0.3)
              : AppTheme.textHint.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Indicador animado
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isConnected ? AppTheme.primary : AppTheme.textHint,
              shape: BoxShape.circle,
              boxShadow: isConnected
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Texto
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
                      : 'Conecta tu adaptador Bluetooth',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),

          // Botón acción
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

