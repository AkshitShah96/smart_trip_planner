import 'package:flutter_test/flutter_test.dart';
import 'package:smart_trip_planner/data/models/itinerary.dart';
import 'package:smart_trip_planner/data/models/day_plan.dart';
import 'package:smart_trip_planner/data/models/day_item.dart';
import 'package:smart_trip_planner/core/models/itinerary_change.dart';
import 'package:smart_trip_planner/core/utils/itinerary_diff_engine.dart';

void main() {
  group('ItineraryDiffEngine', () {
    late Itinerary baseItinerary;
    late Itinerary modifiedItinerary;

    setUp(() {
      baseItinerary = Itinerary(
        title: 'Tokyo Adventure',
        startDate: '2024-03-15',
        endDate: '2024-03-17',
        days: [
          DayPlan(
            date: '2024-03-15',
            summary: 'Arrival day',
            items: [
              DayItem(
                time: '09:00',
                activity: 'Arrive at Narita Airport',
                location: 'Narita International Airport',
              ),
              DayItem(
                time: '12:00',
                activity: 'Lunch at Tsukiji Market',
                location: 'Tsukiji Outer Market',
              ),
            ],
          ),
          DayPlan(
            date: '2024-03-16',
            summary: 'Temple visits',
            items: [
              DayItem(
                time: '08:00',
                activity: 'Visit Senso-ji Temple',
                location: 'Asakusa, Tokyo',
              ),
            ],
          ),
        ],
      );
    });

    group('Basic Comparison', () {
      test('should detect no changes for identical itineraries', () {
        final diff = ItineraryDiffEngine.compareItineraries(baseItinerary, baseItinerary);
        
        expect(diff.hasChanges, isFalse);
        expect(diff.changes, isEmpty);
        expect(diff.summary['totalChanges'], 0);
      });

      test('should detect title change', () {
        modifiedItinerary = Itinerary(
          title: 'Tokyo Cultural Journey',
          startDate: baseItinerary.startDate,
          endDate: baseItinerary.endDate,
          days: baseItinerary.days,
        );

        final diff = ItineraryDiffEngine.compareItineraries(baseItinerary, modifiedItinerary);
        
        expect(diff.hasChanges, isTrue);
        expect(diff.changes, hasLength(1));
        expect(diff.changes.first.type, ChangeType.modified);
        expect(diff.changes.first.path, 'title');
        expect(diff.changes.first.oldValue, 'Tokyo Adventure');
        expect(diff.changes.first.newValue, 'Tokyo Cultural Journey');
      });

      test('should detect date changes', () {
        modifiedItinerary = Itinerary(
          title: baseItinerary.title,
          startDate: '2024-03-16',
          endDate: '2024-03-18',
          days: baseItinerary.days,
        );

        final diff = ItineraryDiffEngine.compareItineraries(baseItinerary, modifiedItinerary);
        
        expect(diff.hasChanges, isTrue);
        expect(diff.changes, hasLength(2));
        expect(diff.changes.any((c) => c.path == 'startDate'), isTrue);
        expect(diff.changes.any((c) => c.path == 'endDate'), isTrue);
      });
    });

    group('Day Changes', () {
      test('should detect added day', () {
        modifiedItinerary = Itinerary(
          title: baseItinerary.title,
          startDate: baseItinerary.startDate,
          endDate: '2024-03-18',
          days: [
            ...baseItinerary.days,
            DayPlan(
              date: '2024-03-17',
              summary: 'Shopping day',
              items: [
                DayItem(
                  time: '10:00',
                  activity: 'Visit Ginza district',
                  location: 'Ginza, Tokyo',
                ),
              ],
            ),
          ],
        );

        final diff = ItineraryDiffEngine.compareItineraries(baseItinerary, modifiedItinerary);
        
        expect(diff.hasChanges, isTrue);
        final addedChanges = diff.getChangesByType(ChangeType.added);
        expect(addedChanges, hasLength(1));
        expect(addedChanges.first.granularity, ChangeGranularity.day);
        expect(addedChanges.first.description, contains('New day added'));
      });

      test('should detect removed day', () {
        modifiedItinerary = Itinerary(
          title: baseItinerary.title,
          startDate: baseItinerary.startDate,
          endDate: '2024-03-16',
          days: [baseItinerary.days.first], // Remove second day
        );

        final diff = ItineraryDiffEngine.compareItineraries(baseItinerary, modifiedItinerary);
        
        expect(diff.hasChanges, isTrue);
        final removedChanges = diff.getChangesByType(ChangeType.removed);
        expect(removedChanges, hasLength(1));
        expect(removedChanges.first.granularity, ChangeGranularity.day);
        expect(removedChanges.first.description, contains('Day removed'));
      });

      test('should detect day summary change', () {
        modifiedItinerary = Itinerary(
          title: baseItinerary.title,
          startDate: baseItinerary.startDate,
          endDate: baseItinerary.endDate,
          days: [
            baseItinerary.days[0],
            DayPlan(
              date: baseItinerary.days[1].date,
              summary: 'Temple and shrine visits',
              items: baseItinerary.days[1].items,
            ),
          ],
        );

        final diff = ItineraryDiffEngine.compareItineraries(baseItinerary, modifiedItinerary);
        
        expect(diff.hasChanges, isTrue);
        final modifiedChanges = diff.getChangesByType(ChangeType.modified);
        expect(modifiedChanges.any((c) => c.path.contains('.summary')), isTrue);
      });
    });

    group('Item Changes', () {
      test('should detect added item', () {
        modifiedItinerary = Itinerary(
          title: baseItinerary.title,
          startDate: baseItinerary.startDate,
          endDate: baseItinerary.endDate,
          days: [
            baseItinerary.days[0],
            DayPlan(
              date: baseItinerary.days[1].date,
              summary: baseItinerary.days[1].summary,
              items: [
                ...baseItinerary.days[1].items,
                DayItem(
                  time: '14:00',
                  activity: 'Visit Meiji Shrine',
                  location: 'Shibuya, Tokyo',
                ),
              ],
            ),
          ],
        );

        final diff = ItineraryDiffEngine.compareItineraries(baseItinerary, modifiedItinerary);
        
        expect(diff.hasChanges, isTrue);
        final addedChanges = diff.getChangesByType(ChangeType.added);
        expect(addedChanges.any((c) => c.granularity == ChangeGranularity.item), isTrue);
      });

      test('should detect removed item', () {
        modifiedItinerary = Itinerary(
          title: baseItinerary.title,
          startDate: baseItinerary.startDate,
          endDate: baseItinerary.endDate,
          days: [
            DayPlan(
              date: baseItinerary.days[0].date,
              summary: baseItinerary.days[0].summary,
              items: [baseItinerary.days[0].items.first], // Remove second item
            ),
            baseItinerary.days[1],
          ],
        );

        final diff = ItineraryDiffEngine.compareItineraries(baseItinerary, modifiedItinerary);
        
        expect(diff.hasChanges, isTrue);
        final removedChanges = diff.getChangesByType(ChangeType.removed);
        expect(removedChanges.any((c) => c.granularity == ChangeGranularity.item), isTrue);
      });

      test('should detect modified item fields', () {
        modifiedItinerary = Itinerary(
          title: baseItinerary.title,
          startDate: baseItinerary.startDate,
          endDate: baseItinerary.endDate,
          days: [
            baseItinerary.days[0],
            DayPlan(
              date: baseItinerary.days[1].date,
              summary: baseItinerary.days[1].summary,
              items: [
                DayItem(
                  time: '09:00', // Changed from 08:00
                  activity: 'Visit Senso-ji Temple',
                  location: 'Asakusa, Tokyo',
                ),
              ],
            ),
          ],
        );

        final diff = ItineraryDiffEngine.compareItineraries(baseItinerary, modifiedItinerary);
        
        expect(diff.hasChanges, isTrue);
        final modifiedChanges = diff.getChangesByType(ChangeType.modified);
        expect(modifiedChanges.any((c) => c.path.contains('.time')), isTrue);
      });

      test('should detect moved item', () {
        modifiedItinerary = Itinerary(
          title: baseItinerary.title,
          startDate: baseItinerary.startDate,
          endDate: baseItinerary.endDate,
          days: [
            DayPlan(
              date: baseItinerary.days[0].date,
              summary: baseItinerary.days[0].summary,
              items: [
                baseItinerary.days[0].items[1], // Moved second item to first
                baseItinerary.days[0].items[0], // Moved first item to second
              ],
            ),
            baseItinerary.days[1],
          ],
        );

        final diff = ItineraryDiffEngine.compareItineraries(baseItinerary, modifiedItinerary);
        
        expect(diff.hasChanges, isTrue);
        final movedChanges = diff.getChangesByType(ChangeType.moved);
        expect(movedChanges, isNotEmpty);
      });
    });

    group('Change Filtering', () {
      late ItineraryDiff diff;

      setUp(() {
        modifiedItinerary = Itinerary(
          title: 'Tokyo Cultural Journey',
          startDate: '2024-03-16',
          endDate: '2024-03-18',
          days: [
            DayPlan(
              date: '2024-03-16',
              summary: 'Arrival and exploration',
              items: [
                DayItem(
                  time: '10:00',
                  activity: 'Arrive at Narita Airport',
                  location: 'Narita International Airport',
                ),
                DayItem(
                  time: '14:00',
                  activity: 'Visit Tokyo Skytree',
                  location: 'Sumida, Tokyo',
                ),
              ],
            ),
            DayPlan(
              date: '2024-03-17',
              summary: 'Temple visits',
              items: [
                DayItem(
                  time: '08:00',
                  activity: 'Visit Senso-ji Temple',
                  location: 'Asakusa, Tokyo',
                ),
              ],
            ),
            DayPlan(
              date: '2024-03-18',
              summary: 'Shopping day',
              items: [
                DayItem(
                  time: '10:00',
                  activity: 'Visit Ginza district',
                  location: 'Ginza, Tokyo',
                ),
              ],
            ),
          ],
        );

        diff = ItineraryDiffEngine.compareItineraries(baseItinerary, modifiedItinerary);
      });

      test('should filter changes by type', () {
        final addedChanges = diff.getChangesByType(ChangeType.added);
        final modifiedChanges = diff.getChangesByType(ChangeType.modified);
        final removedChanges = diff.getChangesByType(ChangeType.removed);

        expect(addedChanges, isNotEmpty);
        expect(modifiedChanges, isNotEmpty);
        expect(removedChanges, isEmpty);
      });

      test('should filter changes by granularity', () {
        final itineraryChanges = diff.getChangesByGranularity(ChangeGranularity.itinerary);
        final dayChanges = diff.getChangesByGranularity(ChangeGranularity.day);
        final itemChanges = diff.getChangesByGranularity(ChangeGranularity.item);

        expect(itineraryChanges, isNotEmpty);
        expect(dayChanges, isNotEmpty);
        expect(itemChanges, isNotEmpty);
      });

      test('should filter changes by day', () {
        final day0Changes = diff.getChangesForDay(0);
        final day1Changes = diff.getChangesForDay(1);
        final day2Changes = diff.getChangesForDay(2);

        expect(day0Changes, isNotEmpty);
        expect(day1Changes, isNotEmpty);
        expect(day2Changes, isNotEmpty);
      });

      test('should check if day has changes', () {
        expect(diff.hasChangesInDay(0), isTrue);
        expect(diff.hasChangesInDay(1), isTrue);
        expect(diff.hasChangesInDay(2), isTrue);
      });
    });

    group('Summary Generation', () {
      test('should generate correct summary', () {
        modifiedItinerary = Itinerary(
          title: 'Tokyo Cultural Journey',
          startDate: baseItinerary.startDate,
          endDate: baseItinerary.endDate,
          days: [
            ...baseItinerary.days,
            DayPlan(
              date: '2024-03-17',
              summary: 'Shopping day',
              items: [
                DayItem(
                  time: '10:00',
                  activity: 'Visit Ginza district',
                  location: 'Ginza, Tokyo',
                ),
              ],
            ),
          ],
        );

        final diff = ItineraryDiffEngine.compareItineraries(baseItinerary, modifiedItinerary);
        
        expect(diff.summary['totalChanges'], greaterThan(0));
        expect(diff.summary['added'], greaterThan(0));
        expect(diff.summary['hasChanges'], isTrue);
      });

      test('should generate changes summary string', () {
        modifiedItinerary = Itinerary(
          title: 'Tokyo Cultural Journey',
          startDate: baseItinerary.startDate,
          endDate: baseItinerary.endDate,
          days: [
            ...baseItinerary.days,
            DayPlan(
              date: '2024-03-17',
              summary: 'Shopping day',
              items: [
                DayItem(
                  time: '10:00',
                  activity: 'Visit Ginza district',
                  location: 'Ginza, Tokyo',
                ),
              ],
            ),
          ],
        );

        final diff = ItineraryDiffEngine.compareItineraries(baseItinerary, modifiedItinerary);
        final summary = diff.getChangesSummary();
        
        expect(summary, contains('Changes:'));
        expect(summary, contains('added'));
      });
    });

    group('Helper Methods', () {
      late ItineraryDiff diff;

      setUp(() {
        modifiedItinerary = Itinerary(
          title: 'Tokyo Cultural Journey',
          startDate: baseItinerary.startDate,
          endDate: baseItinerary.endDate,
          days: [
            DayPlan(
              date: baseItinerary.days[0].date,
              summary: 'Arrival and exploration',
              items: [
                DayItem(
                  time: '10:00',
                  activity: 'Arrive at Narita Airport',
                  location: 'Narita International Airport',
                ),
                DayItem(
                  time: '14:00',
                  activity: 'Visit Tokyo Skytree',
                  location: 'Sumida, Tokyo',
                ),
              ],
            ),
            baseItinerary.days[1],
          ],
        );

        diff = ItineraryDiffEngine.compareItineraries(baseItinerary, modifiedItinerary);
      });

      test('should get day changes', () {
        final dayChange = ItineraryDiffEngine.getDayChanges(diff, 0);
        
        expect(dayChange.dayIndex, 0);
        expect(dayChange.hasChanges, isTrue);
        expect(dayChange.changes, isNotEmpty);
      });

      test('should get item changes', () {
        final itemChange = ItineraryDiffEngine.getItemChanges(diff, 0, 0);
        
        expect(itemChange.dayIndex, 0);
        expect(itemChange.itemIndex, 0);
        expect(itemChange.hasChanges, isTrue);
        expect(itemChange.changes, isNotEmpty);
      });

      test('should create simplified diff', () {
        final simplified = ItineraryDiffEngine.createSimplifiedDiff(diff);
        
        expect(simplified['hasChanges'], isTrue);
        expect(simplified['changes'], isA<List>());
        expect(simplified['oldItinerary'], isA<Map>());
        expect(simplified['newItinerary'], isA<Map>());
      });
    });

    group('Edge Cases', () {
      test('should handle empty itineraries', () {
        final emptyItinerary = Itinerary(
          title: 'Empty Trip',
          startDate: '2024-03-15',
          endDate: '2024-03-15',
          days: [],
        );

        final diff = ItineraryDiffEngine.compareItineraries(emptyItinerary, baseItinerary);
        
        expect(diff.hasChanges, isTrue);
        expect(diff.changes, isNotEmpty);
      });

      test('should handle completely different itineraries', () {
        final differentItinerary = Itinerary(
          title: 'Paris Adventure',
          startDate: '2024-06-01',
          endDate: '2024-06-03',
          days: [
            DayPlan(
              date: '2024-06-01',
              summary: 'Arrival in Paris',
              items: [
                DayItem(
                  time: '10:00',
                  activity: 'Visit Eiffel Tower',
                  location: 'Paris, France',
                ),
              ],
            ),
          ],
        );

        final diff = ItineraryDiffEngine.compareItineraries(baseItinerary, differentItinerary);
        
        expect(diff.hasChanges, isTrue);
        expect(diff.changes, isNotEmpty);
      });

      test('should handle items with additional info', () {
        final itineraryWithAdditionalInfo = Itinerary(
          title: baseItinerary.title,
          startDate: baseItinerary.startDate,
          endDate: baseItinerary.endDate,
          days: [
            DayPlan(
              date: baseItinerary.days[0].date,
              summary: baseItinerary.days[0].summary,
              items: [
                DayItem(
                  time: baseItinerary.days[0].items[0].time,
                  activity: baseItinerary.days[0].items[0].activity,
                  location: baseItinerary.days[0].items[0].location,
                  additionalInfo: {'rating': 4.5, 'price': '¥¥¥'},
                ),
              ],
            ),
            baseItinerary.days[1],
          ],
        );

        final diff = ItineraryDiffEngine.compareItineraries(baseItinerary, itineraryWithAdditionalInfo);
        
        expect(diff.hasChanges, isTrue);
        expect(diff.changes.any((c) => c.path.contains('additionalInfo')), isTrue);
      });
    });
  });
}


