import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/food_result.dart';
import '../repositories/food_repository.dart';
import '../core/utils/offline_db.dart';
import '../core/utils/logger.dart';
import 'auth_provider.dart';
import '../repositories/supabase_food_decision_repository.dart';
import '../repositories/supabase_food_report_repository.dart';

/// State for the food search + result flow.
class FoodSearchState {
  final String query;
  final List<String> suggestions;
  final FoodResult? result;
  final bool isLoading;
  final String? error;
  final List<String> recentSearches;

  const FoodSearchState({
    this.query = '',
    this.suggestions = const [],
    this.result,
    this.isLoading = false,
    this.error,
    this.recentSearches = const [],
  });

  FoodSearchState copyWith({
    String? query,
    List<String>? suggestions,
    FoodResult? result,
    bool? isLoading,
    String? error,
    List<String>? recentSearches,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return FoodSearchState(
      query: query ?? this.query,
      suggestions: suggestions ?? this.suggestions,
      result: clearResult ? null : (result ?? this.result),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }
}

class FoodSearchNotifier extends StateNotifier<FoodSearchState> {
  final FoodRepository _repo;
  final Ref _ref;
  Timer? _debounce;

  FoodSearchNotifier(this._repo, this._ref) : super(const FoodSearchState()) {
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final box = Hive.box<String>(OfflineDB.recentSearchesBoxName);
      final list = box.values.toList();
      state = state.copyWith(recentSearches: list);
      talker.info('Loaded ${list.length} recent searches from Hive');
    } catch (e, st) {
      talker.handle(e, st, 'Failed to load recent searches');
    }
  }

  Future<void> _saveRecentSearch(String food) async {
    final list = List<String>.from(state.recentSearches);
    list.remove(food);
    list.insert(0, food);
    if (list.length > 10) list.removeLast();
    
    try {
      final box = Hive.box<String>(OfflineDB.recentSearchesBoxName);
      await box.clear();
      final map = {for (var i = 0; i < list.length; i++) i: list[i]};
      await box.putAll(map);
      state = state.copyWith(recentSearches: list);
    } catch (e, st) {
      talker.handle(e, st, 'Failed to save recent searches');
    }
  }

  void updateQuery(String query) {
    state = state.copyWith(query: query, clearError: true);
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      state = state.copyWith(suggestions: []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _updateSuggestions(query);
    });
  }

  void _updateSuggestions(String query) {
    final q = query.toLowerCase();
    final allFoods = <String>[];
    // Import food data inline to avoid circular deps
    const categories = {
      'Fruits': ['Apple', 'Banana', 'Orange', 'Mango', 'Grapes', 'Strawberry',
        'Blueberry', 'Watermelon', 'Papaya', 'Pineapple', 'Pomegranate',
        'Guava', 'Avocado', 'Kiwi', 'Peach', 'Plum', 'Cherry', 'Lemon',
        'Coconut', 'Lychee', 'Dates', 'Fig'],
      'Vegetables': ['Spinach', 'Broccoli', 'Carrot', 'Tomato', 'Onion', 'Garlic',
        'Potato', 'Sweet Potato', 'Cauliflower', 'Cabbage', 'Bell Pepper',
        'Cucumber', 'Beetroot', 'Eggplant', 'Zucchini', 'Mushroom',
        'Pumpkin', 'Okra', 'Green Beans', 'Asparagus', 'Lettuce', 'Kale'],
      'Grains': ['White Rice', 'Brown Rice', 'Wheat Bread', 'Oats', 'Quinoa',
        'Barley', 'Millet', 'Corn', 'Pasta', 'Noodles', 'Roti',
        'Couscous', 'White Bread', 'Sourdough'],
      'Dairy': ['Milk', 'Yogurt', 'Cheese', 'Paneer', 'Butter', 'Ghee',
        'Cream', 'Cottage Cheese', 'Ice Cream', 'Whey Protein'],
      'Meat': ['Chicken Breast', 'Red Meat', 'Lamb', 'Pork', 'Turkey',
        'Eggs', 'Bacon', 'Sausage', 'Liver'],
      'Seafood': ['Salmon', 'Tuna', 'Shrimp', 'Mackerel', 'Sardines', 'Cod',
        'Crab', 'Tilapia', 'Prawns', 'Oysters'],
      'Legumes': ['Lentils', 'Chickpeas', 'Black Beans', 'Kidney Beans',
        'Soybeans', 'Tofu', 'Green Peas', 'Peanuts', 'Edamame'],
      'Nuts': ['Almonds', 'Walnuts', 'Cashews', 'Pistachios', 'Flaxseed',
        'Chia Seeds', 'Sunflower Seeds', 'Pumpkin Seeds', 'Hazelnuts'],
      'Beverages': ['Green Tea', 'Coffee', 'Black Tea', 'Orange Juice',
        'Coconut Water', 'Kombucha', 'Soda', 'Energy Drink',
        'Alcohol / Beer', 'Wine'],
      'Others': ['Honey', 'Jaggery', 'Dark Chocolate', 'Sugar',
        'Olive Oil', 'Coconut Oil', 'Pickle', 'Chips', 'Cake',
        'Fried Foods', 'Turmeric', 'Ginger', 'Cinnamon'],
    };
    for (final list in categories.values) {
      allFoods.addAll(list);
    }
    final matches = allFoods
        .where((f) => f.toLowerCase().contains(q))
        .take(8)
        .toList();
    state = state.copyWith(suggestions: matches);
  }

  Future<void> searchFood(String food) async {
    state = state.copyWith(
      query: food,
      isLoading: true,
      clearError: true,
      clearResult: true,
      suggestions: [],
    );

    try {
      final authState = _ref.read(authProvider);
      final conditions = authState.user?.conditions ?? [];
      final allergies = authState.user?.allergies ?? [];
      final medications = authState.user?.medications ?? [];
      final dietType = authState.user?.dietType;
      final ethnicity = authState.user?.ethnicity;

      final result = await _repo.checkFood(
        food,
        conditions,
        allergies: allergies,
        medications: medications,
        dietType: dietType,
        ethnicity: ethnicity,
      );
      state = state.copyWith(result: result, isLoading: false);
      await _saveRecentSearch(food);
    } catch (e) {
      state = state.copyWith(
        error: 'Something went wrong. Please try again.',
        isLoading: false,
      );
    }
  }

  void clearResult() {
    state = state.copyWith(clearResult: true, query: '');
  }

  void clearRecentSearch(String food) async {
    final list = List<String>.from(state.recentSearches)..remove(food);
    try {
      final box = Hive.box<String>(OfflineDB.recentSearchesBoxName);
      await box.clear();
      final map = {for (var i = 0; i < list.length; i++) i: list[i]};
      await box.putAll(map);
      state = state.copyWith(recentSearches: list);
    } catch (e, st) {
      talker.handle(e, st, 'Failed to clear recent search');
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final foodSearchProvider =
    StateNotifierProvider<FoodSearchNotifier, FoodSearchState>((ref) {
  return FoodSearchNotifier(
    ref.read(foodRepositoryProvider),
    ref,
  );
});

/// Logs a food decision (will_eat / wont_eat) to Supabase & local cache.
final foodDecisionLogProvider = Provider<FoodDecisionLogger>((ref) {
  final repo = ref.watch(foodDecisionRepositoryProvider);
  return FoodDecisionLogger(repo);
});

class FoodDecisionLogger {
  final FoodDecisionRepository _repo;
  FoodDecisionLogger(this._repo);

  Future<void> log({
    required String food,
    required String verdict,
    required String decision,
    required List<String> conditions,
  }) async {
    final v = Verdict.values.firstWhere(
      (val) => val.name == verdict,
      orElse: () => Verdict.good,
    );
    await _repo.logDecision(
      food: food,
      verdict: v,
      decision: decision,
      conditions: conditions,
    );
  }
}

/// Logs a food report to Supabase & local cache.
final foodReportProvider = Provider<FoodReportLogger>((ref) {
  final repo = ref.watch(foodReportRepositoryProvider);
  return FoodReportLogger(repo);
});

class FoodReportLogger {
  final FoodReportRepository _repo;
  FoodReportLogger(this._repo);

  Future<void> report({
    required String food,
    required String reportType,
    String? comment,
    required Map<String, dynamic> verdictSnapshot,
  }) async {
    await _repo.submitReport(
      food: food,
      reportType: reportType,
      comment: comment,
      verdictSnapshot: verdictSnapshot,
    );
  }
}
