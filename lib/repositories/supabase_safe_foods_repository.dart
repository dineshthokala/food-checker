import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/logger.dart';
import '../core/utils/offline_db.dart';
import '../models/food_result.dart';

abstract class SafeFoodsRepository {
  Future<List<SafeFood>> getSavedFoods();
  Future<void> addFood(String food, Verdict verdict);
  Future<void> removeFood(String food);
  Future<void> syncOfflineCache();
}

class SupabaseSafeFoodsRepository implements SafeFoodsRepository {
  final SupabaseClient _supabase;

  SupabaseSafeFoodsRepository(this._supabase);

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  Future<List<SafeFood>> getSavedFoods() async {
    final userId = _uid;
    if (userId == null) {
      return _loadFromHive();
    }

    try {
      final data = await _supabase
          .from('saved_foods')
          .select('food, verdict, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final list = (data as List).map((row) {
        return SafeFood(
          food: row['food'] as String,
          verdict: Verdict.values.firstWhere(
            (v) => v.name == row['verdict'],
            orElse: () => Verdict.good,
          ),
          addedAt: DateTime.parse(row['created_at'] as String),
        );
      }).toList();

      // Update Hive cache
      await _saveToHive(list);
      return list;
    } catch (e, st) {
      talker.handle(e, st, 'Failed to fetch saved foods from Supabase, falling back to Hive');
      return _loadFromHive();
    }
  }

  @override
  Future<void> addFood(String food, Verdict verdict) async {
    final userId = _uid;
    final safeFood = SafeFood(food: food, verdict: verdict, addedAt: DateTime.now());

    // Update local Hive immediately for responsive UI
    final currentList = _loadFromHive();
    if (!currentList.any((s) => s.food.toLowerCase() == food.toLowerCase())) {
      currentList.insert(0, safeFood);
      await _saveToHive(currentList);
    }

    // Persist to Supabase if authenticated
    if (userId != null) {
      try {
        await _supabase.from('saved_foods').upsert({
          'user_id': userId,
          'food': food,
          'verdict': verdict.name,
        }, onConflict: 'user_id, food');
        talker.info('Saved food to Supabase: $food ($verdict)');
      } catch (e, st) {
        talker.handle(e, st, 'Failed to upsert saved food to Supabase');
      }
    }
  }

  @override
  Future<void> removeFood(String food) async {
    final userId = _uid;

    // Remove from local Hive
    final currentList = _loadFromHive();
    currentList.removeWhere((s) => s.food.toLowerCase() == food.toLowerCase());
    await _saveToHive(currentList);

    // Delete from Supabase if authenticated
    if (userId != null) {
      try {
        await _supabase
            .from('saved_foods')
            .delete()
            .eq('user_id', userId)
            .eq('food', food);
        talker.info('Deleted food from Supabase: $food');
      } catch (e, st) {
        talker.handle(e, st, 'Failed to delete saved food from Supabase');
      }
    }
  }

  @override
  Future<void> syncOfflineCache() async {
    await getSavedFoods();
  }

  List<SafeFood> _loadFromHive() {
    try {
      final box = Hive.box<String>(OfflineDB.safeFoodsBoxName);
      return box.values
          .map((e) => SafeFood.fromJson(jsonDecode(e) as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      talker.handle(e, st, 'Failed to read safe foods box from Hive');
      return [];
    }
  }

  Future<void> _saveToHive(List<SafeFood> list) async {
    try {
      final box = Hive.box<String>(OfflineDB.safeFoodsBoxName);
      await box.clear();
      final map = {
        for (var i = 0; i < list.length; i++) i: jsonEncode(list[i].toJson())
      };
      await box.putAll(map);
    } catch (e, st) {
      talker.handle(e, st, 'Failed to write safe foods to Hive');
    }
  }
}

final safeFoodsRepositoryProvider = Provider<SafeFoodsRepository>((ref) {
  return SupabaseSafeFoodsRepository(Supabase.instance.client);
});
