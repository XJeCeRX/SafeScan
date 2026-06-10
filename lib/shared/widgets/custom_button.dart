import 'package:flutter/material.dart';
import '../../core/theme.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isOutlined;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isOutlined = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primary,
                ),
              )
            : Icon(icon ?? Icons.arrow_forward),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textPrimary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppTheme.textHint),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon ?? Icons.arrow_forward),
      label: Text(label),
    );
  }
}
