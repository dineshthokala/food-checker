import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/logger.dart';
import '../models/food_result.dart';
import 'food_repository.dart';

class SupabaseFoodRepository implements FoodRepository {
  final SupabaseClient _supabase;
  final FoodRepository _fallback;

  SupabaseFoodRepository(this._supabase, {FoodRepository? fallback})
      : _fallback = fallback ?? MockFoodRepository();

  @override
  Future<FoodResult> checkFood(
    String food,
    List<String> conditions, {
    List<String>? allergies,
    List<String>? medications,
    String? dietType,
    String? ethnicity,
  }) async {
    try {
      talker.info('Calling check-food Edge Function for "$food"...');
      
      final response = await _supabase.functions
          .invoke(
            'check-food',
            body: {
              'food': food,
              'conditions': conditions,
              'allergies': allergies ?? [],
              'medications': medications ?? [],
              'diet_type': dietType,
              'ethnicity': ethnicity,
            },
          )
          .timeout(const Duration(seconds: 12));

      if (response.status == 200 && response.data != null) {
        final Map<String, dynamic> data =
            Map<String, dynamic>.from(response.data as Map);
        talker.info('Received food evaluation for "$food": ${data['verdict']} (source: ${data['source'] ?? 'unknown'})');
        return FoodResult.fromJson(data);
      } else {
        talker.warning(
          'Edge function returned status ${response.status}. Falling back to local rule engine.',
        );
      }
    } catch (e, st) {
      talker.handle(
        e,
        st,
        'Failed to evaluate food via Edge Function. Using offline rule-engine fallback.',
      );
    }

    // Seamless offline/error fallback
    return _fallback.checkFood(
      food,
      conditions,
      allergies: allergies,
      medications: medications,
    );
  }
}
