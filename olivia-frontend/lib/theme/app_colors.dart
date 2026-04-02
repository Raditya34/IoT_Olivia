import 'package:flutter/material.dart';

class AppColors {
  /* =========================
   * BRAND (OLIVIA)
   * ========================= */
  static const Color teal = Color(0xFF1FB6AA); // Primary
  static const Color tealDark = Color(0xFF0E8F86);
  static const Color orange = Color(0xFFF59E0B); // Accent
  static const Color orangeDeep = Color(0xFFEA580C);

  /* =========================
   * STATUS
   * ========================= */
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = teal;

  /* =========================
   * BACKGROUND & SURFACE
   * ========================= */
  static const Color background = Color(0xFFF6F7FB);
  static const Color surface = Colors.white;

  static const Color border = Color(0x1A0F172A); // 10% dark
  static const Color divider = Color(0x14000000);

  /* =========================
   * TEXT
   * ========================= */
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Colors.white;

  /* =========================
   * GRADIENTS
   * ========================= */

  // Untuk tombol Login / Mulai
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      orange,
      orangeDeep,
    ],
  );

  // Optional (kalau nanti mau pakai)
  static const LinearGradient modernGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF5B7CFF),
      teal,
    ],
  );
}
