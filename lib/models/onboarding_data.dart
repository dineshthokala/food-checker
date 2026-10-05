/// Onboarding state persisted across the multi-step flow.
class OnboardingData {
  final int currentStep;
  final List<String> conditions;
  final double? heightCm;
  final double? weightKg;
  final int? age;
  final String? gender;
  final String? ethnicity;
  final String? bloodGroup;
  final String? dietType;
  final List<String> allergies;
  final List<String> medications;
  final bool consentGiven;
  final bool privacyAccepted;

  const OnboardingData({
    this.currentStep = 0,
    this.conditions = const [],
    this.heightCm,
    this.weightKg,
    this.age,
    this.gender,
    this.ethnicity,
    this.bloodGroup,
    this.dietType,
    this.allergies = const [],
    this.medications = const [],
    this.consentGiven = false,
    this.privacyAccepted = false,
  });

  static const int totalSteps = 4;

  bool get canProceedFromStep {
    switch (currentStep) {
      case 0:
        return conditions.isNotEmpty;
      case 1:
        return age != null && gender != null;
      case 2:
        return true; // diet/allergies/meds are optional
      case 3:
        return consentGiven && privacyAccepted;
      default:
        return false;
    }
  }

  OnboardingData copyWith({
    int? currentStep,
    List<String>? conditions,
    double? heightCm,
    double? weightKg,
    int? age,
    String? gender,
    String? ethnicity,
    String? bloodGroup,
    String? dietType,
    List<String>? allergies,
    List<String>? medications,
    bool? consentGiven,
    bool? privacyAccepted,
  }) {
    return OnboardingData(
      currentStep: currentStep ?? this.currentStep,
      conditions: conditions ?? this.conditions,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      ethnicity: ethnicity ?? this.ethnicity,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      dietType: dietType ?? this.dietType,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      consentGiven: consentGiven ?? this.consentGiven,
      privacyAccepted: privacyAccepted ?? this.privacyAccepted,
    );
  }
}
