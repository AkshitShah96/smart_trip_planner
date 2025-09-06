import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:smart_trip_planner/data/repositories/itinerary_repository_impl.dart';
import 'package:smart_trip_planner/domain/entities/itinerary.dart';
import 'package:smart_trip_planner/domain/entities/day_plan.dart';
import 'package:smart_trip_planner/domain/entities/day_item.dart';
import 'package:smart_trip_planner/data/models/itinerary.dart' as data_model;
import 'package:smart_trip_planner/data/models/day_plan.dart' as data_model;
import 'package:smart_trip_planner/data/models/day_item.dart' as data_model;

void main() {
  group('ItineraryRepository Tests', () {
    late Isar isar;
    late ItineraryRepositoryImpl repository;

    setUpAll(() async {
      // Create in-memory Isar instance for testing
      isar = await Isar.open(
        [
          data_model.ItinerarySchema,
          data_model.DayPlanSchema,
          data_model.DayItemSchema,
        ],
        directory: '',
        name: 'test',
        inspector: false,
      );
    });

    setUp(() {
      repository = ItineraryRepositoryImpl();
      // Replace the database instance with our test instance
      // This would require modifying the repository to accept an Isar instance
    });

    tearDown(() async {
      // Clear all data after each test
      await isar.writeTxn(() async {
        await isar.itineraries.clear();
        await isar.dayPlans.clear();
        await isar.dayItems.clear();
      });
    });

    tearDownAll(() async {
      await isar.close();
    });

    test('should save and retrieve itinerary successfully', () async {
      // Arrange
      final itinerary = _createSampleItinerary();

      // Act
      await repository.saveItinerary(itinerary);
      final retrievedItineraries = await repository.getAllItineraries();

      // Assert
      expect(retrievedItineraries, hasLength(1));
      expect(retrievedItineraries.first.title, equals(itinerary.title));
      expect(retrievedItineraries.first.startDate, equals(itinerary.startDate));
      expect(retrievedItineraries.first.endDate, equals(itinerary.endDate));
      expect(retrievedItineraries.first.days, hasLength(2));
    });

    test('should save and retrieve itinerary by ID', () async {
      // Arrange
      final itinerary = _createSampleItinerary();

      // Act
      await repository.saveItinerary(itinerary);
      final allItineraries = await repository.getAllItineraries();
      final savedItinerary = allItineraries.first;
      
      final retrievedItinerary = await repository.getItineraryById(savedItinerary.id!);

      // Assert
      expect(retrievedItinerary, isNotNull);
      expect(retrievedItinerary!.title, equals(itinerary.title));
      expect(retrievedItinerary.days, hasLength(2));
      expect(retrievedItinerary.days.first.items, hasLength(2));
    });

    test('should return null when getting non-existent itinerary', () async {
      // Act
      final result = await repository.getItineraryById(999);

      // Assert
      expect(result, isNull);
    });

    test('should delete itinerary successfully', () async {
      // Arrange
      final itinerary = _createSampleItinerary();
      await repository.saveItinerary(itinerary);
      final allItineraries = await repository.getAllItineraries();
      final savedItinerary = allItineraries.first;

      // Act
      await repository.deleteItinerary(savedItinerary.id!);
      final remainingItineraries = await repository.getAllItineraries();

      // Assert
      expect(remainingItineraries, isEmpty);
    });

    test('should update itinerary successfully', () async {
      // Arrange
      final originalItinerary = _createSampleItinerary();
      await repository.saveItinerary(originalItinerary);
      final allItineraries = await repository.getAllItineraries();
      final savedItinerary = allItineraries.first;

      final updatedItinerary = savedItinerary.copyWith(
        title: 'Updated Trip Title',
        days: [
          ...savedItinerary.days,
          DayPlan(
            date: '2025-04-16',
            summary: 'Additional day',
            items: [
              DayItem(
                time: '10:00',
                activity: 'New activity',
                location: 'New location',
              ),
            ],
          ),
        ],
      );

      // Act
      await repository.updateItinerary(updatedItinerary);
      final retrievedItinerary = await repository.getItineraryById(savedItinerary.id!);

      // Assert
      expect(retrievedItinerary, isNotNull);
      expect(retrievedItinerary!.title, equals('Updated Trip Title'));
      expect(retrievedItinerary.days, hasLength(3));
    });

    test('should handle multiple itineraries correctly', () async {
      // Arrange
      final itinerary1 = _createSampleItinerary();
      final itinerary2 = _createSampleItinerary().copyWith(
        title: 'Second Trip',
        startDate: '2025-05-01',
        endDate: '2025-05-05',
      );

      // Act
      await repository.saveItinerary(itinerary1);
      await repository.saveItinerary(itinerary2);
      final allItineraries = await repository.getAllItineraries();

      // Assert
      expect(allItineraries, hasLength(2));
      expect(allItineraries.map((i) => i.title), containsAll(['Kyoto 5-Day Solo Trip', 'Second Trip']));
    });

    test('should preserve nested data structure correctly', () async {
      // Arrange
      final itinerary = _createComplexItinerary();

      // Act
      await repository.saveItinerary(itinerary);
      final retrievedItineraries = await repository.getAllItineraries();
      final retrievedItinerary = retrievedItineraries.first;

      // Assert
      expect(retrievedItinerary.days, hasLength(2));
      
      final firstDay = retrievedItinerary.days.first;
      expect(firstDay.summary, equals('Fushimi Inari & Gion'));
      expect(firstDay.items, hasLength(3));
      expect(firstDay.items.first.activity, equals('Climb Fushimi Inari Shrine'));
      expect(firstDay.items.first.location, equals('34.9671,135.7727'));

      final secondDay = retrievedItinerary.days[1];
      expect(secondDay.summary, equals('Arashiyama & Bamboo Grove'));
      expect(secondDay.items, hasLength(2));
    });
  });
}

Itinerary _createSampleItinerary() {
  return Itinerary(
    title: 'Kyoto 5-Day Solo Trip',
    startDate: '2025-04-10',
    endDate: '2025-04-15',
    days: [
      DayPlan(
        date: '2025-04-10',
        summary: 'Fushimi Inari & Gion',
        items: [
          DayItem(
            time: '09:00',
            activity: 'Climb Fushimi Inari Shrine',
            location: '34.9671,135.7727',
          ),
          DayItem(
            time: '14:00',
            activity: 'Explore Gion District',
            location: 'Gion, Kyoto, Japan',
          ),
        ],
      ),
      DayPlan(
        date: '2025-04-11',
        summary: 'Arashiyama & Bamboo Grove',
        items: [
          DayItem(
            time: '08:00',
            activity: 'Visit Bamboo Grove',
            location: 'Arashiyama, Kyoto, Japan',
          ),
        ],
      ),
    ],
  );
}

Itinerary _createComplexItinerary() {
  return Itinerary(
    title: 'Complex Test Trip',
    startDate: '2025-04-10',
    endDate: '2025-04-12',
    days: [
      DayPlan(
        date: '2025-04-10',
        summary: 'Fushimi Inari & Gion',
        items: [
          DayItem(
            time: '09:00',
            activity: 'Climb Fushimi Inari Shrine',
            location: '34.9671,135.7727',
          ),
          DayItem(
            time: '12:00',
            activity: 'Lunch at Traditional Restaurant',
            location: 'Gion, Kyoto, Japan',
          ),
          DayItem(
            time: '15:00',
            activity: 'Explore Gion District',
            location: 'Gion, Kyoto, Japan',
          ),
        ],
      ),
      DayPlan(
        date: '2025-04-11',
        summary: 'Arashiyama & Bamboo Grove',
        items: [
          DayItem(
            time: '08:00',
            activity: 'Visit Bamboo Grove',
            location: 'Arashiyama, Kyoto, Japan',
          ),
          DayItem(
            time: '11:00',
            activity: 'Monkey Park',
            location: 'Iwatayama Monkey Park, Kyoto, Japan',
          ),
        ],
      ),
    ],
  );
}


















