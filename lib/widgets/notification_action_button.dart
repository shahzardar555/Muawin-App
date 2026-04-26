import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/haptic_feedback.dart';

/// Reusable action button widget for notification tiles
class NotificationActionButton extends StatelessWidget {
  const NotificationActionButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon!,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
            ],
            if (isLoading)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
