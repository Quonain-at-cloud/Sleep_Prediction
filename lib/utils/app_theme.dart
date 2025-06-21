import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color gold = Color(0xFFF7F3B7); 

  static TextStyle get displayLarge => GoogleFonts.montserratAlternates(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    height: 1.2,
  );

  static TextStyle get titleLarge => GoogleFonts.montserratAlternates(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    height: 1.2,
  );

  static TextStyle get titleMedium => GoogleFonts.montserratAlternates(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
  );

  static TextStyle get titleSmall => GoogleFonts.montserratAlternates(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
  );
  static TextStyle get titleExtraSmall => GoogleFonts.montserratAlternates(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
  );
  static TextStyle get labelLarge => GoogleFonts.montserratAlternates(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    height: 1.5,
  );

  static TextStyle get labelMedium => GoogleFonts.montserratAlternates(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    height: 1.5,
  );

  static TextStyle get labelSmall => GoogleFonts.montserratAlternates(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    height: 1.5,
  );

  static TextStyle get bodyLarge => GoogleFonts.montserratAlternates(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.montserratAlternates(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.white,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.montserratAlternates(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Colors.white,
    height: 1.5,
  );

  static TextStyle get buttonLarge => GoogleFonts.montserratAlternates(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle get buttonMedium => GoogleFonts.montserratAlternates(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // Helper method to modify any text style
  static TextStyle modifyStyle(TextStyle baseStyle, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
    double? letterSpacing,
  }) {
    return baseStyle.copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
      letterSpacing: letterSpacing,
    );
  }
} 