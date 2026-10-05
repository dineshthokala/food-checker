/// Verdict for a food item relative to the user's conditions.
enum Verdict { good, limit, avoid }

/// The result of checking a food item against user conditions.
class FoodResult {
  final String food;
  final Verdict verdict;
  final String summary;
  final String? portionTip;
  final List<String> alternatives;
  final List<String> relevantConditions;
  final String disclaimer;

  const FoodResult({
    required this.food,
    required this.verdict,
    required this.summary,
    this.portionTip,
    this.alternatives = const [],
    this.relevantConditions = const [],
    this.disclaimer =
        'This is general guidance, not medical advice. Always consult your doctor or dietitian.',
  });

  Map<String, dynamic> toJson() => {
    'food': food,
    'verdict': verdict.name,
    'summary': summary,
    'portion_tip': portionTip,
    'alternatives': alternatives,
    'relevant_conditions': relevantConditions,
    'disclaimer': disclaimer,
  };

  factory FoodResult.fromJson(Map<String, dynamic> json) {
    return FoodResult(
      food: json['food'] as String? ?? '',
      verdict: Verdict.values.firstWhere(
        (v) => v.name.toLowerCase() == (json['verdict'] as String? ?? '').toLowerCase(),
        orElse: () => Verdict.good,
      ),
      summary: json['summary'] as String? ?? '',
      portionTip: json['portion_tip'] as String? ?? json['portionTip'] as String?,
      alternatives: (json['alternatives'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      relevantConditions: (json['relevant_conditions'] as List? ?? json['relevantConditions'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      disclaimer: json['disclaimer'] as String? ?? 'This is general guidance, not medical advice. Always consult your doctor or dietitian.',
    );
  }
}

/// A logged food decision (will eat / won't eat).
class FoodDecision {
  final String id;
  final String food;
  final Verdict verdict;
  final String decision; // 'will_eat' or 'wont_eat'
  final List<String> conditionsSnapshot;
  final DateTime timestamp;

  const FoodDecision({
    required this.id,
    required this.food,
    required this.verdict,
    required this.decision,
    required this.conditionsSnapshot,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'food': food,
    'verdict': verdict.name,
    'decision': decision,
    'conditions_snapshot': conditionsSnapshot,
    'timestamp': timestamp.toIso8601String(),
  };

  factory FoodDecision.fromJson(Map<String, dynamic> json) => FoodDecision(
    id: json['id'] as String? ?? '',
    food: json['food'] as String? ?? '',
    verdict: Verdict.values.firstWhere(
      (v) => v.name.toLowerCase() == (json['verdict'] as String? ?? '').toLowerCase(),
      orElse: () => Verdict.good,
    ),
    decision: json['decision'] as String? ?? 'will_eat',
    conditionsSnapshot: (json['conditions_snapshot'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    timestamp: json['timestamp'] != null
        ? DateTime.parse(json['timestamp'] as String)
        : DateTime.now(),
  );
}

/// A food report submitted by the user.
class FoodReport {
  final String food;
  final String reportType; // false_positive, false_negative, incorrect_info, other
  final String? comment;
  final Map<String, dynamic> verdictSnapshot;
  final DateTime timestamp;

  const FoodReport({
    required this.food,
    required this.reportType,
    this.comment,
    required this.verdictSnapshot,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'food': food,
    'report_type': reportType,
    'comment': comment,
    'verdict_snapshot': verdictSnapshot,
    'timestamp': timestamp.toIso8601String(),
  };

  factory FoodReport.fromJson(Map<String, dynamic> json) => FoodReport(
    food: json['food'] as String? ?? '',
    reportType: json['report_type'] as String? ?? 'other',
    comment: json['comment'] as String?,
    verdictSnapshot: json['verdict_snapshot'] as Map<String, dynamic>? ?? const {},
    timestamp: json['timestamp'] != null
        ? DateTime.parse(json['timestamp'] as String)
        : DateTime.now(),
  );
}

/// A saved "safe food" item.
class SafeFood {
  final String food;
  final Verdict verdict;
  final DateTime addedAt;

  const SafeFood({
    required this.food,
    required this.verdict,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
    'food': food,
    'verdict': verdict.name,
    'added_at': addedAt.toIso8601String(),
  };

  factory SafeFood.fromJson(Map<String, dynamic> json) => SafeFood(
    food: json['food'] as String,
    verdict: Verdict.values.firstWhere(
      (v) => v.name == json['verdict'],
      orElse: () => Verdict.good,
    ),
    addedAt: DateTime.parse(json['added_at'] as String),
  );
}
