import 'package:flutter/material.dart';

/// Design tokens from docs/DESIGN_SYSTEM.md
abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF1A1A2E);
  static const accent = Color(0xFFE8C547);
  static const accentSoft = Color(0x26E8C547); // 15%

  // Neutrals
  static const neutral50 = Color(0xFFFAFAFA);
  static const neutral100 = Color(0xFFF5F5F5);
  static const neutral200 = Color(0xFFE5E5E5);
  static const neutral300 = Color(0xFFD4D4D4);
  static const neutral400 = Color(0xFFA3A3A3);
  static const neutral600 = Color(0xFF525252);
  static const neutral900 = Color(0xFF171717);

  // Semantic
  static const success = Color(0xFF22C55E);
  static const successSoft = Color(0x2622C55E); // 15%
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0x26F59E0B);
  static const error = Color(0xFFEF4444);
  static const errorSoft = Color(0x26EF4444);
  static const info = Color(0xFF3B82F6);
  static const infoSoft = Color(0x263B82F6);
}
