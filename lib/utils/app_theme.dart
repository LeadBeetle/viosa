import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors (DMC Logo Inspiration)
  static const Color _brandPurple = Color(0xFF7C3AED); // Violet 600
  static const Color _brandPurpleDark = Color(0xFF8B5CF6); // Violet 500
  static const Color _brandOrange = Color(0xFFEA580C); // Orange 600
  static const Color _brandOrangeDark = Color(0xFFF97316); // Orange 500

  static const Color _lightSurface = Colors.white;
  static const Color _lightBackground = Color(0xFFF9FAFB); // Gray 50

  // Deep Dark Background for "Space" look
  static const Color _darkBackground = Color(0xFF0A0A0A); 
  static const Color _darkSurface = Color(0xFF171717); // Neutral 900
  static const Color _darkSurfaceVariant = Color(0xFF262626); // Neutral 800

  // Semantic Colors
  static const Color snackbarSuccessLight = Color(0xFF2D5F3F);
  static const Color snackbarErrorLight = Color(0xFF7D2E2E);
  static const Color snackbarNeutralLight = Color(0xFF3D3D3D);

  static const Color snackbarSuccessDark = Color(0xFF166534); // Green 800
  static const Color snackbarErrorDark = Color(0xFF991B1B); // Red 800
  static const Color snackbarNeutralDark = Color(0xFF3F3F46); // Zinc 700

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _brandOrange,
      brightness: Brightness.light,
    ).copyWith(
      primary: _brandOrange,
      onPrimary: Colors.white,
      primaryContainer: _brandOrange.withOpacity(0.2),
      onPrimaryContainer: _brandOrange,
      secondary: _brandPurple,
      onSecondary: Colors.white,
      tertiary: _brandPurple,
      onTertiary: Colors.white,
      error: const Color(0xFFDC2626), // Red 600
      onError: Colors.white,
      surface: _lightSurface,
      surfaceContainerHighest: const Color(0xFFF3F4F6),
      onSurface: const Color(0xFF1F2937),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBackground,
      cardTheme: CardThemeData(
        elevation: 2,
        color: _lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: _lightBackground,
        foregroundColor: colorScheme.onSurface,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _brandOrangeDark,
      brightness: Brightness.dark,
    ).copyWith(
      primary: _brandOrangeDark,
      onPrimary: Colors.white,
      primaryContainer: _brandOrangeDark.withOpacity(0.3),
      onPrimaryContainer: _brandOrangeDark,
      secondary: _brandPurpleDark,
      onSecondary: Colors.white,
      tertiary: _brandPurpleDark,
      onTertiary: Colors.white,
      error: const Color(0xFFEF4444), // Red 500
      onError: Colors.white,
      surface: _darkSurface,
      surfaceContainerHighest: _darkSurfaceVariant,
      surfaceContainerHigh: const Color(0xFF2A2A2A),
      surfaceContainer: _darkSurface,
      onSurface: const Color(0xFFE8E8E8),
      onSurfaceVariant: const Color(0xFFC0C0C0),
      outline: const Color(0xFF505050),
      outlineVariant: const Color(0xFF3A3A3A),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBackground,
      cardTheme: CardThemeData(
        elevation: 2,
        color: _darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: _darkBackground,
        foregroundColor: colorScheme.onSurface,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkSurfaceVariant,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: colorScheme.onSurface),
        bodyMedium: TextStyle(color: colorScheme.onSurface),
        bodySmall: TextStyle(color: colorScheme.onSurfaceVariant),
        titleLarge: TextStyle(color: colorScheme.onSurface),
        titleMedium: TextStyle(color: colorScheme.onSurface),
        titleSmall: TextStyle(color: colorScheme.onSurface),
        labelLarge: TextStyle(color: colorScheme.onSurface),
        labelMedium: TextStyle(color: colorScheme.onSurface),
        labelSmall: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
