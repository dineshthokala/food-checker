import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/logger.dart';
import '../core/utils/offline_db.dart';
import '../models/food_result.dart';

abstract class FoodReportRepository {
  Future<void> submitReport({
    required String food,
    required String reportType,
    String? comment,
    required Map<String, dynamic> verdictSnapshot,
  });
}

class SupabaseFoodReportRepository implements FoodReportRepository {
  final SupabaseClient _supabase;

  SupabaseFoodReportRepository(this._supabase);

  @override
  Future<void> submitReport({
    required String food,
    required String reportType,
    String? comment,
    required Map<String, dynamic> verdictSnapshot,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final report = FoodReport(
      food: food,
      reportType: reportType,
      comment: comment,
      verdictSnapshot: verdictSnapshot,
      timestamp: DateTime.now(),
    );

    // Save locally
    try {
      final box = Hive.box<String>(OfflineDB.foodReportsBoxName);
      final existing = box.values.toList();
      existing.insert(0, jsonEncode(report.toJson()));
      await box.clear();
      final map = {for (var i = 0; i < existing.length; i++) i: existing[i]};
      await box.putAll(map);
    } catch (e, st) {
      talker.handle(e, st, 'Failed to save food report locally');
    }

    // Persist to Supabase if authenticated
    if (userId != null) {
      try {
        await _supabase.from('food_reports').insert({
          'user_id': userId,
          'food': food,
          'report_type': reportType,
          'comment': comment,
          'verdict_snapshot': verdictSnapshot,
        });
        talker.info('Submitted food report to Supabase for $food');
      } catch (e, st) {
        talker.handle(e, st, 'Failed to submit food report to Supabase');
      }
    }
  }
}

final foodReportRepositoryProvider = Provider<FoodReportRepository>((ref) {
  return SupabaseFoodReportRepository(Supabase.instance.client);
});
