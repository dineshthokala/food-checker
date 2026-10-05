import 'package:flutter_test/flutter_test.dart';
import 'package:foodchecker/models/food_result.dart';
import 'package:foodchecker/repositories/food_repository.dart';

void main() {
  late MockFoodRepository repo;

  setUp(() {
    repo = MockFoodRepository();
  });

  group('MockFoodRepository Rule Engine', () {
    test('returns GOOD for healthy neutral foods with no conflicting conditions', () async {
      final result = await repo.checkFood('Apple', ['Type 2 Diabetes']);
      expect(result.verdict, Verdict.good);
      expect(result.summary, isNotEmpty);
    });

    test('returns LIMIT or AVOID for high glycemic items with Type 2 Diabetes', () async {
      final result = await repo.checkFood('White Rice', ['Type 2 Diabetes']);
      expect(result.verdict, anyOf(Verdict.limit, Verdict.avoid));
      expect(result.relevantConditions, contains('Type 2 Diabetes'));
      expect(result.alternatives, isNotEmpty);
    });

    test('returns AVOID for high sodium foods with Hypertension', () async {
      final result = await repo.checkFood('Bacon', ['Hypertension']);
      expect(result.verdict, Verdict.avoid);
      expect(result.relevantConditions, contains('Hypertension'));
    });

    test('returns AVOID for gluten-containing foods with Celiac Disease', () async {
      final result = await repo.checkFood('White Bread', ['Celiac Disease']);
      expect(result.verdict, Verdict.avoid);
      expect(result.relevantConditions, contains('Celiac Disease'));
    });

    test('returns AVOID for allergens matched in user allergies', () async {
      final result = await repo.checkFood(
        'Peanuts',
        [],
        allergies: ['Peanuts'],
      );
      expect(result.verdict, Verdict.avoid);
      expect(result.summary.toLowerCase(), contains('allergic'));
    });

    test('detects medication interactions e.g. Warfarin and high Vitamin K', () async {
      final result = await repo.checkFood(
        'Spinach',
        [],
        medications: ['Blood Thinners (Warfarin)'],
      );
      expect(result.verdict, Verdict.limit);
      expect(result.summary.toLowerCase(), contains('vitamin k'));
    });

    test('handles unknown foods gracefully with safe defaults', () async {
      final result = await repo.checkFood(
        'Exotic Dragonfruit Dish',
        ['Type 2 Diabetes'],
      );
      expect(result.verdict, Verdict.good);
      expect(result.summary, isNotEmpty);
      expect(result.disclaimer, contains('medical advice'));
    });
  });
}
