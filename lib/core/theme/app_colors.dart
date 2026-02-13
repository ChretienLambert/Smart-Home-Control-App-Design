import 'package:flutter/material.dart';

class AppColors {
  // Primary Cyano Blue Palette
  static const Color cyanoBlue = Color(0xFF00897B);
  static const Color cyanoBlueLight = Color(0xFF26A69A);
  static const Color cyanoBlueDark = Color(0xFF00695C);
  static const Color cyanoBlueDarker = Color(0xFF004D40);

  // Accent Colors
  static const Color accentCyan = Color(0xFF00BCD4);
  static const Color accentTeal = Color(0xFF009688);
  static const Color accentLightBlue = Color(0xFF03A9F4);

  // Neutral Colors
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Device Status Colors
  static const Color deviceOnline = cyanoBlue;
  static const Color deviceOffline = textSecondary;
  static const Color deviceActive = accentCyan;
  static const Color deviceInactive = textSecondary;

  // Alert Severity Colors
  static const Color alertInfo = info;
  static const Color alertWarning = warning;
  static const Color alertError = error;
  static const Color alertCritical = Color(0xFF9C27B0);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyanoBlue, accentCyan],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyanoBlueLight, cyanoBlue],
  );

  // Shadow Colors
  static const Color shadowColor = Color(0x1A000000);
  static const Color lightShadowColor = Color(0x0D000000);
}

extension ColorExtension on Color {
  Color withOpacity(double opacity) {
    return Color.fromARGB(
      (255 * opacity).round(),
      r.toInt(),
      g.toInt(),
      b.toInt(),
    );
  }
}
