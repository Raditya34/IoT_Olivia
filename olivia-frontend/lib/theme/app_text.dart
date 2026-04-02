import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppText {
  /* =========================
   * BRAND / SPLASH
   * ========================= */

  // OLIVIA
  static TextStyle brand(BuildContext context) => const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.5,
        color: AppColors.textDark,
        height: 1.1,
      );

  // OIL FILTRATION AUTOMATION
  static TextStyle brandTagline(BuildContext context) => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
        color: AppColors.tealDark,
      );

  // Turning Waste Oil into Value
  static TextStyle slogan(BuildContext context) => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        height: 1.35,
      );

  /* =========================
   * HEADERS (UI)
   * ========================= */

  static TextStyle h1(BuildContext context) => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
        height: 1.2,
      );

  static TextStyle h2(BuildContext context) => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      );

  static TextStyle h3(BuildContext context) => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      );

  /* =========================
   * BODY
   * ========================= */

  static TextStyle body(BuildContext context) => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textDark,
        height: 1.45,
      );

  static TextStyle muted(BuildContext context) => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        height: 1.4,
      );

  static TextStyle caption(BuildContext context) => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      );

  /* =========================
   * UI ELEMENTS
   * ========================= */

  static TextStyle button(BuildContext context) => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: AppColors.textLight,
      );

  static TextStyle chip(BuildContext context) => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: AppColors.textDark,
      );
}
