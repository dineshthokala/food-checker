import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_result.dart';
import 'supabase_food_repository.dart';

/// Abstract food repository.
abstract class FoodRepository {
  Future<FoodResult> checkFood(
    String food,
    List<String> conditions, {
    List<String>? allergies,
    List<String>? medications,
    String? dietType,
    String? ethnicity,
  });
}

/// Rule-based mock that simulates AI food-checking for common scenarios.
class MockFoodRepository implements FoodRepository {
  // Tag-based food properties for the rule engine.
  static const Map<String, Set<String>> _foodTags = {
    'white rice': {'high_glycemic', 'refined', 'grain', 'gluten_free'},
    'brown rice': {'low_glycemic', 'high_fiber', 'grain', 'gluten_free'},
    'banana': {'high_potassium', 'moderate_sugar', 'fruit', 'high_fiber'},
    'apple': {'low_glycemic', 'high_fiber', 'fruit'},
    'orange': {'acidic', 'high_vitamin_c', 'fruit', 'moderate_sugar'},
    'mango': {'high_glycemic', 'high_sugar', 'fruit'},
    'grapes': {'high_sugar', 'fruit'},
    'watermelon': {'high_glycemic', 'fruit'},
    'avocado': {'healthy_fat', 'high_potassium', 'low_glycemic', 'fruit'},
    'spinach': {'high_oxalate', 'high_iron', 'high_vitamin_k', 'vegetable'},
    'broccoli': {'cruciferous', 'high_fiber', 'vegetable'},
    'carrot': {'low_glycemic', 'high_fiber', 'vegetable'},
    'tomato': {'acidic', 'high_potassium', 'vegetable'},
    'potato': {'high_glycemic', 'high_potassium', 'vegetable'},
    'sweet potato': {'moderate_glycemic', 'high_fiber', 'high_potassium', 'vegetable'},
    'garlic': {'anti_inflammatory', 'vegetable'},
    'onion': {'anti_inflammatory', 'vegetable'},
    'beetroot': {'high_oxalate', 'high_sugar', 'vegetable'},
    'mushroom': {'high_purine', 'vegetable'},
    'cauliflower': {'cruciferous', 'low_glycemic', 'vegetable'},
    'kale': {'cruciferous', 'high_vitamin_k', 'high_oxalate', 'vegetable'},
    'red meat': {'high_purine', 'high_saturated_fat', 'high_protein', 'high_iron', 'meat'},
    'chicken breast': {'lean_protein', 'low_fat', 'meat'},
    'lamb': {'high_purine', 'high_saturated_fat', 'meat'},
    'pork': {'high_saturated_fat', 'meat'},
    'eggs': {'high_protein', 'high_cholesterol', 'dairy_adjacent'},
    'salmon': {'omega_3', 'high_protein', 'seafood'},
    'tuna': {'high_protein', 'high_mercury', 'seafood'},
    'shrimp': {'high_cholesterol', 'high_purine', 'seafood'},
    'mackerel': {'omega_3', 'high_purine', 'seafood'},
    'sardines': {'omega_3', 'high_purine', 'high_calcium', 'seafood'},
    'milk': {'lactose', 'high_calcium', 'high_phosphorus', 'dairy'},
    'yogurt': {'lactose', 'probiotic', 'high_calcium', 'dairy'},
    'cheese': {'lactose', 'high_sodium', 'high_saturated_fat', 'high_calcium', 'dairy'},
    'paneer': {'lactose', 'high_protein', 'dairy'},
    'butter': {'high_saturated_fat', 'dairy'},
    'ghee': {'high_saturated_fat', 'dairy', 'lactose_free'},
    'oats': {'high_fiber', 'low_glycemic', 'grain'},
    'quinoa': {'high_fiber', 'high_protein', 'grain', 'gluten_free'},
    'wheat bread': {'gluten', 'moderate_glycemic', 'grain'},
    'white bread': {'gluten', 'high_glycemic', 'refined', 'grain'},
    'pasta': {'gluten', 'high_glycemic', 'refined', 'grain'},
    'lentils': {'high_fiber', 'high_protein', 'high_potassium', 'legume'},
    'chickpeas': {'high_fiber', 'high_protein', 'legume'},
    'kidney beans': {'high_fiber', 'high_potassium', 'high_purine', 'legume'},
    'soybeans': {'high_protein', 'phytoestrogen', 'legume'},
    'tofu': {'high_protein', 'low_fat', 'legume'},
    'peanuts': {'high_fat', 'nut', 'common_allergen'},
    'almonds': {'healthy_fat', 'high_fiber', 'high_calcium', 'nut'},
    'walnuts': {'omega_3', 'healthy_fat', 'nut'},
    'cashews': {'high_fat', 'nut'},
    'green tea': {'antioxidant', 'caffeine', 'beverage'},
    'coffee': {'caffeine', 'acidic', 'beverage'},
    'alcohol / beer': {'alcohol', 'high_purine', 'high_sugar', 'beverage'},
    'wine': {'alcohol', 'acidic', 'beverage'},
    'soda': {'high_sugar', 'acidic', 'beverage'},
    'honey': {'high_sugar', 'natural_sugar'},
    'dark chocolate': {'antioxidant', 'moderate_sugar', 'caffeine'},
    'sugar': {'high_sugar', 'refined'},
    'olive oil': {'healthy_fat', 'anti_inflammatory'},
    'coconut oil': {'high_saturated_fat'},
    'fried foods': {'high_saturated_fat', 'high_sodium', 'refined'},
    'chips': {'high_sodium', 'high_saturated_fat', 'refined'},
    'cake': {'high_sugar', 'high_saturated_fat', 'gluten', 'refined'},
    'turmeric': {'anti_inflammatory', 'spice'},
    'ginger': {'anti_inflammatory', 'spice'},
    'cinnamon': {'anti_inflammatory', 'blood_sugar_friendly', 'spice'},
    'dates': {'high_sugar', 'high_fiber', 'high_potassium', 'fruit'},
    'coconut water': {'high_potassium', 'natural_sugar', 'beverage'},
    'ice cream': {'high_sugar', 'high_saturated_fat', 'lactose', 'dairy'},
    'bacon': {'high_sodium', 'high_saturated_fat', 'processed_meat'},
    'sausage': {'high_sodium', 'high_saturated_fat', 'processed_meat'},
    'liver': {'high_iron', 'high_purine', 'high_vitamin_a', 'meat'},
    'pickle': {'high_sodium', 'acidic'},
  };

  // Rules: condition → tag → verdict effect
  static const Map<String, Map<String, Verdict>> _conditionRules = {
    'Type 2 Diabetes': {
      'high_glycemic': Verdict.limit,
      'high_sugar': Verdict.limit,
      'refined': Verdict.limit,
      'high_fiber': Verdict.good,
      'low_glycemic': Verdict.good,
      'blood_sugar_friendly': Verdict.good,
      'alcohol': Verdict.avoid,
    },
    'Type 1 Diabetes': {
      'high_glycemic': Verdict.limit,
      'high_sugar': Verdict.limit,
      'refined': Verdict.limit,
      'alcohol': Verdict.avoid,
    },
    'Hypertension': {
      'high_sodium': Verdict.avoid,
      'high_potassium': Verdict.good,
      'alcohol': Verdict.avoid,
      'processed_meat': Verdict.avoid,
      'caffeine': Verdict.limit,
    },
    'High Cholesterol': {
      'high_saturated_fat': Verdict.limit,
      'high_cholesterol': Verdict.limit,
      'omega_3': Verdict.good,
      'healthy_fat': Verdict.good,
      'high_fiber': Verdict.good,
      'processed_meat': Verdict.avoid,
    },
    'Chronic Kidney Disease': {
      'high_potassium': Verdict.limit,
      'high_phosphorus': Verdict.limit,
      'high_protein': Verdict.limit,
      'high_sodium': Verdict.avoid,
      'high_oxalate': Verdict.limit,
    },
    'Gout': {
      'high_purine': Verdict.avoid,
      'alcohol': Verdict.avoid,
      'high_sugar': Verdict.limit,
    },
    'Heart Disease': {
      'high_saturated_fat': Verdict.limit,
      'high_sodium': Verdict.avoid,
      'omega_3': Verdict.good,
      'high_fiber': Verdict.good,
      'processed_meat': Verdict.avoid,
      'alcohol': Verdict.limit,
    },
    'GERD / Acid Reflux': {
      'acidic': Verdict.limit,
      'caffeine': Verdict.limit,
      'high_saturated_fat': Verdict.limit,
      'alcohol': Verdict.avoid,
      'spice': Verdict.limit,
    },
    'Celiac Disease': {
      'gluten': Verdict.avoid,
      'gluten_free': Verdict.good,
    },
    'Hypothyroidism': {
      'cruciferous': Verdict.limit,
      'high_fiber': Verdict.good,
    },
    'Fatty Liver (NAFLD)': {
      'high_sugar': Verdict.avoid,
      'refined': Verdict.limit,
      'alcohol': Verdict.avoid,
      'high_saturated_fat': Verdict.limit,
      'high_fiber': Verdict.good,
      'omega_3': Verdict.good,
    },
    'Lactose Intolerance': {
      'lactose': Verdict.avoid,
      'lactose_free': Verdict.good,
    },
    'Anemia': {
      'high_iron': Verdict.good,
      'high_vitamin_c': Verdict.good,
    },
    'IBS': {
      'high_fiber': Verdict.limit,
      'lactose': Verdict.limit,
      'caffeine': Verdict.limit,
      'alcohol': Verdict.avoid,
    },
  };

  // Medication interactions
  static const Map<String, Map<String, Verdict>> _medicationRules = {
    'Blood Thinners (Warfarin)': {
      'high_vitamin_k': Verdict.limit,
    },
  };

  // Alternative suggestions
  static const Map<String, List<String>> _alternatives = {
    'white rice': ['Brown Rice', 'Quinoa', 'Cauliflower Rice'],
    'white bread': ['Whole Wheat Bread', 'Oats', 'Sourdough'],
    'potato': ['Sweet Potato', 'Cauliflower'],
    'red meat': ['Chicken Breast', 'Salmon', 'Tofu', 'Lentils'],
    'soda': ['Green Tea', 'Coconut Water', 'Sparkling Water'],
    'sugar': ['Cinnamon', 'Stevia', 'Small amount of Honey'],
    'milk': ['Almond Milk', 'Oat Milk', 'Lactose-free Milk'],
    'cheese': ['Paneer (small portion)', 'Cottage Cheese'],
    'pasta': ['Quinoa', 'Zucchini Noodles', 'Brown Rice Noodles'],
    'fried foods': ['Grilled or Baked options', 'Air-fried alternatives'],
    'ice cream': ['Frozen Yogurt', 'Banana Nice Cream'],
    'chips': ['Roasted Nuts', 'Baked Vegetable Chips'],
    'cake': ['Dark Chocolate (small piece)', 'Fresh Fruit'],
    'bacon': ['Turkey Bacon', 'Grilled Chicken'],
    'butter': ['Olive Oil', 'Ghee (small amount)'],
    'coffee': ['Green Tea', 'Herbal Tea'],
    'alcohol / beer': ['Kombucha', 'Sparkling Water with Lime'],
    'wine': ['Grape Juice (small)', 'Sparkling Water'],
  };

  @override
  Future<FoodResult> checkFood(
    String food,
    List<String> conditions, {
    List<String>? allergies,
    List<String>? medications,
    String? dietType,
    String? ethnicity,
  }) async {
    final effectiveAllergies = allergies ?? const [];
    final effectiveMedications = medications ?? const [];
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    final normalizedFood = food.toLowerCase().trim();
    final tags = _foodTags[normalizedFood] ?? <String>{};

    // Collect all triggered rules
    var worstVerdict = Verdict.good;
    final reasons = <String>[];
    final matchedConditions = <String>[];

    // Check condition rules
    for (final condition in conditions) {
      final rules = _conditionRules[condition];
      if (rules == null) continue;

      for (final entry in rules.entries) {
        if (tags.contains(entry.key)) {
          matchedConditions.add(condition);
          if (entry.value.index > worstVerdict.index) {
            worstVerdict = entry.value;
          }
          reasons.add(_buildReason(condition, entry.key, entry.value));
        }
      }
    }

    // Check medication rules
    for (final med in effectiveMedications) {
      final rules = _medicationRules[med];
      if (rules == null) continue;
      for (final entry in rules.entries) {
        if (tags.contains(entry.key)) {
          if (entry.value.index > worstVerdict.index) {
            worstVerdict = entry.value;
          }
          reasons.add('$med users should be mindful of ${_tagLabel(entry.key)} content.');
        }
      }
    }

    // Check allergies
    for (final allergy in effectiveAllergies) {
      final allergyTag = _allergyToTag(allergy);
      if (tags.contains(allergyTag)) {
        worstVerdict = Verdict.avoid;
        reasons.add('Contains $allergy, which you\'re allergic to.');
        matchedConditions.add('Allergy: $allergy');
      }
    }

    // Build summary
    String summary;
    if (tags.isEmpty) {
      summary = '${_capitalize(food)} appears to be compatible with your profile. '
          'We don\'t have detailed nutritional rules for this item yet — '
          'check with your dietitian for specific guidance.';
      worstVerdict = Verdict.good;
    } else if (reasons.isEmpty) {
      summary = '${_capitalize(food)} is generally considered safe for your conditions. '
          'It provides beneficial nutrients without conflicting with your health needs.';
    } else {
      final uniqueReasons = reasons.toSet().take(3).toList();
      summary = uniqueReasons.join(' ');
    }

    // Portion tip
    String? portionTip;
    if (worstVerdict == Verdict.limit) {
      portionTip = 'A small portion (about half your usual serving) is generally fine. '
          'Pair it with fiber-rich foods to balance the impact.';
    } else if (worstVerdict == Verdict.avoid) {
      portionTip = 'Consider skipping this one. If you do have it occasionally, '
          'keep the portion very small and monitor how you feel.';
    }

    return FoodResult(
      food: food,
      verdict: worstVerdict,
      summary: summary,
      portionTip: portionTip,
      alternatives: _alternatives[normalizedFood] ?? [],
      relevantConditions: matchedConditions.toSet().toList(),
    );
  }

  String _buildReason(String condition, String tag, Verdict verdict) {
    final action = verdict == Verdict.avoid ? 'avoid' : 'limit';
    return 'With $condition, it\'s generally advised to $action foods '
        '${_tagExplanation(tag)}.';
  }

  String _tagLabel(String tag) {
    return tag.replaceAll('_', ' ');
  }

  String _tagExplanation(String tag) {
    switch (tag) {
      case 'high_glycemic': return 'with a high glycemic index';
      case 'high_sugar': return 'high in sugar';
      case 'high_sodium': return 'high in sodium';
      case 'high_purine': return 'high in purines';
      case 'high_saturated_fat': return 'high in saturated fat';
      case 'high_potassium': return 'high in potassium';
      case 'high_phosphorus': return 'high in phosphorus';
      case 'high_protein': return 'very high in protein';
      case 'high_cholesterol': return 'high in dietary cholesterol';
      case 'high_oxalate': return 'high in oxalates';
      case 'high_vitamin_k': return 'high in vitamin K';
      case 'acidic': return 'that are acidic';
      case 'caffeine': return 'containing caffeine';
      case 'alcohol': return 'containing alcohol';
      case 'gluten': return 'containing gluten';
      case 'lactose': return 'containing lactose';
      case 'refined': return 'that are highly refined';
      case 'cruciferous': return 'from the cruciferous family (in large amounts)';
      case 'processed_meat': return 'that are processed meats';
      default: return 'with this nutritional profile';
    }
  }

  String _allergyToTag(String allergy) {
    switch (allergy) {
      case 'Milk / Dairy': return 'dairy';
      case 'Wheat / Gluten': return 'gluten';
      case 'Peanuts': return 'common_allergen';
      case 'Soy': return 'legume';
      case 'Fish': return 'seafood';
      case 'Shellfish': return 'seafood';
      default: return '';
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }
}

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return SupabaseFoodRepository(
    Supabase.instance.client,
    fallback: MockFoodRepository(),
  );
});
