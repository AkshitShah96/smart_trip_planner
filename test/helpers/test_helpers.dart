import 'package:isar/isar.dart';
import 'package:smart_trip_planner/data/models/itinerary.dart';
import 'package:smart_trip_planner/data/models/day_plan.dart';
import 'package:smart_trip_planner/data/models/day_item.dart';

class TestHelpers {
  static Future<Isar> createTestIsar() async {
    return await Isar.open(
      [
        ItinerarySchema,
        DayPlanSchema,
        DayItemSchema,
      ],
      directory: '',
      name: 'test_${DateTime.now().millisecondsSinceEpoch}',
      inspector: false,
    );
  }

  static Future<void> clearTestIsar(Isar isar) async {
    await isar.writeTxn(() async {
      await isar.itineraries.clear();
      await isar.dayPlans.clear();
      await isar.dayItems.clear();
    });
  }

  static Future<void> closeTestIsar(Isar isar) async {
    await isar.close();
  }
}


















