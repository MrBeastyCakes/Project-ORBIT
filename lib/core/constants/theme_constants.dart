import 'package:flutter/material.dart';

class ThemeConstants {
  ThemeConstants._();

  static const Color backgroundColor = Color(0xFF0A0A1A);
  static const Color surfaceColor = Color(0xFF1A1A2E);
  static const Color accentColor = Color(0xFF6C63FF);
  static const Color starColor = Color(0xFFFFF8E7);
  static const Color blackHoleColor = Color(0xFF2D1B69);
  static const Color defaultPlanetColor = Color(0xFF4A90D9);
  static const Color urgentAtmosphereColor = Color(0xFF2ECC71);
  static const Color referenceAtmosphereColor = Color(0xFF3498DB);
  static const Color protostarGlowColor = Color(0xFFFFD700);
  static const Color nebulaColor = Color(0x33FF6B6B);
  static const Color constellationLineColor = Color(0x66FFFFFF);
  static const Color orbitPathColor = Color(0x14FFFFFF);
  static const Color wormholeColor = Color(0xFF00E5FF);

  static ThemeData get orbitDarkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: const ColorScheme.dark(
          surface: surfaceColor,
          primary: accentColor,
          secondary: wormholeColor,
        ),
        cardColor: surfaceColor,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: starColor),
          bodyMedium: TextStyle(color: starColor),
        ),
      );
}
