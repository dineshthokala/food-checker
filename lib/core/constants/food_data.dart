/// All food items for local autocomplete search, plus category data.
class FoodData {
  FoodData._();

  static const Map<String, List<String>> categories = {
    'Fruits': [
      'Apple', 'Banana', 'Orange', 'Mango', 'Grapes', 'Strawberry',
      'Blueberry', 'Watermelon', 'Papaya', 'Pineapple', 'Pomegranate',
      'Guava', 'Avocado', 'Kiwi', 'Peach', 'Plum', 'Cherry', 'Lemon',
      'Coconut', 'Lychee', 'Dates', 'Fig',
    ],
    'Vegetables': [
      'Spinach', 'Broccoli', 'Carrot', 'Tomato', 'Onion', 'Garlic',
      'Potato', 'Sweet Potato', 'Cauliflower', 'Cabbage', 'Bell Pepper',
      'Cucumber', 'Beetroot', 'Eggplant', 'Zucchini', 'Mushroom',
      'Pumpkin', 'Okra', 'Green Beans', 'Asparagus', 'Lettuce', 'Kale',
    ],
    'Grains': [
      'White Rice', 'Brown Rice', 'Wheat Bread', 'Oats', 'Quinoa',
      'Barley', 'Millet', 'Corn', 'Pasta', 'Noodles', 'Roti',
      'Couscous', 'White Bread', 'Sourdough',
    ],
    'Dairy': [
      'Milk', 'Yogurt', 'Cheese', 'Paneer', 'Butter', 'Ghee',
      'Cream', 'Cottage Cheese', 'Ice Cream', 'Whey Protein',
    ],
    'Meat & Poultry': [
      'Chicken Breast', 'Red Meat', 'Lamb', 'Pork', 'Turkey',
      'Eggs', 'Bacon', 'Sausage', 'Liver',
    ],
    'Seafood': [
      'Salmon', 'Tuna', 'Shrimp', 'Mackerel', 'Sardines', 'Cod',
      'Crab', 'Tilapia', 'Prawns', 'Oysters',
    ],
    'Legumes': [
      'Lentils', 'Chickpeas', 'Black Beans', 'Kidney Beans',
      'Soybeans', 'Tofu', 'Green Peas', 'Peanuts', 'Edamame',
    ],
    'Nuts & Seeds': [
      'Almonds', 'Walnuts', 'Cashews', 'Pistachios', 'Flaxseed',
      'Chia Seeds', 'Sunflower Seeds', 'Pumpkin Seeds', 'Hazelnuts',
    ],
    'Beverages': [
      'Green Tea', 'Coffee', 'Black Tea', 'Orange Juice',
      'Coconut Water', 'Kombucha', 'Soda', 'Energy Drink',
      'Alcohol / Beer', 'Wine',
    ],
    'Others': [
      'Honey', 'Jaggery', 'Dark Chocolate', 'Sugar',
      'Olive Oil', 'Coconut Oil', 'Pickle', 'Chips', 'Cake',
      'Fried Foods', 'Turmeric', 'Ginger', 'Cinnamon',
    ],
  };

  /// Flat list of all foods, sorted alphabetically.
  static List<String> get allFoods {
    final foods = <String>[];
    for (final list in categories.values) {
      foods.addAll(list);
    }
    foods.sort();
    return foods;
  }

  static const List<String> quickCategories = [
    'Fruits',
    'Vegetables',
    'Grains',
    'Dairy',
    'Meat & Poultry',
    'Seafood',
    'Legumes',
    'Nuts & Seeds',
  ];

  static const Map<String, String> categoryIcons = {
    'Fruits': '🍎',
    'Vegetables': '🥬',
    'Grains': '🌾',
    'Dairy': '🥛',
    'Meat & Poultry': '🍗',
    'Seafood': '🐟',
    'Legumes': '🫘',
    'Nuts & Seeds': '🥜',
    'Beverages': '🍵',
    'Others': '🧂',
  };
}
