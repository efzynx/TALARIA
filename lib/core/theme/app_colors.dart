import 'package:flutter/material.dart';

/// Design tokens for Talaria-Inverse design system.
/// Cyberpunk cold void aesthetic: abyssal obsidian background with electric cyan accents.
abstract class AppColors {
  // Brand & Accents
  static const Color primary = Color(0xFF00E5FF); // Electric Cyan
  static const Color primaryHover = Color(0xFF38BDF8);
  static const Color primaryActive = Color(0xFF0284C7);
  static const Color secondary = Color(0xFF0077B6);
  static const Color tertiary = Color(0xFF6366F1);

  // Backgrounds & Surfaces (AMOLED Dark)
  static const Color background = Color(0xFF080C14); // Abyssal Night
  static const Color surface = Color(0xFF0F172A); // Slate Void
  static const Color surfaceHover = Color(0xFF1E293B);
  static const Color surfaceActive = Color(0xFF334155);

  // Borders & Dividers
  static const Color border = Color(0xFF1E293B);
  static const Color borderHighlight = Color(0xFF00E5FF);

  // Text Hierarchy
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Semantic Status
  static const Color ok = Color(0xFF10B981);
  static const Color error = Color(0xFFF43F5E);
  static const Color warn = Color(0xFFF59E0B);
  static const Color warning = Color(0xFFF59E0B);
  static const Color thinking = Color(0xFF38BDF8);
}

/// Spacing and Border Radii tokens defined in DESIGN.md
abstract class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  // Radii
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusFull = 9999.0;

  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(radiusFull));
}
