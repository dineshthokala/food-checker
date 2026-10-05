import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/logger.dart';
import '../../providers/safe_foods_provider.dart';
import '../../widgets/verdict_badge.dart';

class SafeFoodsScreen extends ConsumerWidget {
  const SafeFoodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeFoods = ref.watch(safeFoodsProvider);

    return Scaffold(
      backgroundColor: AppColors.warmSand,
      body: SafeArea(
        child: safeFoods.isEmpty ? _buildEmptyState(context) : _buildList(context, ref, safeFoods),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.tealSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_outline_rounded,
                size: 40,
                color: AppColors.deepTeal,
              ),
            ).animate().fadeIn(duration: 400.ms).scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
              duration: 400.ms,
            ),
            const SizedBox(height: 24),
            Text(
              'No saved foods yet',
              style: Theme.of(context).textTheme.headlineMedium,
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
            const SizedBox(height: 8),
            Text(
              'Search for a food and save it to build your personal safe foods list.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedPlum,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.search_rounded, size: 20),
              label: const Text('Search foods'),
            ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List safeFoods) {
    return LiquidPullToRefresh(
      onRefresh: () async {
        try {
          // Just a dummy delay to show the beautiful refresh animation
          await Future.delayed(const Duration(milliseconds: 1500));
        } catch (e, st) {
          logScreenError('SafeFoodsScreen', 'Failed to refresh safe foods', e, st);
        }
      },
      color: AppColors.tealSurface,
      backgroundColor: AppColors.deepTeal,
      height: 60,
      animSpeedFactor: 2.0,
      showChildOpacityTransition: false,
      child: CustomScrollView(
        slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My safe foods',
                  style: Theme.of(context).textTheme.displayMedium,
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 4),
                Text(
                  '${safeFoods.length} food${safeFoods.length == 1 ? '' : 's'} saved',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedPlum,
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final sf = safeFoods[index];
                return Dismissible(
                  key: ValueKey(sf.food),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.verdictAvoidBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.verdictAvoid,
                    ),
                  ),
                  onDismissed: (_) {
                    try {
                      ref.read(safeFoodsProvider.notifier).removeFood(sf.food);
                    } catch (e, st) {
                      logScreenError('SafeFoodsScreen', 'Failed to remove "${sf.food}"', e, st);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.divider.withValues(alpha: 0.5),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 6,
                      ),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.tealSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.restaurant_rounded,
                          color: AppColors.deepTeal,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        sf.food,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        'Saved ${_formatDate(sf.addedAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                      trailing: VerdictChip(verdict: sf.verdict),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onTap: () {
                        try {
                          context.push('/result/${Uri.encodeComponent(sf.food)}');
                        } catch (e, st) {
                          logScreenError('SafeFoodsScreen', 'Failed to open result for "${sf.food}"', e, st);
                        }
                      },
                    ),
                  ),
                );
              },
              childCount: safeFoods.length,
            ),
          ),
        ),
      ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
