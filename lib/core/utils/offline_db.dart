import 'package:hive_flutter/hive_flutter.dart';
import 'logger.dart';

class OfflineDB {
  static const String safeFoodsBoxName = 'safe_foods';
  static const String recentSearchesBoxName = 'recent_searches';
  static const String foodDecisionsBoxName = 'food_decisions';
  static const String foodReportsBoxName = 'food_reports';

  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      
      // Open all necessary boxes
      await Hive.openBox<String>(safeFoodsBoxName);
      await Hive.openBox<String>(recentSearchesBoxName);
      await Hive.openBox<String>(foodDecisionsBoxName);
      await Hive.openBox<String>(foodReportsBoxName);
      
      talker.info('Hive initialized and boxes opened successfully.');
    } catch (e, st) {
      talker.handle(e, st, 'Failed to initialize Hive Offline DB');
    }
  }
}
