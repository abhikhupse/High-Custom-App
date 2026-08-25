import 'package:flutter/material.dart';

class AppTheme {
  static const background = Color(0xFF020507);
  static const surface = Color(0xFF0A0D11);
  static const elevatedSurface = Color(0xFF0E1116);
  static const border = Color(0xFF282D35);
  static const gold = Color(0xFFF2C45F);
  static const goldDark = Color(0xFFD9A93F);
  static const success = Color(0xFF168447);
  static const warning = Color(0xFFF2C45F);
  static const error = Color(0xFFFF5B66);
  static const text = Color(0xFFF3F4F6);
  static const mutedText = Color(0xFF9298A3);

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: gold,
      onPrimary: Color(0xFF17120A),
      secondary: goldDark,
      onSecondary: Color(0xFF17120A),
      surface: surface,
      onSurface: text,
      error: error,
      onError: Colors.white,
      outline: border,
    );
    final roundedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: border),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Roboto',
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      dividerColor: border,
      dialogTheme: const DialogThemeData(
        backgroundColor: elevatedSurface,
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF070A0E),
        labelStyle: const TextStyle(color: mutedText),
        hintStyle: const TextStyle(color: mutedText),
        errorMaxLines: 2,
        border: roundedBorder,
        enabledBorder: roundedBorder,
        focusedBorder: roundedBorder.copyWith(
          borderSide: const BorderSide(color: gold, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: const Color(0xFF17120A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: const Color(0xFF17120A),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: gold,
        foregroundColor: Color(0xFF17120A),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: gold),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? gold : null,
        ),
        checkColor: const WidgetStatePropertyAll(Color(0xFF17120A)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? gold : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? gold.withValues(alpha: 0.45)
              : null,
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: Color(0x33F2C45F),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: Color(0x33F2C45F),
        selectedIconTheme: IconThemeData(color: gold),
        selectedLabelTextStyle: TextStyle(color: gold),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: success,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
