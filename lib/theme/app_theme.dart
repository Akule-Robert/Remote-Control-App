import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0D0D14);
  static const bg2 = Color(0xFF13131E);
  static const bg3 = Color(0xFF1C1C2A);
  static const bg4 = Color(0xFF252536);
  static const surface = Color(0xFF1A1A28);
  static const border = Color(0x14FFFFFF);
  static const border2 = Color(0x24FFFFFF);
  static const accent = Color(0xFF5B6EF5);
  static const accentDim = Color(0x2E5B6EF5);
  static const text = Color(0xFFF2F2F8);
  static const text2 = Color(0xFF8888A8);
  static const text3 = Color(0xFF4A4A65);
  static const green = Color(0xFF29C278);
  static const red = Color(0xFFF04545);
  static const yellow = Color(0xFFF0C040);
}

final appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.bg,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.accent,
    surface: AppColors.surface,
  ),
  fontFamily: 'DMSans',
  useMaterial3: true,
);
