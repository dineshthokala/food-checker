import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/logger.dart';
import '../core/utils/offline_db.dart';
import '../models/food_result.dart';

abstract class FoodDecisionRepository {
  Future<void> logDecision({
    required String food,
    required Verdict verdict,
    required String decision,
    required List<String> conditions,
  });
  Future<List<FoodDecision>> getDecisions();
}

class SupabaseFoodDecisionRepository implements FoodDecisionRepository {
  final SupabaseClient _supabase;

  SupabaseFoodDecisionRepository(this._supabase);

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  Future<void> logDecision({
    required String food,
    required Verdict verdict,
    required String decision,
    required List<String> conditions,
  }) async {
    final userId = _uid;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final item = FoodDecision(
      id: id,
      food: food,
      verdict: verdict,
      decision: decision,
      conditionsSnapshot: conditions,
      timestamp: DateTime.now(),
    );

    // Save locally in Hive
    try {
      final box = Hive.box<String>(OfflineDB.foodDecisionsBoxName);
      final existing = box.values.toList();
      existing.insert(0, jsonEncode(item.toJson()));
      if (existing.length > 100) existing.removeLast();

      await box.clear();
      final map = {for (var i = 0; i < existing.length; i++) i: existing[i]};
      await box.putAll(map);
      talker.info('Logged food decision locally: $food -> $decision');
    } catch (e, st) {
      talker.handle(e, st, 'Failed to save food decision locally');
    }

    // Persist to Supabase if authenticated
    if (userId != null) {
      try {
        await _supabase.from('food_decisions').insert({
          'user_id': userId,
          'food': food,
          'verdict': verdict.name,
          'decision': decision,
          'conditions_snapshot': conditions,
        });
        talker.info('Persisted food decision to Supabase');
      } catch (e, st) {
        talker.handle(e, st, 'Failed to insert food decision into Supabase');
      }
    }
  }

  @override
  Future<List<FoodDecision>> getDecisions() async {
    final userId = _uid;
    if (userId == null) {
      return _loadFromHive();
    }

    try {
      final data = await _supabase
          .from('food_decisions')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(100);

      return (data as List).map((row) {
        return FoodDecision(
          id: row['id'] as String,
          food: row['food'] as String,
          verdict: Verdict.values.firstWhere(
            (v) => v.name == row['verdict'],
            orElse: () => Verdict.good,
          ),
          decision: row['decision'] as String,
          conditionsSnapshot: (row['conditions_snapshot'] as List?)
                  ?.map((c) => c.toString())
                  .toList() ??
              [],
          timestamp: DateTime.parse(row['created_at'] as String),
        );
      }).toList();
    } catch (e, st) {
      talker.handle(e, st, 'Failed to fetch food decisions from Supabase');
      return _loadFromHive();
    }
  }

  List<FoodDecision> _loadFromHive() {
    try {
      final box = Hive.box<String>(OfflineDB.foodDecisionsBoxName);
      return box.values.map((raw) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        return FoodDecision(
          id: json['id'] ?? '',
          food: json['food'] ?? '',
          verdict: Verdict.values.firstWhere(
            (v) => v.name == json['verdict'],
            orElse: () => Verdict.good,
          ),
          decision: json['decision'] ?? '',
          conditionsSnapshot: (json['conditions_snapshot'] as List?)
                  ?.map((c) => c.toString())
                  .toList() ??
              [],
          timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}

final foodDecisionRepositoryProvider = Provider<FoodDecisionRepository>((ref) {
  return SupabaseFoodDecisionRepository(Supabase.instance.client);
});
