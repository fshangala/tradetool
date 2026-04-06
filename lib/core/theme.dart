import 'package:flutter/material.dart';

class BinanceTheme {
  static const Color yellow = Color(0xFFF0B90B);
  static const Color darkBackground = Color(0xFF1E2329);
  static const Color surfaceColor = Color(0xFF2B3139);
  static const Color textColor = Color(0xFFEAECEF);
  static const Color secondaryTextColor = Color(0xFF848E9C);
  static const Color green = Color(0xFF0ECB81);
  static const Color red = Color(0xFFF6465D);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: yellow,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: yellow,
        onPrimary: Colors.black,
        secondary: yellow,
        surface: surfaceColor,
        onSurface: textColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(color: textColor),
        bodyMedium: TextStyle(color: secondaryTextColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: yellow,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return yellow;
          }
          return secondaryTextColor;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return yellow.withValues(alpha: 0.5);
          }
          return surfaceColor;
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: yellow, width: 1),
        ),
        labelStyle: const TextStyle(color: secondaryTextColor),
        hintStyle: const TextStyle(color: secondaryTextColor),
      ),
    );
  }

  // Gradients for modern UI
  static const LinearGradient yellowGradient = LinearGradient(
    colors: [Color(0xFFFCD535), yellow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [surfaceColor, darkBackground],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
