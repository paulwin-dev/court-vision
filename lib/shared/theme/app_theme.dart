import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background  = Color(0xFF1A1C1E);
  static const accent      = Color(0xFFDFFF4F);
  static const surface1    = Color(0xFF272828);
  static const surface2    = Color(0xFF2D2F30);
  static const stroke1     = Color(0xFF303233);
  static const stroke2     = Color(0xFF424344);
  static const white       = Color(0xFFFFFFFF);
  static const red         = Color(0xFF2C1919);
  static const red_stroke  = Color(0xFF56282A);

  static const subtext = Color(0xFF868686);
}

ThemeData buildAppTheme() {
  final outfit = GoogleFonts.outfitTextTheme();

  return ThemeData(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      background: AppColors.background,
      primary:    AppColors.accent,
      surface:    AppColors.surface1,
      surfaceContainerLowest: AppColors.surface1,
      surfaceContainerHighest: AppColors.surface2,
      outline: AppColors.stroke1,
      outlineVariant: AppColors.stroke2,
      errorContainer: AppColors.red,
      onErrorContainer: AppColors.red_stroke,

      surfaceBright: AppColors.subtext
    ),
    textTheme: outfit.apply(
      bodyColor:    AppColors.white,
      displayColor: AppColors.white,
    ),
  );
}