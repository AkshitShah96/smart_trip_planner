import 'package:isar/isar.dart';
import '../../domain/entities/itinerary.dart';
import '../../domain/entities/day_plan.dart';
import '../../domain/entities/day_item.dart';
import '../../domain/repositories/itinerary_repository.dart';
// TODO: Uncomment after running build_runner
// import '../models/itinerary.dart' as data_model;
// import '../models/day_plan.dart' as data_model;
// import '../models/day_item.dart' as data_model;
// TODO: Uncomment after running build_runner
// import '../../core/database/isar_database.dart';

class ItineraryRepositoryImpl implements ItineraryRepository {
  // Temporary storage until Isar is properly set up
  static final List<Itinerary> _temporaryStorage = [];

  @override
  Future<void> saveItinerary(Itinerary itinerary) async {
    // TODO: Replace with Isar implementation after running build_runner
    _temporaryStorage.add(itinerary);
    
    // Uncomment this after generating Isar schema files:
    /*
    final isar = await IsarDatabase.instance;
    
    // Convert domain entities to data models
    final itineraryModel = data_model.Itinerary(
      title: itinerary.title,
      startDate: itinerary.startDate,
      endDate: itinerary.endDate,
    );

    await isar.writeTxn(() async {
      // Save itinerary
      await isar.itineraries.put(itineraryModel);
      
      // Save days and items
      for (final day in itinerary.days) {
        final dayModel = data_model.DayPlan(
          date: day.date,
          summary: day.summary,
        );
        
        await isar.dayPlans.put(dayModel);
        itineraryModel.days.add(dayModel);
        
        // Save items for this day
        for (final item in day.items) {
          final itemModel = data_model.DayItem(
            time: item.time,
            activity: item.activity,
            location: item.location,
          );
          
          await isar.dayItems.put(itemModel);
          dayModel.items.add(itemModel);
        }
      }
      
      // Update itinerary with days
      await isar.itineraries.put(itineraryModel);
    });
    */
  }

  @override
  Future<List<Itinerary>> getAllItineraries() async {
    // TODO: Replace with Isar implementation after running build_runner
    return List.from(_temporaryStorage);
    
    // Uncomment this after generating Isar schema files:
    /*
    final isar = await IsarDatabase.instance;
    
    final itineraryModels = await isar.itineraries
        .where()
        .sortByTitle()
        .findAll();

    final itineraries = <Itinerary>[];

    for (final itineraryModel in itineraryModels) {
      // Load days for this itinerary
      final dayModels = await itineraryModel.days.load();
      final days = <DayPlan>[];

      for (final dayModel in dayModels) {
        // Load items for this day
        final itemModels = await dayModel.items.load();
        final items = itemModels.map((itemModel) => DayItem(
          id: itemModel.id,
          time: itemModel.time,
          activity: itemModel.activity,
          location: itemModel.location,
        )).toList();

        days.add(DayPlan(
          id: dayModel.id,
          date: dayModel.date,
          summary: dayModel.summary,
          items: items,
        ));
      }

      itineraries.add(Itinerary(
        id: itineraryModel.id,
        title: itineraryModel.title,
        startDate: itineraryModel.startDate,
        endDate: itineraryModel.endDate,
        days: days,
      ));
    }

    return itineraries;
    */
  }

  @override
  Future<Itinerary?> getItineraryById(int id) async {
    // TODO: Replace with Isar implementation after running build_runner
    try {
      return _temporaryStorage.firstWhere((itinerary) => itinerary.id == id);
    } catch (e) {
      return null;
    }
    
    // Uncomment this after generating Isar schema files:
    /*
    final isar = await IsarDatabase.instance;
    
    final itineraryModel = await isar.itineraries.get(id);
    if (itineraryModel == null) return null;

    // Load days for this itinerary
    final dayModels = await itineraryModel.days.load();
    final days = <DayPlan>[];

    for (final dayModel in dayModels) {
      // Load items for this day
      final itemModels = await dayModel.items.load();
      final items = itemModels.map((itemModel) => DayItem(
        id: itemModel.id,
        time: itemModel.time,
        activity: itemModel.activity,
        location: itemModel.location,
      )).toList();

      days.add(DayPlan(
        id: dayModel.id,
        date: dayModel.date,
        summary: dayModel.summary,
        items: items,
      ));
    }

    return Itinerary(
      id: itineraryModel.id,
      title: itineraryModel.title,
      startDate: itineraryModel.startDate,
      endDate: itineraryModel.endDate,
      days: days,
    );
    */
  }

  @override
  Future<void> deleteItinerary(int id) async {
    // TODO: Replace with Isar implementation after running build_runner
    _temporaryStorage.removeWhere((itinerary) => itinerary.id == id);
    
    // Uncomment this after generating Isar schema files:
    /*
    final isar = await IsarDatabase.instance;
    
    await isar.writeTxn(() async {
      final itineraryModel = await isar.itineraries.get(id);
      if (itineraryModel != null) {
        // Load and delete all related days and items
        final dayModels = await itineraryModel.days.load();
        for (final dayModel in dayModels) {
          final itemModels = await dayModel.items.load();
          await isar.dayItems.deleteAll(itemModels.map((item) => item.id).toList());
        }
        await isar.dayPlans.deleteAll(dayModels.map((day) => day.id).toList());
        await isar.itineraries.delete(id);
      }
    });
    */
  }

  @override
  Future<void> updateItinerary(Itinerary itinerary) async {
    if (itinerary.id == null) {
      throw ArgumentError('Itinerary must have an ID to update');
    }

    // TODO: Replace with Isar implementation after running build_runner
    final index = _temporaryStorage.indexWhere((item) => item.id == itinerary.id);
    if (index != -1) {
      _temporaryStorage[index] = itinerary;
    }
    
    // Uncomment this after generating Isar schema files:
    /*
    final isar = await IsarDatabase.instance;
    
    await isar.writeTxn(() async {
      // Delete existing itinerary and all related data
      await deleteItinerary(itinerary.id!);
      
      // Save the updated itinerary
      await saveItinerary(itinerary);
    });
    */
  }
}

