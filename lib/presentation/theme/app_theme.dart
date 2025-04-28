import 'package:flutter/material.dart';

class AppTheme {
  static const _primaryColor = Colors.blue;
  static const _surfaceTintLight = Color(0xFFF5F5F5);
  static const _surfaceTintDark = Color(0xFF1E1E1E);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
      surfaceTint: _surfaceTintLight,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 2,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      space: 24,
      thickness: 1,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.dark,
      surfaceTint: _surfaceTintDark,
      // Enhanced dark theme colors
      background: const Color(0xFF121212),
      surface: const Color(0xFF1E1E1E),
      surfaceVariant: const Color(0xFF2D2D2D),
      // Increased contrast for better readability
      onBackground: Colors.white,
      onSurface: Colors.white,
      onSurfaceVariant: const Color(0xFFE0E0E0),
      // Vibrant accent colors
      primary: Colors.blue.shade300,
      secondary: Colors.tealAccent.shade200,
      tertiary: Colors.purpleAccent.shade100,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: const Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.blue.shade300,
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: const Color(0xFF2D2D2D),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: Colors.blue.shade300,
        foregroundColor: Colors.black,
      ),
    ),
    dividerTheme: DividerThemeData(
      space: 24,
      thickness: 1,
      color: Colors.grey.shade700,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Colors.blue,
      textColor: Colors.white,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.blue.shade300;
        }
        return null;
      }),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.blue.shade300;
        }
        return Colors.grey.shade400;
      }),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF2D2D2D),
      contentTextStyle: TextStyle(color: Colors.white),
      actionTextColor: Colors.blue,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: const Color(0xFF1E1E1E),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
