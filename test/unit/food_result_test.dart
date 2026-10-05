import 'package:flutter_test/flutter_test.dart';
import 'package:foodchecker/models/food_result.dart';

void main() {
  group('FoodResult Serialization & Deserialization', () {
    test('serializes to and from standard JSON properly', () {
      const result = FoodResult(
        food: 'White Rice',
        verdict: Verdict.limit,
        summary: 'High glycemic index, moderation is advised for diabetes.',
        portionTip: 'Limit to 1/2 cup cooked with added fiber.',
        alternatives: ['Brown rice', 'Quinoa', 'Cauliflower rice'],
        relevantConditions: ['Type 2 Diabetes'],
      );

      final json = result.toJson();
      expect(json['food'], 'White Rice');
      expect(json['verdict'], 'limit');
      expect(json['portion_tip'], 'Limit to 1/2 cup cooked with added fiber.');
      expect(json['alternatives'], contains('Brown rice'));
      expect(json['relevant_conditions'], contains('Type 2 Diabetes'));

      final fromJson = FoodResult.fromJson(json);
      expect(fromJson.food, 'White Rice');
      expect(fromJson.verdict, Verdict.limit);
      expect(fromJson.portionTip, 'Limit to 1/2 cup cooked with added fiber.');
      expect(fromJson.alternatives.length, 3);
      expect(fromJson.relevantConditions, contains('Type 2 Diabetes'));
    });

    test('handles legacy and camelCase JSON keys gracefully', () {
      final legacyJson = {
        'food': 'Oatmeal',
        'verdict': 'GOOD',
        'summary': 'Rich in soluble fiber.',
        'portionTip': '1 cup cooked with berries.',
        'relevantConditions': ['High Cholesterol'],
      };

      final result = FoodResult.fromJson(legacyJson);
      expect(result.food, 'Oatmeal');
      expect(result.verdict, Verdict.good);
      expect(result.portionTip, '1 cup cooked with berries.');
      expect(result.relevantConditions, contains('High Cholesterol'));
      expect(result.alternatives, isEmpty);
    });

    test('falls back to default verdict on unknown verdict string', () {
      final json = {
        'food': 'Unknown Food',
        'verdict': 'invalid_verdict_key',
        'summary': 'Some summary',
      };

      final result = FoodResult.fromJson(json);
      expect(result.verdict, Verdict.good);
      expect(result.disclaimer, contains('medical advice'));
    });
  });

  group('FoodDecision Model', () {
    test('toJson and fromJson work correctly', () {
      final decision = FoodDecision(
        id: 'dec-123',
        food: 'Dark Chocolate',
        verdict: Verdict.good,
        decision: 'will_eat',
        conditionsSnapshot: ['Hypertension'],
        timestamp: DateTime.parse('2026-10-04T12:00:00.000Z'),
      );

      final json = decision.toJson();
      expect(json['id'], 'dec-123');
      expect(json['food'], 'Dark Chocolate');
      expect(json['verdict'], 'good');
      expect(json['decision'], 'will_eat');

      final fromJson = FoodDecision.fromJson(json);
      expect(fromJson.id, 'dec-123');
      expect(fromJson.food, 'Dark Chocolate');
      expect(fromJson.verdict, Verdict.good);
      expect(fromJson.decision, 'will_eat');
      expect(fromJson.conditionsSnapshot, contains('Hypertension'));
    });
  });

  group('FoodReport Model', () {
    test('toJson and fromJson work correctly', () {
      final report = FoodReport(
        food: 'Almond Milk',
        reportType: 'false_positive',
        comment: 'Unsweetened almond milk is actually safe for me.',
        verdictSnapshot: {'verdict': 'limit'},
        timestamp: DateTime.parse('2026-10-04T12:00:00.000Z'),
      );

      final json = report.toJson();
      expect(json['food'], 'Almond Milk');
      expect(json['report_type'], 'false_positive');
      expect(json['comment'], 'Unsweetened almond milk is actually safe for me.');

      final fromJson = FoodReport.fromJson(json);
      expect(fromJson.food, 'Almond Milk');
      expect(fromJson.reportType, 'false_positive');
      expect(fromJson.comment, contains('Unsweetened almond milk'));
    });
  });

  group('SafeFood Model', () {
    test('toJson and fromJson work correctly', () {
      final safeFood = SafeFood(
        food: 'Spinach',
        verdict: Verdict.good,
        addedAt: DateTime.parse('2026-10-04T10:00:00.000Z'),
      );

      final json = safeFood.toJson();
      expect(json['food'], 'Spinach');
      expect(json['verdict'], 'good');

      final fromJson = SafeFood.fromJson(json);
      expect(fromJson.food, 'Spinach');
      expect(fromJson.verdict, Verdict.good);
      expect(fromJson.addedAt.year, 2026);
    });
  });
}
