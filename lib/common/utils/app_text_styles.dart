import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // HEADING STYLES
  static TextStyle heading1({
    Color color = Colors.black,
    double fontSize = 32,
    FontWeight fontWeight = FontWeight.w700,
    double letterSpacing = 0,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    return GoogleFonts.playfairDisplay(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );
  }

  static TextStyle heading2({
    Color color = Colors.black,
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w600,
    double letterSpacing = 0.5,
  }) {
    return GoogleFonts.playfairDisplay(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );
  }

  // BODY TEXT STYLES
  static TextStyle bodyLarge({
    Color color = Colors.black87,
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w400,
    double height = 1.5,
  }) {
    return GoogleFonts.montserrat(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
    );
  }

  static TextStyle bodyMedium({
    Color color = Colors.black87,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    TextDecoration decoration = TextDecoration.none,
  }) {
    return GoogleFonts.montserrat(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      decoration: decoration,
    );
  }

  // SPECIAL ASTROLOGY STYLES
  static TextStyle zodiacSign({
    Color color = Colors.deepPurple,
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return GoogleFonts.cinzel(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  static TextStyle horoscopeText({
    Color color = Colors.indigo,
    double fontSize = 16,
    FontStyle fontStyle = FontStyle.italic,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return GoogleFonts.alegreya(
      color: color,
      fontSize: fontSize,
      fontStyle: fontStyle,
      fontWeight: fontWeight
    );
  }

  // BUTTON TEXT
  static TextStyle buttonText({
    Color color = Colors.white,
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w600,
    double letterSpacing = 1.0,
  }) {
    return GoogleFonts.exo2(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );
  }

  // CAPTION/TINY TEXT
  static TextStyle captionText({
    Color color = Colors.grey,
    double fontSize = 12,
    double height = 1.0,
    FontWeight fontWeight = FontWeight.w600,
    double letterSpacing = 1.0,
  }) {
    return GoogleFonts.montserrat(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing
    );
  }
}