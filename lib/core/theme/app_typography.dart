import 'package:flutter/material.dart';

class AppTypography {
  static const String fontFamily = 'Roboto';

  static TextStyle displayLarge(bool isDark) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
  );

  static TextStyle displayMedium(bool isDark) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
  );

  static TextStyle titleLarge(bool isDark) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
  );

  static TextStyle titleMedium(bool isDark) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
  );

  static TextStyle bodyLarge(bool isDark) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
  );

  static TextStyle bodyMedium(bool isDark) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
  );

  static TextStyle bodySmall(bool isDark) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
  );

  static TextStyle codeFont(bool isDark) => TextStyle(
    fontFamily: 'Courier',
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: 6.0,
    color: isDark ? const Color(0xFF00D2FF) : const Color(0xFF0284C7),
  );
}
