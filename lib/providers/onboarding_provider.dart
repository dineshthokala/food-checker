import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/onboarding_data.dart';

class OnboardingNotifier extends StateNotifier<OnboardingData> {
  OnboardingNotifier() : super(const OnboardingData());

  void goToStep(int step) {
    if (step >= 0 && step < OnboardingData.totalSteps) {
      state = state.copyWith(currentStep: step);
    }
  }

  void nextStep() {
    if (state.currentStep < OnboardingData.totalSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  // ── Step 1: Conditions ──
  void toggleCondition(String condition) {
    final conditions = List<String>.from(state.conditions);
    if (conditions.contains(condition)) {
      conditions.remove(condition);
    } else {
      conditions.add(condition);
    }
    state = state.copyWith(conditions: conditions);
  }

  // ── Step 2: Body & Personal ──
  void setHeight(double? cm) => state = state.copyWith(heightCm: cm);
  void setWeight(double? kg) => state = state.copyWith(weightKg: kg);
  void setAge(int? age) => state = state.copyWith(age: age);
  void setGender(String? gender) => state = state.copyWith(gender: gender);
  void setEthnicity(String? ethnicity) => state = state.copyWith(ethnicity: ethnicity);
  void setBloodGroup(String? bloodGroup) => state = state.copyWith(bloodGroup: bloodGroup);

  // ── Step 3: Diet, Allergies, Medications ──
  void setDietType(String? type) => state = state.copyWith(dietType: type);

  void toggleAllergy(String allergy) {
    final allergies = List<String>.from(state.allergies);
    if (allergies.contains(allergy)) {
      allergies.remove(allergy);
    } else {
      allergies.add(allergy);
    }
    state = state.copyWith(allergies: allergies);
  }

  void toggleMedication(String medication) {
    final medications = List<String>.from(state.medications);
    if (medications.contains(medication)) {
      medications.remove(medication);
    } else {
      medications.add(medication);
    }
    state = state.copyWith(medications: medications);
  }

  // ── Step 4: Consent ──
  void setConsent(bool value) => state = state.copyWith(consentGiven: value);
  void setPrivacy(bool value) => state = state.copyWith(privacyAccepted: value);

  void reset() => state = const OnboardingData();
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingData>((ref) {
  return OnboardingNotifier();
});
