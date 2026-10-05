import 'package:flutter/material.dart';

/// FoodChecker color system.
/// Deep Teal primary conveys trust and health.
/// Warm Sand background feels human, not clinical.
class AppColors {
  AppColors._();

  // ── Primary ──
  static const deepTeal = Color(0xFF0A6E5C);
  static const deepTealLight = Color(0xFF0E8A73);
  static const deepTealDark = Color(0xFF085647);
  static const tealSurface = Color(0xFFE6F5F1);

  // ── Background ──
  static const warmSand = Color(0xFFF5F0E8);
  static const warmSandDark = Color(0xFFE8E0D4);

  // ── Surfaces ──
  static const softSage = Color(0xFFD4E4D9);
  static const white = Color(0xFFFFFFFF);
  static const cardBg = Color(0xFFFAF8F4);

  // ── Verdict ──
  static const verdictGood = Color(0xFF2D8C5A);
  static const verdictGoodBg = Color(0xFFE8F5EC);
  static const verdictLimit = Color(0xFFE5A432);
  static const verdictLimitBg = Color(0xFFFFF4E0);
  static const verdictAvoid = Color(0xFFE8654A);
  static const verdictAvoidBg = Color(0xFFFDE8E4);

  // ── Text ──
  static const charcoal = Color(0xFF1A1A2E);
  static const mutedPlum = Color(0xFF6B5B7B);
  static const textLight = Color(0xFF9A8FA3);
  static const textOnPrimary = Color(0xFFFFFFFF);

  // ── Utility ──
  static const divider = Color(0xFFE0D8CC);
  static const error = Color(0xFFD32F2F);
  static const shimmer = Color(0xFFE8E0D4);
  static const cardShadow = Color(0x14000000);
  static const overlay = Color(0x4D000000);
}
