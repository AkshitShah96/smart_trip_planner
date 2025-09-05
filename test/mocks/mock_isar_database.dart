import 'package:isar/isar.dart';
import 'package:smart_trip_planner/data/models/itinerary.dart';
import 'package:smart_trip_planner/data/models/day_plan.dart';
import 'package:smart_trip_planner/data/models/day_item.dart';

class MockIsarDatabase {
  static Isar? _isar;

  static Future<Isar> get instance async {
    if (_isar != null) {
      return _isar!;
    }

    _isar = await Isar.open(
      [
        ItinerarySchema,
        DayPlanSchema,
        DayItemSchema,
      ],
      directory: '',
      name: 'test_${DateTime.now().millisecondsSinceEpoch}',
      inspector: false,
    );

    return _isar!;
  }

  static Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }

  static Future<void> clear() async {
    if (_isar != null) {
      await _isar!.writeTxn(() async {
        await _isar!.itineraries.clear();
        await _isar!.dayPlans.clear();
        await _isar!.dayItems.clear();
      });
    }
  }
}

















