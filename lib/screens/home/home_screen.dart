import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/food_data.dart';
import '../../core/utils/logger.dart';
import '../../providers/auth_provider.dart';
import '../../providers/food_search_provider.dart';
import '../../providers/safe_foods_provider.dart';
import '../../widgets/disclaimer_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _showSuggestions = false;

  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _scanKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    ShowcaseView.register();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkShowcase());
  }

  Future<void> _checkShowcase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasShown = prefs.getBool('has_shown_showcase') ?? false;
      if (!hasShown && mounted) {
        ShowcaseView.get().startShowCase([_searchKey, _scanKey]);
        await prefs.setBool('has_shown_showcase', true);
      }
    } catch (e, st) {
      logScreenError('HomeScreen', 'Failed to show onboarding showcase', e, st);
    }
  }

  @override
  void dispose() {
    try {
      ShowcaseView.get().unregister();
    } catch (_) {}
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch(String food) {
    if (food.trim().isEmpty) return;
    try {
      _searchController.clear();
      _focusNode.unfocus();
      setState(() => _showSuggestions = false);
      ref.read(foodSearchProvider.notifier).searchFood(food);
      context.push('/result/${Uri.encodeComponent(food)}');
    } catch (e, st) {
      logScreenError('HomeScreen', 'Failed to search for "$food"', e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Log food-search failures with screen context (fires once per new error).
    ref.listen(foodSearchProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        logScreenError('HomeScreen', 'Food search failed', next.error!);
      }
    });
    final authState = ref.watch(authProvider);
    final searchState = ref.watch(foodSearchProvider);
    final safeFoods = ref.watch(safeFoodsProvider);
    final userName = authState.user?.displayName ?? 'there';

    return Scaffold(
      backgroundColor: AppColors.warmSand,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            _focusNode.unfocus();
            setState(() => _showSuggestions = false);
          },
          child: CustomScrollView(
            slivers: [
              // ── Header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $userName',
                                style: Theme.of(context).textTheme.headlineLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'What are you thinking of eating?',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.mutedPlum,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => context.go('/profile'),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.tealSurface,
                              child: Text(
                                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: AppColors.deepTeal,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 400.ms),
                      const SizedBox(height: 28),

                      // ── Search Bar ──
                      Showcase(
                        key: _searchKey,
                        description: 'Search for any food or ingredient here to check if it\'s safe for you.',
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cardShadow,
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                          controller: _searchController,
                          focusNode: _focusNode,
                          onChanged: (v) {
                            ref.read(foodSearchProvider.notifier).updateQuery(v);
                            setState(() => _showSuggestions = v.isNotEmpty);
                          },
                          onSubmitted: _onSearch,
                          decoration: InputDecoration(
                            hintText: 'Search any food...',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.deepTeal,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 20),
                                    onPressed: () {
                                      _searchController.clear();
                                      ref.read(foodSearchProvider.notifier).updateQuery('');
                                      setState(() => _showSuggestions = false);
                                    },
                                  )
                                : Showcase(
                                    key: _scanKey,
                                    description: 'Or scan a food barcode directly!',
                                    child: IconButton(
                                      icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.deepTeal),
                                       onPressed: () async {
                                         try {
                                           final result = await context.push<String?>('/scanner');
                                           if (result != null) {
                                             _onSearch(result);
                                           }
                                         } catch (e, st) {
                                           logScreenError('HomeScreen', 'Scanner navigation failed', e, st);
                                         }
                                       },
                                    ),
                                  ),
                            filled: true,
                            fillColor: AppColors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.deepTeal,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                    ],
                  ),
                ),
              ),

              // ── Suggestions Dropdown ──
              if (_showSuggestions && searchState.suggestions.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: searchState.suggestions.map((food) {
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.restaurant_rounded,
                              size: 18,
                              color: AppColors.mutedPlum,
                            ),
                            title: Text(
                              food,
                              style: const TextStyle(fontSize: 14),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            onTap: () => _onSearch(food),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

              // ── Quick Categories ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Browse by category',
                        style: Theme.of(context).textTheme.titleLarge,
                      ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: FoodData.quickCategories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final cat = FoodData.quickCategories[index];
                            final emoji = FoodData.categoryIcons[cat] ?? '🍽️';
                            return ActionChip(
                              avatar: Text(emoji, style: const TextStyle(fontSize: 16)),
                              label: Text(cat),
                              backgroundColor: AppColors.white,
                              side: const BorderSide(color: AppColors.divider),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onPressed: () {
                                // Show foods in category
                                _showCategoryFoods(context, cat);
                              },
                            );
                          },
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                    ],
                  ),
                ),
              ),

              // ── Recent Searches ──
              if (searchState.recentSearches.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent searches',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        ...searchState.recentSearches.take(5).map((food) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(14),
                              child: ListTile(
                                dense: true,
                                leading: const Icon(
                                  Icons.history_rounded,
                                  size: 18,
                                  color: AppColors.textLight,
                                ),
                                title: Text(
                                  food,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 16),
                                  color: AppColors.textLight,
                                  onPressed: () {
                                    ref.read(foodSearchProvider.notifier)
                                        .clearRecentSearch(food);
                                  },
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                onTap: () => _onSearch(food),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

              // ── Safe Foods Preview ──
              if (safeFoods.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'My safe foods',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            TextButton(
                              onPressed: () => context.go('/safe-foods'),
                              child: const Text('See all'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: safeFoods.take(6).map((sf) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.verdictGoodBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 16,
                                    color: AppColors.verdictGood,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    sf.food,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.verdictGood,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Disclaimer ──
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: DisclaimerBanner(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryFoods(BuildContext context, String category) {
    try {
      final foods = FoodData.categories[category] ?? [];
      showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
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
                '${FoodData.categoryIcons[category] ?? ""} $category',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: foods.map((food) {
                  return ActionChip(
                    label: Text(food),
                    backgroundColor: AppColors.cardBg,
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _onSearch(food);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
    } catch (e, st) {
      logScreenError('HomeScreen', 'Failed to show category "$category"', e, st);
    }
  }
}
