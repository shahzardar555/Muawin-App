import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium Muawin PRO badge widget
/// Displays a beautiful gradient badge with crown icon and "Muawin PRO" text
enum MuawinProBadgeSize {
  small,
  medium,
  large,
}

class MuawinProBadge extends StatelessWidget {
  final MuawinProBadgeSize size;

  const MuawinProBadge({
    super.key,
    this.size = MuawinProBadgeSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final dimensions = _getDimensions();
    final iconSize = _getIconSize();
    final fontSize = _getFontSize();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dimensions.paddingHorizontal,
        vertical: dimensions.paddingVertical,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD700), // Gold
            Color(0xFF047A62), // Brand Teal
          ],
        ),
        borderRadius: BorderRadius.circular(dimensions.borderRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            color: Colors.white,
            size: iconSize,
          ),
          const SizedBox(width: 6),
          Text(
            'Muawin PRO',
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeDimensions _getDimensions() {
    switch (size) {
      case MuawinProBadgeSize.small:
        return const _BadgeDimensions(
          paddingHorizontal: 8,
          paddingVertical: 4,
          borderRadius: 12,
        );
      case MuawinProBadgeSize.medium:
        return const _BadgeDimensions(
          paddingHorizontal: 12,
          paddingVertical: 6,
          borderRadius: 20,
        );
      case MuawinProBadgeSize.large:
        return const _BadgeDimensions(
          paddingHorizontal: 16,
          paddingVertical: 8,
          borderRadius: 24,
        );
    }
  }

  double _getIconSize() {
    switch (size) {
      case MuawinProBadgeSize.small:
        return 14;
      case MuawinProBadgeSize.medium:
        return 18;
      case MuawinProBadgeSize.large:
        return 22;
    }
  }

  double _getFontSize() {
    switch (size) {
      case MuawinProBadgeSize.small:
        return 10;
      case MuawinProBadgeSize.medium:
        return 12;
      case MuawinProBadgeSize.large:
        return 14;
    }
  }
}

class _BadgeDimensions {
  final double paddingHorizontal;
  final double paddingVertical;
  final double borderRadius;

  const _BadgeDimensions({
    required this.paddingHorizontal,
    required this.paddingVertical,
    required this.borderRadius,
  });
}
