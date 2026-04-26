import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom filter chip widget with consistent styling
class CustomFilterChip extends StatelessWidget {
  const CustomFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.backgroundColor,
    this.selectedColor,
    this.checkmarkColor,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? checkmarkColor;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: selected ? (checkmarkColor ?? const Color(0xFF047A62)) : Colors.black87,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: backgroundColor ?? Colors.grey[200],
      selectedColor: selectedColor ?? const Color(0xFF047A62).withValues(alpha: 0.2),
      checkmarkColor: checkmarkColor ?? const Color(0xFF047A62),
      side: BorderSide(
        color: selected ? (checkmarkColor ?? const Color(0xFF047A62)) : Colors.grey[300]!,
        width: selected ? 2 : 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
