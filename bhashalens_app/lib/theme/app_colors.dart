import 'package:flutter/material.dart';

/// App color palette based on Orange theme with complementary colors
class AppColors {
  // --- PRIMARY THEME COLORS ---
  // Teal/Blue-Green (Primary)
  static const Color primary = primaryTeal;
  static const Color primaryLight = primaryTealLight;
  static const Color primaryDark = primaryTealDark;
  // Orange (Secondary)
  static const Color secondary = secondaryOrange;
  static const Color secondaryLight = secondaryOrangeLight;
  static const Color secondaryDark = secondaryOrangeDark;

  // --- BACKGROUND & SURFACE ---
  static const Color background = Color(0xFFF6F8FA); // App background
  static const Color backgroundDark = Color(0xFF10171A); // Dark mode bg
  static const Color surface = Color(0xFFFFFFFF); // Cards, sheets
  static const Color surfaceDark = Color(0xFF1A2327); // Cards, sheets dark

  // --- TEXT COLORS ---
  static const Color text = Color(0xFF222B45); // Main text
  static const Color textLight = Color(0xFF8F9BB3); // Secondary text
  static const Color textDark = Color(0xFFFFFFFF); // On dark bg
  static const Color textOnPrimary = Color(0xFFFFFFFF); // On teal/orange
  static const Color textOnSecondary = Color(0xFFFFFFFF); // On orange

  // --- BORDER & DIVIDER ---
  static const Color border = Color(0xFFE4E9F2);
  static const Color borderDark = Color(0xFF222B45);
  static const Color divider = Color(0xFFEDF1F7);
  static const Color dividerDark = Color(0xFF222B45);

  // --- ICONS ---
  static const Color icon = primaryTeal;
  static const Color iconInactive = Color(0xFFB3BFD7);
  static const Color iconDark = Color(0xFF8F9BB3);

  // --- STATES ---
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);

  // --- BUTTONS ---
  static const Color button = primaryTeal;
  static const Color buttonText = Color(0xFFFFFFFF);
  static const Color buttonSecondary = secondaryOrange;
  static const Color buttonSecondaryText = Color(0xFFFFFFFF);
  static const Color buttonDisabled = Color(0xFFB3BFD7);
  static const Color buttonDisabledText = Color(0xFFFFFFFF);

  // --- INPUTS ---
  static const Color inputFill = Color(0xFFF7F9FC);
  static const Color inputFillDark = Color(0xFF222B45);
  static const Color inputBorder = border;
  static const Color inputBorderDark = borderDark;
  static const Color inputText = text;
  static const Color inputTextDark = textDark;
  static const Color inputLabel = textLight;
  static const Color inputLabelDark = textDark;

  // --- SHADOWS ---
  static const Color shadow = Color(0x1A000000); // 10% black

  // --- GRADIENTS ---
  static const List<Color> mainGradient = [primaryTeal, secondaryOrange];
  static const List<Color> accentGradient = [
    primaryTealLight,
    secondaryOrangeLight,
  ];

  // --- MISC ---
  static const Color overlay = Color(0x80000000); // 50% black
  static const Color highlight = Color(0xFFB2F5EA); // Light teal highlight
  // Teal/Blue-Green and Orange for new theme
  static const Color primaryTeal = Color(0xFF1193d4); // Teal/Blue-Green
  static const Color primaryTealLight = Color(0xFF4DD0E1); // Light Teal
  static const Color primaryTealDark = Color(0xFF006978); // Dark Teal
  static const Color secondaryOrange = Color(0xFFFF6B35); // Vibrant Orange
  static const Color secondaryOrangeLight = Color(0xFFFF8A65); // Light Orange
  static const Color secondaryOrangeDark = Color(0xFFE64A19); // Dark Orange
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

  static const Color error = Color(0xFFE53935);

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
  // --- MOCKUP DARK THEME COLORS ---
  static const Color darkBackground = Color(0xFF101C25); // Deep Blue/Charcoal
  static const Color darkCard = Color(0xFF1A2630); // Slightly lighter
  static const Color darkAccent = Color(0xFF2196F3); // Clear Blue
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkSubText = Color(0xFF8F9BB3);
  
  static const Color orangeAccent = Color(0xFFE65100); // Warm orange for icon
  static const Color purpleAccent = Color(0xFFAB47BC); // Purple for explain icon
  static const Color greenAccent = Color(0xFF43A047); // Green for assistant icon

  static const Color sosRed = Color(0xFFCF6679); // Muted red for SOS
}
