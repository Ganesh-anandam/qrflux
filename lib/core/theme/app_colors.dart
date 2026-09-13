import 'package:flutter/material.dart';

class AppColors {
  // Dark Palette (Primary Experience)
  static const Color darkBackground = Color(0xFF090D16);
  static const Color darkSurface = Color(0xFF111726);
  static const Color darkSurfaceElevated = Color(0xFF1A2238);
  static const Color darkCardBorder = Color(0x1AFFFFFF);
  static const Color darkCardHover = Color(0x0DFFFFFF);

  // Light Palette
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9);
  static const Color lightCardBorder = Color(0x1E000000);

  // Brand Accents
  static const Color primary = Color(0xFF00D2FF);
  static const Color primaryDark = Color(0xFF0096C7);
  static const Color secondary = Color(0xFF6366F1);
  static const Color accentCyan = Color(0xFF38BDF8);
  static const Color accentIndigo = Color(0xFF818CF8);

  // Semantic Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0xFF064E3B);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFF78350F);
  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFF7F1D1D);

  // Text Colors (Dark)
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Text Colors (Light)
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00D2FF), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    colors: [Color(0x2600D2FF), Color(0x00111726)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
