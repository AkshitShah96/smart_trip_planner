import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/day_item.dart';
import '../../data/models/day_plan.dart';
import '../../data/models/itinerary.dart';

class IsarDatabase {
  static Isar? _isar;

  static Future<Isar> get instance async {
    if (_isar != null) {
      return _isar!;
    }

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      schemas: [
        ItinerarySchema,
        DayPlanSchema,
        DayItemSchema,
      ],
      directory: dir.path,
    );

    return _isar!;
  }

  static Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}




