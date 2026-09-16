import 'package:flutter/material.dart';

abstract class AppColors {
  //Cores base
  static const Color bgColor = Color(0xFFF8FAFC);
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color secondaryColor = Color(0xFF06B6D4);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color primaryTextColor = Color(0xFF0F172A);
  static const Color secondaryTextColor = Color(0xFF64748B);

  //Complementos
  static const Color primaryColorDark = Color(0xFF1D4ED8);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color inputFillColor = Color(0xFFF1F5F9);
  static const Color hintTextColor = Color(0xFF94A3B8);
  static const Color disabledColor = Color(0xFFCBD5E1);
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);

  static const Color shadowColor = Color(0x1A2563EB);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}