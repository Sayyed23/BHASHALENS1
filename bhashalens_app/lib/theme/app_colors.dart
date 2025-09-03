import 'package:flutter/material.dart';

/// App color palette based on Orange theme with complementary colors
class AppColors {
  // Primary Orange Colors
  static const Color primaryOrange = Color(0xFFFF6B35); // Vibrant Orange
  static const Color primaryOrangeLight = Color(0xFFFF8A65); // Light Orange
  static const Color primaryOrangeDark = Color(0xFFE64A19); // Dark Orange

  // Secondary Colors
  static const Color secondaryBlue = Color(0xFF1976D2); // Complementary Blue
  static const Color secondaryBlueLight = Color(0xFF42A5F5); // Light Blue
  static const Color secondaryBlueDark = Color(0xFF0D47A1); // Dark Blue

  // Accent Colors
  static const Color accentGreen = Color(0xFF4CAF50); // Success Green
  static const Color accentRed = Color(0xFFE53935); // Error Red
  static const Color accentYellow = Color(0xFFFFC107); // Warning Yellow
  static const Color accentPurple = Color(0xFF9C27B0); // Purple accent

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Background Colors
  static const Color backgroundLight = Color(
    0xFFFFF8F5,
  ); // Very light orange tint
  static const Color backgroundDark = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFFFFF3E0); // Light orange surface
  static const Color surfaceDark = Color(0xFF2D2D2D);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFFFF6B35),
    Color(0xFFFF8A65),
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFF1976D2),
    Color(0xFF42A5F5),
  ];

  static const List<Color> warmGradient = [
    Color(0xFFFF6B35),
    Color(0xFFFFC107),
    Color(0xFFFF8A65),
  ];
}
