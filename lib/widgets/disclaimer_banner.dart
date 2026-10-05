import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// A subtle, persistent disclaimer banner for health-related screens.
class DisclaimerBanner extends StatelessWidget {
  final String text;

  const DisclaimerBanner({
    super.key,
    this.text = 'This is general guidance, not medical advice. Always consult your doctor or dietitian.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warmSandDark.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.mutedPlum.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.mutedPlum.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
