import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/food_result.dart';

/// The hero element on the result screen — a large, animated verdict badge.
class VerdictBadge extends StatelessWidget {
  final Verdict verdict;
  final double size;

  const VerdictBadge({
    super.key,
    required this.verdict,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _bgColor,
        boxShadow: [
          BoxShadow(
            color: _color.withValues(alpha: 0.25),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_icon, color: _color, size: size * 0.35),
          const SizedBox(height: 4),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontSize: size * 0.14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color get _color {
    switch (verdict) {
      case Verdict.good:
        return AppColors.verdictGood;
      case Verdict.limit:
        return AppColors.verdictLimit;
      case Verdict.avoid:
        return AppColors.verdictAvoid;
    }
  }

  Color get _bgColor {
    switch (verdict) {
      case Verdict.good:
        return AppColors.verdictGoodBg;
      case Verdict.limit:
        return AppColors.verdictLimitBg;
      case Verdict.avoid:
        return AppColors.verdictAvoidBg;
    }
  }

  IconData get _icon {
    switch (verdict) {
      case Verdict.good:
        return Icons.check_rounded;
      case Verdict.limit:
        return Icons.warning_amber_rounded;
      case Verdict.avoid:
        return Icons.close_rounded;
    }
  }

  String get _label {
    switch (verdict) {
      case Verdict.good:
        return 'Good';
      case Verdict.limit:
        return 'Limit';
      case Verdict.avoid:
        return 'Avoid';
    }
  }
}

/// Small inline verdict indicator for lists and cards.
class VerdictChip extends StatelessWidget {
  final Verdict verdict;

  const VerdictChip({super.key, required this.verdict});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color get _color {
    switch (verdict) {
      case Verdict.good:
        return AppColors.verdictGood;
      case Verdict.limit:
        return AppColors.verdictLimit;
      case Verdict.avoid:
        return AppColors.verdictAvoid;
    }
  }

  Color get _bgColor {
    switch (verdict) {
      case Verdict.good:
        return AppColors.verdictGoodBg;
      case Verdict.limit:
        return AppColors.verdictLimitBg;
      case Verdict.avoid:
        return AppColors.verdictAvoidBg;
    }
  }

  String get _label {
    switch (verdict) {
      case Verdict.good:
        return 'Good';
      case Verdict.limit:
        return 'Limit';
      case Verdict.avoid:
        return 'Avoid';
    }
  }
}
