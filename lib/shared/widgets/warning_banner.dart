import 'package:flutter/material.dart';
import '../../core/theme.dart';

class WarningBanner extends StatelessWidget {
  final String message;
  final String severity;
  final VoidCallback? onTap;

  const WarningBanner({
    super.key,
    required this.message,
    required this.severity,
    this.onTap,
  });

  Color get _color {
    switch (severity) {
      case 'urgent':
        return AppTheme.severityUrgent;
      case 'medium':
        return AppTheme.severityMedium;
      default:
        return AppTheme.severityLow;
    }
  }

  IconData get _icon {
    switch (severity) {
      case 'urgent':
        return Icons.error_outline;
      case 'medium':
        return Icons.warning_amber_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _color.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          children: [
            Icon(_icon, color: _color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios, color: _color, size: 14),
          ],
        ),
      ),
    );
  }
}
