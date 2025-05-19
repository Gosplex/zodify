import 'package:flutter/material.dart';

class AppColors {
  // Primary Purple Theme
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      primary,
      primaryDark,
    ],
    stops: [0.0, 1.0],
  );
  static const Color primary = Color(0xFF22103D);
  static const Color primaryLight = Color(0xFFA968f6);
  static const Color primaryDark = Color(0xFF38006B);
  static const Color primaryDark2 = Color(0xFF764BFA);

  // Text Colors
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Colors.black87;
  static const Color textWhite = Colors.white;
  static const Color textWhite70 = Colors.white70;
  static const Color textGrey = Colors.grey;

  // Background Colors
  static const Color backgroundLight = Colors.white;
  static const Color backgroundDark = Color(0xFF121212);
  static const Color profileBackground = Color(0x80585858);

  // Accent Colors
  static const Color accentPurple = Color(0xFFAB47BC);
  static const Color accentAmber = Color(0xFFFFC107);
  static const Color accentDeepPurple = Color(0xFF7E57C2);
  static const Color accentIndigo = Color(0xFF5C6BC0);

  // Button Colors
  static const Color buttonPrimary = Color(0xFF22103D);
  static const Color buttonText = Colors.white;

  // Input Fields
  static const Color inputBorder = Color(0xFF6A1B9A);
  static const Color inputBorderFocused = Color(0xFF9C4DF4);
  static const Color inputBackground = Colors.white;

  // Special Astrology Colors
  static const Color zodiacGold = Color(0xFFD4AF37);
  static const Color cosmicBlue = Color(0xFF1A237E);
  static const Color mysticPurple = Color(0xFF4A148C);
  static const Color starWhite = Color(0xFFE1F5FE);

  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFF44336);
}