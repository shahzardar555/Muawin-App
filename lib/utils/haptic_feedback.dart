import 'package:flutter/foundation.dart';

/// Utility class for safe haptic feedback with error handling
class HapticFeedback {
  /// Light haptic feedback
  static Future<void> lightImpact() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('❌ Haptic feedback error (light): $e');
    }
  }

  /// Medium haptic feedback
  static Future<void> mediumImpact() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('❌ Haptic feedback error (medium): $e');
    }
  }

  /// Heavy haptic feedback
  static Future<void> heavyImpact() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('❌ Haptic feedback error (heavy): $e');
    }
  }

  /// Selection haptic feedback
  static Future<void> selectionClick() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('❌ Haptic feedback error (selection): $e');
    }
  }

  /// Success haptic feedback
  static Future<void> success() async {
    try {
      await HapticFeedback.lightImpact(); // Light impact for success
    } catch (e) {
      debugPrint('❌ Haptic feedback error (success): $e');
    }
  }

  /// Error haptic feedback
  static Future<void> error() async {
    try {
      await HapticFeedback.heavyImpact(); // Heavy impact for errors
    } catch (e) {
      debugPrint('❌ Haptic feedback error (error): $e');
    }
  }
}
