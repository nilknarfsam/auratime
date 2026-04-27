import 'package:flutter/material.dart';

class AppTheme {
  static const Color _background = Color(0xFF0B0B12);
  static const Color _surface = Color(0xFF151523);
  static const Color _surfaceVariant = Color(0xFF1E1E30);
  static const Color _primaryAura = Color(0xFF8B7CFF);
  static const Color _secondaryAura = Color(0xFF53D6FF);
  static const Color _onDark = Color(0xFFF6F7FF);
  static const Color _mutedText = Color(0xFFB5B8C9);

  static ThemeData get premiumDark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _primaryAura,
      onPrimary: Color(0xFF0A0718),
      secondary: _secondaryAura,
      onSecondary: Color(0xFF00151F),
      error: Color(0xFFFF6E8A),
      onError: Colors.white,
      surface: _surface,
      onSurface: _onDark,
      surfaceContainerHighest: _surfaceVariant,
      onSurfaceVariant: _mutedText,
      outline: Color(0xFF3A3A53),
      shadow: Colors.black,
      inverseSurface: _onDark,
      onInverseSurface: _background,
      inversePrimary: Color(0xFFC3BCFF),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _background,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: _background,
        foregroundColor: _onDark,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: _surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2A2A40)),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: _onDark,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        headlineMedium: TextStyle(
          color: _onDark,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: _onDark),
        bodyMedium: TextStyle(color: _mutedText),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF26263A),
        thickness: 1,
      ),
    );
  }
}
