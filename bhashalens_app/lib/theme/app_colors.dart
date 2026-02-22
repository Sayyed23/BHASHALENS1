import 'package:flutter/material.dart';

/// App color palette based on Orange theme with complementary colors
class AppColors {
  // --- PRIMARY THEME COLORS ---
  // High-Contrast Slate (Backgrounds & Text)
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF020617);

  // Deep Blue (Primary Brand Color)
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue700 = Color(0xFF1D4ED8);

  // Standardized Semantic Names
  static const Color primary = blue600;
  static const Color primaryLight = blue500;
  static const Color primaryDark = blue700;

  static const Color secondary = slate600;
  static const Color secondaryLight = slate400;
  static const Color secondaryDark = slate800;

  static const Color background = slate50;
  static const Color backgroundDark = slate950;
  static const Color surface = Colors.white;
  static const Color surfaceDark = slate900;

  static const Color text = slate900;
  static const Color textLight = slate500;
  static const Color textMuted = slate500;
  static const Color textOnPrimary = Colors.white;
  static const Color textOnSecondary = Colors.white;
  static const Color textDark = Colors.white;

  static const Color border = slate200;
  static const Color borderDark = slate800;
  static const Color divider = slate200;
  static const Color dividerDark = slate800;

  // States
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  static const Color sosRed = Color(0xFFEF4444);

  // Layout Helpers
  static const Color shadow = Color(0x1A000000); // 10% black
  static const Color overlay = Color(0x80000000); // 50% black

  // Gradients for glassmorphism and accents
  static const List<Color> blueGradient = [blue700, blue500];
  static const List<Color> darkGradient = [slate900, slate800];
}
