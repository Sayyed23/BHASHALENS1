import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  /// Light theme configuration
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.sourceSans3TextTheme().copyWith(
      displayLarge: GoogleFonts.lexend(
        fontWeight: FontWeight.bold,
        color: AppColors.slate900,
      ),
      displayMedium: GoogleFonts.lexend(
        fontWeight: FontWeight.bold,
        color: AppColors.slate900,
      ),
      displaySmall: GoogleFonts.lexend(
        fontWeight: FontWeight.bold,
        color: AppColors.slate900,
      ),
      headlineLarge: GoogleFonts.lexend(
        fontWeight: FontWeight.w600,
        color: AppColors.slate900,
      ),
      headlineMedium: GoogleFonts.lexend(
        fontWeight: FontWeight.w600,
        color: AppColors.slate900,
      ),
      headlineSmall: GoogleFonts.lexend(
        fontWeight: FontWeight.w600,
        color: AppColors.slate900,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: textTheme,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        primaryContainer: AppColors.blue100,
        onPrimaryContainer: AppColors.blue700,
        secondary: AppColors.slate600,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.slate100,
        onSecondaryContainer: AppColors.slate900,
        surface: AppColors.surface,
        onSurface: AppColors.slate900,
        surfaceContainerHighest: AppColors.slate100,
        onSurfaceVariant: AppColors.slate500,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.border,
        outlineVariant: AppColors.slate200,
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.slate900,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.lexend(
          color: AppColors.slate900,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle:
              GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.slate50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.sourceSans3TextTheme()
        .apply(
          bodyColor: AppColors.textDark,
          displayColor: AppColors.textDark,
        )
        .copyWith(
          displayLarge: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
          displayMedium: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
          displaySmall: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
          headlineLarge: GoogleFonts.lexend(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
          headlineMedium: GoogleFonts.lexend(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
          headlineSmall: GoogleFonts.lexend(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: textTheme,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        primaryContainer: Color(0xFF1E3A8A), // Dark blue
        onPrimaryContainer: Colors.white,

        secondary: AppColors.slate400,
        onSecondary: AppColors.slate950,
        secondaryContainer: AppColors.slate800,
        onSecondaryContainer: Colors.white,

        surface: AppColors.surfaceDark,
        onSurface: AppColors.textDark,
        surfaceContainerHighest: AppColors.backgroundDark,
        onSurfaceVariant: AppColors.slate400,

        error: AppColors.error,
        onError: Colors.white,

        outline: AppColors.borderDark,
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.lexend(
          color: AppColors.textDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle:
              GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.slate900,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  const CustomColors({
    required this.success,
    required this.warning,
    required this.info,
  });

  final Color success;
  final Color warning;
  final Color info;

  @override
  CustomColors copyWith({Color? success, Color? warning, Color? info}) {
    return CustomColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }

  // Helper getter to use these colors with Theme.of(context).colorScheme.custom.success
  static CustomColors of(BuildContext context) =>
      Theme.of(context).extension<CustomColors>()!;
}
