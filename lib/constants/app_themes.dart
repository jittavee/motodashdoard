import 'package:flutter/material.dart';

enum ThemeType { classic, sport, digital }

class AppThemes {
  // Theme 1: Classic (คลาสสิค - โทนสีน้ำตาล/ทอง)
  static final ThemeData classicTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFD4AF37), // Gold
    scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFD4AF37),
      secondary: Color(0xFF8B4513),
      surface: Color(0xFF2A2A2A),
      error: Color(0xFFFF6B6B),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2A2A2A),
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF2A2A2A),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  // Theme 2: Sport (สปอร์ต - โทนสีแดง/ดำ)
  static final ThemeData sportTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFFF0000), // Red
    scaffoldBackgroundColor: const Color(0xFF000000),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFF0000),
      secondary: Color(0xFFFF6B00),
      surface: Color(0xFF1A0000),
      error: Color(0xFFFFFF00),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A0000),
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A0000),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  // Theme 3: Digital (ดิจิทัล - โทนสีฟ้า/ขาว)
  static final ThemeData digitalTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF00D9FF), // Cyan
    scaffoldBackgroundColor: const Color(0xFF0A0E27),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00D9FF),
      secondary: Color(0xFF6C63FF),
      surface: Color(0xFF1A1F3A),
      error: Color(0xFFFF4757),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1F3A),
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A1F3A),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  static ThemeData getTheme(ThemeType type) {
    switch (type) {
      case ThemeType.classic:
        return classicTheme;
      case ThemeType.sport:
        return sportTheme;
      case ThemeType.digital:
        return digitalTheme;
    }
  }

  // สีสำหรับ Gauge
  static Color getGaugeColor(ThemeType type) {
    switch (type) {
      case ThemeType.classic:
        return const Color(0xFFD4AF37);
      case ThemeType.sport:
        return const Color(0xFFFF0000);
      case ThemeType.digital:
        return const Color(0xFF00D9FF);
    }
  }

  // สีพื้นหลัง Gauge
  static Color getGaugeBackgroundColor(ThemeType type) {
    switch (type) {
      case ThemeType.classic:
        return const Color(0xFF2A2A2A);
      case ThemeType.sport:
        return const Color(0xFF1A0000);
      case ThemeType.digital:
        return const Color(0xFF1A1F3A);
    }
  }

  // สีข้อความ
  static Color getTextColor(ThemeType type) {
    switch (type) {
      case ThemeType.classic:
        return const Color(0xFFD4AF37);
      case ThemeType.sport:
        return const Color(0xFFFFFFFF);
      case ThemeType.digital:
        return const Color(0xFF00D9FF);
    }
  }
}