import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/network_monitor.dart';

/// Wraps the main tabs (Home, Safe Foods, Profile) with a bottom nav bar.
class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/safe-foods')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _currentIndex(context);
    final isOnline = ref.watch(isOnlineProvider).value ?? true;

    return Scaffold(
      body: Column(
        children: [
          if (!isOnline)
            Container(
              width: double.infinity,
              color: AppColors.verdictLimitBg,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: const SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 14,
                      color: AppColors.verdictLimit,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Offline mode — using local database',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.verdictLimit,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.search_rounded,
                  label: 'Search',
                  isSelected: currentIndex == 0,
                  onTap: () => context.go('/home'),
                ),
                _NavItem(
                  icon: Icons.bookmark_outline_rounded,
                  selectedIcon: Icons.bookmark_rounded,
                  label: 'Safe Foods',
                  isSelected: currentIndex == 1,
                  onTap: () => context.go('/safe-foods'),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  selectedIcon: Icons.person_rounded,
                  label: 'Profile',
                  isSelected: currentIndex == 2,
                  onTap: () => context.go('/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.tealSurface
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? (selectedIcon ?? icon) : icon,
              size: 22,
              color: isSelected ? AppColors.deepTeal : AppColors.textLight,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepTeal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
