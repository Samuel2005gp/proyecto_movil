import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SnackBarHelper {
  // Éxito — azul oscuro elegante
  static void showSuccess(BuildContext context, String message) {
    _show(context, message,
        backgroundColor: const Color(0xFF1E40AF), // azul oscuro
        icon: Icons.check_circle_outline);
  }

  // Error — rojo
  static void showError(BuildContext context, String message) {
    _show(context, message,
        backgroundColor: AppTheme.destructive, icon: Icons.error_outline);
  }

  // Advertencia — ámbar
  static void showWarning(BuildContext context, String message) {
    _show(context, message,
        backgroundColor: const Color(0xFFB45309), // ámbar oscuro
        icon: Icons.warning_amber_outlined);
  }

  // Info — gris oscuro
  static void showInfo(BuildContext context, String message) {
    _show(context, message,
        backgroundColor: const Color(0xFF374151), // gris oscuro
        icon: Icons.info_outline);
  }

  static void _show(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: duration,
        elevation: 6,
      ),
    );
  }
}
