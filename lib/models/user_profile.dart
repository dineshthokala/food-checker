/// User profile model with all health and personal data.
class UserProfile {
  final String id;
  final String displayName;
  final String email;
  final int? age;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final String? ethnicity;
  final String? bloodGroup;
  final String? dietType;
  final List<String> conditions;
  final List<String> allergies;
  final List<String> medications;
  final bool onboardingComplete;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.ethnicity,
    this.bloodGroup,
    this.dietType,
    this.conditions = const [],
    this.allergies = const [],
    this.medications = const [],
    this.onboardingComplete = false,
    required this.createdAt,
  });

  double? get bmi {
    if (heightCm == null || weightKg == null || heightCm == 0) return null;
    final heightM = heightCm! / 100;
    return weightKg! / (heightM * heightM);
  }

  String? get bmiCategory {
    final b = bmi;
    if (b == null) return null;
    if (b < 18.5) return 'Underweight';
    if (b < 25) return 'Normal';
    if (b < 30) return 'Overweight';
    return 'Obese';
  }

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? email,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    String? ethnicity,
    String? bloodGroup,
    String? dietType,
    List<String>? conditions,
    List<String>? allergies,
    List<String>? medications,
    bool? onboardingComplete,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      ethnicity: ethnicity ?? this.ethnicity,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      dietType: dietType ?? this.dietType,
      conditions: conditions ?? this.conditions,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'display_name': displayName,
    'email': email,
    'age': age,
    'gender': gender,
    'height_cm': heightCm,
    'weight_kg': weightKg,
    'ethnicity': ethnicity,
    'blood_group': bloodGroup,
    'diet_type': dietType,
    'conditions': conditions,
    'allergies': allergies,
    'medications': medications,
    'onboarding_complete': onboardingComplete,
    'created_at': createdAt.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    displayName: json['display_name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    age: json['age'] as int?,
    gender: json['gender'] as String?,
    heightCm: (json['height_cm'] as num?)?.toDouble(),
    weightKg: (json['weight_kg'] as num?)?.toDouble(),
    ethnicity: json['ethnicity'] as String?,
    bloodGroup: json['blood_group'] as String?,
    dietType: json['diet_type'] as String?,
    conditions: (json['conditions'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ?? [],
    allergies: (json['allergies'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ?? [],
    medications: (json['medications'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ?? [],
    onboardingComplete: json['onboarding_complete'] as bool? ?? false,
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : DateTime.now(),
  );
}
