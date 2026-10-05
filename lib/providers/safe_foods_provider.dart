import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_result.dart';
import '../repositories/supabase_safe_foods_repository.dart';

class SafeFoodsNotifier extends StateNotifier<List<SafeFood>> {
  final SafeFoodsRepository _repository;

  SafeFoodsNotifier(this._repository) : super([]) {
    load();
  }

  Future<void> load() async {
    final list = await _repository.getSavedFoods();
    state = list;
  }

  Future<void> addFood(String food, Verdict verdict) async {
    if (state.any((s) => s.food.toLowerCase() == food.toLowerCase())) return;

    final sf = SafeFood(food: food, verdict: verdict, addedAt: DateTime.now());
    state = [sf, ...state];
    await _repository.addFood(food, verdict);
  }

  Future<void> removeFood(String food) async {
    state = state.where((s) => s.food.toLowerCase() != food.toLowerCase()).toList();
    await _repository.removeFood(food);
  }

  bool isSaved(String food) {
    return state.any((s) => s.food.toLowerCase() == food.toLowerCase());
  }
}

final safeFoodsProvider =
    StateNotifierProvider<SafeFoodsNotifier, List<SafeFood>>((ref) {
  final repo = ref.watch(safeFoodsRepositoryProvider);
  return SafeFoodsNotifier(repo);
});

