import 'package:flutter/services.dart';

/// Haptic feedback utility for touch interactions.
abstract class AppHaptics {
  /// Subtle feedback for button taps and toggle switches
  static void light() {
    HapticFeedback.lightImpact();
  }

  /// Medium feedback for message submissions
  static void medium() {
    HapticFeedback.mediumImpact();
  }

  /// Strong warning feedback for approval prompts and dangerous actions
  static void warning() {
    HapticFeedback.heavyImpact();
  }

  /// Success feedback for completed actions
  static void success() {
    HapticFeedback.selectionClick();
  }
}
