import 'package:flutter_test/flutter_test.dart';
import 'package:foodchecker/models/user_profile.dart';

void main() {
  group('UserProfile Model', () {
    test('computes BMI and BMI category correctly', () {
      final profile = UserProfile(
        id: 'usr-1',
        displayName: 'John Doe',
        email: 'john@example.com',
        heightCm: 175.0,
        weightKg: 70.0,
        createdAt: DateTime.now(),
      );

      // BMI = 70 / (1.75 * 1.75) = 22.857...
      expect(profile.bmi, isNotNull);
      expect(profile.bmi!, closeTo(22.86, 0.05));
      expect(profile.bmiCategory, 'Normal');
    });

    test('categorizes underweight, overweight, and obese accurately', () {
      final underweight = UserProfile(
        id: 'u1',
        displayName: 'A',
        email: 'a@a.com',
        heightCm: 180,
        weightKg: 55, // BMI ~ 17.0
        createdAt: DateTime.now(),
      );
      expect(underweight.bmiCategory, 'Underweight');

      final overweight = UserProfile(
        id: 'u2',
        displayName: 'B',
        email: 'b@b.com',
        heightCm: 170,
        weightKg: 80, // BMI ~ 27.68
        createdAt: DateTime.now(),
      );
      expect(overweight.bmiCategory, 'Overweight');

      final obese = UserProfile(
        id: 'u3',
        displayName: 'C',
        email: 'c@c.com',
        heightCm: 160,
        weightKg: 95, // BMI ~ 37.1
        createdAt: DateTime.now(),
      );
      expect(obese.bmiCategory, 'Obese');
    });

    test('handles missing or zero height/weight gracefully', () {
      final noMetrics = UserProfile(
        id: 'u4',
        displayName: 'D',
        email: 'd@d.com',
        createdAt: DateTime.now(),
      );
      expect(noMetrics.bmi, isNull);
      expect(noMetrics.bmiCategory, isNull);

      final zeroHeight = UserProfile(
        id: 'u5',
        displayName: 'E',
        email: 'e@e.com',
        heightCm: 0,
        weightKg: 70,
        createdAt: DateTime.now(),
      );
      expect(zeroHeight.bmi, isNull);
      expect(zeroHeight.bmiCategory, isNull);
    });

    test('toJson and fromJson work seamlessly', () {
      final profile = UserProfile(
        id: 'u-100',
        displayName: 'Jane Doe',
        email: 'jane@example.com',
        age: 32,
        gender: 'female',
        heightCm: 165,
        weightKg: 60,
        ethnicity: 'South Asian',
        bloodGroup: 'O+',
        dietType: 'Vegetarian',
        conditions: ['Type 2 Diabetes', 'Hypertension'],
        allergies: ['Peanuts'],
        medications: ['Metformin'],
        onboardingComplete: true,
        createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );

      final json = profile.toJson();
      expect(json['id'], 'u-100');
      expect(json['conditions'], contains('Type 2 Diabetes'));
      expect(json['allergies'], contains('Peanuts'));
      expect(json['medications'], contains('Metformin'));

      final fromJson = UserProfile.fromJson(json);
      expect(fromJson.id, 'u-100');
      expect(fromJson.displayName, 'Jane Doe');
      expect(fromJson.age, 32);
      expect(fromJson.dietType, 'Vegetarian');
      expect(fromJson.conditions.length, 2);
      expect(fromJson.onboardingComplete, isTrue);
    });

    test('copyWith produces updated clone without mutating originals', () {
      final original = UserProfile(
        id: 'u-1',
        displayName: 'Initial',
        email: 'init@test.com',
        conditions: ['Asthma'],
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(
        displayName: 'Updated Name',
        conditions: ['Asthma', 'Hypertension'],
        onboardingComplete: true,
      );

      expect(updated.displayName, 'Updated Name');
      expect(updated.conditions.length, 2);
      expect(updated.onboardingComplete, isTrue);
      expect(original.displayName, 'Initial');
      expect(original.conditions.length, 1);
    });
  });
}
