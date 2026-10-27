import 'package:flutter/material.dart';

/// App color palette adhering strictly to the design system.
class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFFC8102E); // Deep crimson red
  static const Color primaryDark = Color(0xFFA00D24);
  static const Color primaryLight = Color(0xFFE8354F);

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFF8F7FF); // Very light lavender-white
  static const Color surface = Color(0xFFFFFFFF); // Pure white
  static const Color surfaceSecondary = Color(0xFFF0EFFC); // Pale lavender button / tile bg
  static const Color divider = Color(0xFFE6E5F5); // Subtle separator
  static const Color cardShadow = Color(0x0C1B1F3B); // Subtle card elevation

  // Text Colors
  static const Color textPrimary = Color(0xFF1B1F3B); // Dark navy for titles
  static const Color textSecondary = Color(0xFF6B7194); // Muted blue-gray for subtitles/hints
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White on crimson

  // Status: Teal (Members / Active)
  static const Color statusTealBg = Color(0xFFCCF5EF);
  static const Color statusTealFg = Color(0xFF0F766E);

  // Status: Blue (Info / Check-ins)
  static const Color statusBlueBg = Color(0xFFDCEBFF);
  static const Color statusBlueFg = Color(0xFF1D4ED8);

  // Status: Amber (Expiring soon / Pending / Warning)
  static const Color statusAmberBg = Color(0xFFFFF1CC);
  static const Color statusAmberFg = Color(0xFFB45309);

  // Status: Green (Paid / Success / Check-in OK)
  static const Color statusGreenBg = Color(0xFFD9F7E4);
  static const Color statusGreenFg = Color(0xFF15803D);

  // Status: Red (Expired / Overdue / Error / Unpaid)
  static const Color statusRedBg = Color(0xFFFFE0E3);
  static const Color statusRedFg = Color(0xFFC8102E);
}
