import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:share_plus/share_plus.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/logger.dart';
import '../../models/food_result.dart';
import '../../providers/auth_provider.dart';
import '../../providers/food_search_provider.dart';
import '../../providers/safe_foods_provider.dart';
import '../../widgets/verdict_badge.dart';
import '../../widgets/disclaimer_banner.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final String food;

  const ResultScreen({super.key, required this.food});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  late final ConfettiController _confettiController;
  bool _showDecisionResponse = false;
  String? _decisionMessage;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    // Trigger search if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final state = ref.read(foodSearchProvider);
        if (state.result == null || state.result!.food != widget.food) {
          ref.read(foodSearchProvider.notifier).searchFood(widget.food);
        }
      } catch (e, st) {
        logScreenError(
          'ResultScreen',
          'Failed to search for "${widget.food}"',
          e,
          st,
        );
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _onWillEat(FoodResult result) {
    try {
      // Log decision
      ref
          .read(foodDecisionLogProvider)
          .log(
            food: result.food,
            verdict: result.verdict.name,
            decision: 'will_eat',
            conditions: ref.read(authProvider).user?.conditions ?? [],
          );

      setState(() {
        _showDecisionResponse = true;
        _decisionMessage =
            result.portionTip ??
            'No worries — just be mindful of your portion.';
      });
    } catch (e, st) {
      logScreenError(
        'ResultScreen',
        'Failed to log "will eat" for "${result.food}"',
        e,
        st,
      );
    }
  }

  void _onWontEat(FoodResult result) async {
    try {
      // Heavy vibration on submission
      await Haptics.vibrate(HapticsType.medium);

      // Log decision
      ref
          .read(foodDecisionLogProvider)
          .log(
            food: result.food,
            verdict: result.verdict.name,
            decision: 'wont_eat',
            conditions: ref.read(authProvider).user?.conditions ?? [],
          );

      // Add to safe foods if verdict is good/limit
      if (result.verdict != Verdict.avoid) {
        ref
            .read(safeFoodsProvider.notifier)
            .addFood(result.food, result.verdict);
      }

      _confettiController.play();
      setState(() {
        _showDecisionResponse = true;
        _decisionMessage = 'Great choice — your body thanks you! 💚';
      });

      _promptReview();
    } catch (e, st) {
      logScreenError(
        'ResultScreen',
        'Failed to log "wont eat" for "${result.food}"',
        e,
        st,
      );
    }
  }

  Future<void> _promptReview() async {
    // Randomly prompt for review after logging a decision (1 in 5 chance)
    try {
      if (Random().nextDouble() < 0.2) {
        final InAppReview inAppReview = InAppReview.instance;
        if (await inAppReview.isAvailable()) {
          inAppReview.requestReview();
        }
      }
    } catch (e, st) {
      logScreenError('ResultScreen', 'Failed to prompt in-app review', e, st);
    }
  }

  void _showReportSheet(FoodResult result) {
    String? selectedType;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Report this result',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Help us improve by reporting inaccurate information.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  RadioGroup<String>(
                    groupValue: selectedType,
                    onChanged: (v) => setSheetState(() => selectedType = v),
                    child: Column(
                      children:
                          [
                            (
                              'false_positive',
                              'False positive',
                              'Marked as bad, but it\'s actually fine',
                            ),
                            (
                              'false_negative',
                              'False negative',
                              'Marked as good, but it\'s actually risky',
                            ),
                            (
                              'incorrect_info',
                              'Incorrect information',
                              'The explanation or alternatives are wrong',
                            ),
                            ('other', 'Other', 'Something else'),
                          ].map((item) {
                            return RadioListTile<String>(
                              value: item.$1,
                              title: Text(
                                item.$2,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                item.$3,
                                style: const TextStyle(fontSize: 12),
                              ),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Additional details (optional)',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedType == null
                          ? null
                          : () {
                              try {
                                ref
                                    .read(foodReportProvider)
                                    .report(
                                      food: result.food,
                                      reportType: selectedType!,
                                      comment: commentController.text.isNotEmpty
                                          ? commentController.text
                                          : null,
                                      verdictSnapshot: result.toJson(),
                                    );
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Report submitted. Thank you!',
                                    ),
                                  ),
                                );
                              } catch (e, st) {
                                logScreenError(
                                  'ResultScreen',
                                  'Failed to submit report for "${result.food}"',
                                  e,
                                  st,
                                );
                              }
                            },
                      child: const Text('Submit report'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Log food-search failures with screen context (fires once per new error).
    ref.listen(foodSearchProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        logScreenError(
          'ResultScreen',
          'Food search failed for "${widget.food}"',
          next.error!,
        );
      }
    });
    final searchState = ref.watch(foodSearchProvider);
    final safeFoods = ref.watch(safeFoodsProvider);
    final isSaved = safeFoods.any(
      (s) => s.food.toLowerCase() == widget.food.toLowerCase(),
    );

    return Scaffold(
      backgroundColor: AppColors.warmSand,
      appBar: AppBar(
        title: Text(widget.food),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (searchState.result != null)
            IconButton(
              icon: const Icon(Icons.share_rounded, color: AppColors.deepTeal),
              onPressed: () async {
                try {
                  await Haptics.vibrate(HapticsType.light);
                  final res = searchState.result!;
                  SharePlus.instance.share(
                    ShareParams(
                      text:
                          'I checked ${res.food} on FoodChecker and it is ${res.verdict.name.toUpperCase()} for my diet! Check it out.',
                    ),
                  );
                } catch (e, st) {
                  logScreenError(
                    'ResultScreen',
                    'Failed to share result for "${widget.food}"',
                    e,
                    st,
                  );
                }
              },
            ),
          if (searchState.result != null)
            IconButton(
              icon: Icon(
                isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: isSaved ? AppColors.deepTeal : null,
              ),
              onPressed: () {
                try {
                  if (isSaved) {
                    ref
                        .read(safeFoodsProvider.notifier)
                        .removeFood(widget.food);
                  } else {
                    ref
                        .read(safeFoodsProvider.notifier)
                        .addFood(widget.food, searchState.result!.verdict);
                  }
                } catch (e, st) {
                  logScreenError(
                    'ResultScreen',
                    'Failed to toggle saved food "${widget.food}"',
                    e,
                    st,
                  );
                }
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          searchState.isLoading
              ? _buildSkeleton()
              : searchState.result != null
              ? _buildResult(searchState.result!)
              : searchState.error != null
              ? _buildError(searchState.error!)
              : const SizedBox.shrink(),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 20,
              minBlastForce: 8,
              emissionFrequency: 0.05,
              numberOfParticles: 25,
              gravity: 0.2,
              shouldLoop: false,
              colors: const [
                AppColors.verdictGood,
                AppColors.deepTeal,
                AppColors.tealSurface,
                AppColors.softSage,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.divider.withValues(alpha: 0.3),
      highlightColor: AppColors.white.withValues(alpha: 0.6),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Container(width: 200, height: 24, color: Colors.white),
            const SizedBox(height: 12),
            Container(width: double.infinity, height: 60, color: Colors.white),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.verdictAvoid,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                try {
                  ref.read(foodSearchProvider.notifier).searchFood(widget.food);
                } catch (e, st) {
                  logScreenError(
                    'ResultScreen',
                    'Retry search failed for "${widget.food}"',
                    e,
                    st,
                  );
                }
              },
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(FoodResult result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // ── Food Hero Card ──
          Container(
                height: 130,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: result.verdict == Verdict.good
                        ? [AppColors.verdictGoodBg, AppColors.tealSurface]
                        : result.verdict == Verdict.limit
                        ? [AppColors.verdictLimitBg, AppColors.warmSandDark]
                        : [AppColors.verdictAvoidBg, AppColors.warmSandDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: result.verdict == Verdict.good
                        ? AppColors.verdictGood.withValues(alpha: 0.35)
                        : result.verdict == Verdict.limit
                        ? AppColors.verdictLimit.withValues(alpha: 0.45)
                        : AppColors.verdictAvoid.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            (result.verdict == Verdict.good
                                    ? AppColors.verdictGood
                                    : result.verdict == Verdict.limit
                                    ? AppColors.verdictLimit
                                    : AppColors.verdictAvoid)
                                .withValues(alpha: 0.15),
                      ),
                    ),
                    Icon(
                      result.verdict == Verdict.good
                          ? Icons.eco_rounded
                          : result.verdict == Verdict.limit
                          ? Icons.restaurant_rounded
                          : Icons.no_food_rounded,
                      size: 50,
                      color: result.verdict == Verdict.good
                          ? AppColors.verdictGood
                          : result.verdict == Verdict.limit
                          ? AppColors.verdictLimit
                          : AppColors.verdictAvoid,
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1, 1),
                duration: 400.ms,
              ),
          const SizedBox(height: 24),

          // ── Verdict Badge ──
          VerdictBadge(verdict: result.verdict)
              .animate()
              .scale(
                begin: const Offset(0.3, 0.3),
                end: const Offset(1, 1),
                duration: 600.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 300.ms),
          const SizedBox(height: 24),

          // ── Food Name ──
          Text(
            result.food,
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
          const SizedBox(height: 16),

          // ── Summary ──
          Text(
            result.summary,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.mutedPlum,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
          const SizedBox(height: 20),

          // ── Relevant Conditions ──
          if (result.relevantConditions.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: result.relevantConditions.map((c) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warmSandDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    c,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedPlum,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

          // ── Portion Tip ──
          if (result.portionTip != null) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.tealSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.deepTeal,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result.portionTip!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.deepTealDark,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
          ],

          // ── Alternatives ──
          if (result.alternatives.isNotEmpty) ...[
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Try these instead',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: result.alternatives.map((alt) {
                return ActionChip(
                  avatar: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: Text(alt),
                  backgroundColor: AppColors.verdictGoodBg,
                  side: const BorderSide(
                    color: AppColors.verdictGood,
                    width: 0.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onPressed: () {
                    try {
                      ref.read(foodSearchProvider.notifier).searchFood(alt);
                      context.pushReplacement(
                        '/result/${Uri.encodeComponent(alt)}',
                      );
                    } catch (e, st) {
                      logScreenError(
                        'ResultScreen',
                        'Failed to open alternative "$alt"',
                        e,
                        st,
                      );
                    }
                  },
                );
              }).toList(),
            ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
          ],

          // ── Decision Response ──
          if (_showDecisionResponse && _decisionMessage != null) ...[
            const SizedBox(height: 24),
            Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.verdictGoodBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.verdictGood.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _decisionMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.verdictGood,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.2, end: 0, duration: 400.ms),
          ],

          // ── Decision Buttons ──
          if (!_showDecisionResponse) ...[
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _onWillEat(result),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.verdictLimit,
                      side: const BorderSide(
                        color: AppColors.verdictLimit,
                        width: 1.5,
                      ),
                      minimumSize: const Size(0, 54),
                    ),
                    child: const Text('I\'ll still eat'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _onWontEat(result),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.verdictGood,
                      minimumSize: const Size(0, 54),
                    ),
                    child: const Text('No, I won\'t eat'),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms, delay: 700.ms),
          ],

          // ── Report Button ──
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () => _showReportSheet(result),
            icon: const Icon(Icons.flag_outlined, size: 16),
            label: const Text('Report this result'),
            style: TextButton.styleFrom(foregroundColor: AppColors.textLight),
          ).animate().fadeIn(duration: 400.ms, delay: 800.ms),

          // ── Disclaimer ──
          const SizedBox(height: 16),
          const DisclaimerBanner(),
        ],
      ),
    );
  }
}
