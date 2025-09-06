import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_trip_planner/presentation/pages/itinerary_detail_screen.dart';
import 'package:smart_trip_planner/domain/entities/itinerary.dart';
import 'package:smart_trip_planner/domain/entities/day_plan.dart';
import 'package:smart_trip_planner/domain/entities/day_item.dart';

void main() {
  group('ItineraryDetailScreen Widget Tests', () {
    late Itinerary sampleItinerary;

    setUp(() {
      sampleItinerary = _createSampleItinerary();
    });

    testWidgets('should display itinerary title in app bar', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: ItineraryDetailScreen(itinerary: sampleItinerary),
        ),
      );

      // Assert
      expect(find.text('Kyoto 5-Day Solo Trip'), findsOneWidget);
    });

    testWidgets('should display itinerary header information', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: ItineraryDetailScreen(itinerary: sampleItinerary),
        ),
      );

      // Assert
      expect(find.text('Kyoto 5-Day Solo Trip'), findsOneWidget);
      expect(find.text('2025-04-10 - 2025-04-15'), findsOneWidget);
      expect(find.text('2 days'), findsOneWidget);
    });

    testWidgets('should display all days in the itinerary', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: ItineraryDetailScreen(itinerary: sampleItinerary),
        ),
      );

      // Assert
      expect(find.text('Day 1 - 2025-04-10'), findsOneWidget);
      expect(find.text('Day 2 - 2025-04-11'), findsOneWidget);
      expect(find.text('Fushimi Inari & Gion'), findsOneWidget);
      expect(find.text('Arashiyama & Bamboo Grove'), findsOneWidget);
    });

    testWidgets('should display all activities for each day', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: ItineraryDetailScreen(itinerary: sampleItinerary),
        ),
      );

      // Assert
      expect(find.text('Climb Fushimi Inari Shrine'), findsOneWidget);
      expect(find.text('Explore Gion District'), findsOneWidget);
      expect(find.text('Visit Bamboo Grove'), findsOneWidget);
    });

    testWidgets('should display activity times', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: ItineraryDetailScreen(itinerary: sampleItinerary),
        ),
      );

      // Assert
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('14:00'), findsOneWidget);
      expect(find.text('08:00'), findsOneWidget);
    });

    testWidgets('should display activity locations', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: ItineraryDetailScreen(itinerary: sampleItinerary),
        ),
      );

      // Assert
      expect(find.text('34.9671,135.7727'), findsOneWidget);
      expect(find.text('Gion, Kyoto, Japan'), findsOneWidget);
      expect(find.text('Arashiyama, Kyoto, Japan'), findsOneWidget);
    });

    testWidgets('should display View on Map buttons for each activity', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: ItineraryDetailScreen(itinerary: sampleItinerary),
        ),
      );

      // Assert
      expect(find.text('View on Map'), findsNWidgets(3)); // 3 activities total
      expect(find.byIcon(Icons.map), findsNWidgets(3));
    });

    testWidgets('should display View All on Map button in app bar', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: ItineraryDetailScreen(itinerary: sampleItinerary),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.map), findsAtLeastNWidgets(1)); // At least the app bar button
    });

    testWidgets('should display share button in app bar', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: ItineraryDetailScreen(itinerary: sampleItinerary),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('should handle empty itinerary gracefully', (WidgetTester tester) async {
      // Arrange
      final emptyItinerary = Itinerary(
        title: 'Empty Trip',
        startDate: '2025-04-10',
        endDate: '2025-04-10',
        days: [],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ItineraryDetailScreen(itinerary: emptyItinerary),
        ),
      );

      // Assert
      expect(find.text('Empty Trip'), findsOneWidget);
      expect(find.text('Itinerary'), findsOneWidget);
      expect(find.text('View on Map'), findsNothing);
    });

    testWidgets('should handle day with no activities', (WidgetTester tester) async {
      // Arrange
      final itineraryWithEmptyDay = Itinerary(
        title: 'Trip with Empty Day',
        startDate: '2025-04-10',
        endDate: '2025-04-11',
        days: [
          DayPlan(
            date: '2025-04-10',
            summary: 'Day with activities',
            items: [
              DayItem(
                time: '09:00',
                activity: 'Some activity',
                location: 'Some location',
              ),
            ],
          ),
          DayPlan(
            date: '2025-04-11',
            summary: 'Empty day',
            items: [],
          ),
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ItineraryDetailScreen(itinerary: itineraryWithEmptyDay),
        ),
      );

      // Assert
      expect(find.text('Day 1 - 2025-04-10'), findsOneWidget);
      expect(find.text('Day 2 - 2025-04-11'), findsOneWidget);
      expect(find.text('Some activity'), findsOneWidget);
      expect(find.text('View on Map'), findsOneWidget); // Only one activity
    });

    testWidgets('should scroll when content is long', (WidgetTester tester) async {
      // Arrange
      final longItinerary = _createLongItinerary();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ItineraryDetailScreen(itinerary: longItinerary),
        ),
      );

      // Assert
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      
      // Should be able to scroll
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -100));
      await tester.pump();
    });

    testWidgets('should display proper day numbering', (WidgetTester tester) async {
      // Arrange
      final multiDayItinerary = Itinerary(
        title: '5-Day Trip',
        startDate: '2025-04-10',
        endDate: '2025-04-14',
        days: List.generate(5, (index) => DayPlan(
          date: '2025-04-${10 + index}',
          summary: 'Day ${index + 1} summary',
          items: [
            DayItem(
              time: '09:00',
              activity: 'Activity for day ${index + 1}',
              location: 'Location ${index + 1}',
            ),
          ],
        )),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ItineraryDetailScreen(itinerary: multiDayItinerary),
        ),
      );

      // Assert
      for (int i = 1; i <= 5; i++) {
        expect(find.text('Day $i'), findsOneWidget);
      }
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

Itinerary _createLongItinerary() {
  return Itinerary(
    title: 'Long Trip',
    startDate: '2025-04-10',
    endDate: '2025-04-20',
    days: List.generate(10, (index) => DayPlan(
      date: '2025-04-${10 + index}',
      summary: 'Day ${index + 1} summary',
      items: List.generate(5, (itemIndex) => DayItem(
        time: '${9 + itemIndex}:00',
        activity: 'Activity ${itemIndex + 1} for day ${index + 1}',
        location: 'Location ${itemIndex + 1}, Day ${index + 1}',
      )),
    )),
  );
}


















