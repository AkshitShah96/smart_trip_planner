import 'package:flutter_test/flutter_test.dart';
import 'package:smart_trip_planner/core/utils/json_validator.dart';
import 'package:smart_trip_planner/data/models/itinerary.dart';
import 'package:smart_trip_planner/data/models/day_plan.dart';
import 'package:smart_trip_planner/data/models/day_item.dart';

void main() {
  group('JsonValidator', () {
    group('Valid JSON Validation', () {
      test('should validate and parse valid itinerary JSON', () {
        const validJson = '''
        {
          "title": "Tokyo Adventure",
          "startDate": "2024-03-15",
          "endDate": "2024-03-17",
          "days": [
            {
              "date": "2024-03-15",
              "summary": "Arrival and exploration",
              "items": [
                {
                  "time": "09:00",
                  "activity": "Arrive at Narita Airport",
                  "location": "Narita International Airport"
                },
                {
                  "time": "12:00",
                  "activity": "Lunch at Tsukiji Market",
                  "location": "Tsukiji Outer Market"
                }
              ]
            }
          ]
        }
        ''';

        final result = JsonValidator.validateAndParseItinerary(validJson);

        expect(result.isValid, isTrue);
        expect(result.itinerary, isNotNull);
        expect(result.errors, isEmpty);
        expect(result.regenerationRequest, isNull);

        final itinerary = result.itinerary!;
        expect(itinerary.title, 'Tokyo Adventure');
        expect(itinerary.startDate, '2024-03-15');
        expect(itinerary.endDate, '2024-03-17');
        expect(itinerary.days, hasLength(1));
        expect(itinerary.days.first.date, '2024-03-15');
        expect(itinerary.days.first.summary, 'Arrival and exploration');
        expect(itinerary.days.first.items, hasLength(2));
        expect(itinerary.days.first.items.first.time, '09:00');
        expect(itinerary.days.first.items.first.activity, 'Arrive at Narita Airport');
        expect(itinerary.days.first.items.first.location, 'Narita International Airport');
      });

      test('should validate complex multi-day itinerary', () {
        const validJson = '''
        {
          "title": "Kyoto Cultural Journey",
          "startDate": "2024-04-01",
          "endDate": "2024-04-03",
          "days": [
            {
              "date": "2024-04-01",
              "summary": "Temples and traditional culture",
              "items": [
                {
                  "time": "08:00",
                  "activity": "Visit Fushimi Inari Shrine",
                  "location": "Fushimi Inari Taisha"
                },
                {
                  "time": "14:00",
                  "activity": "Explore Kiyomizu-dera Temple",
                  "location": "Kiyomizu-dera"
                }
              ]
            },
            {
              "date": "2024-04-02",
              "summary": "Bamboo groves and gardens",
              "items": [
                {
                  "time": "09:00",
                  "activity": "Walk through Arashiyama Bamboo Grove",
                  "location": "Arashiyama Bamboo Grove"
                },
                {
                  "time": "15:00",
                  "activity": "Visit Ryoan-ji Temple",
                  "location": "Ryoan-ji Temple"
                }
              ]
            }
          ]
        }
        ''';

        final result = JsonValidator.validateAndParseItinerary(validJson);

        expect(result.isValid, isTrue);
        expect(result.itinerary, isNotNull);
        expect(result.itinerary!.days, hasLength(2));
        expect(result.itinerary!.days[0].items, hasLength(2));
        expect(result.itinerary!.days[1].items, hasLength(2));
      });
    });

    group('Invalid JSON Validation', () {
      test('should reject invalid JSON format', () {
        const invalidJson = '{"title": "Test", "invalid": json}';

        final result = JsonValidator.validateAndParseItinerary(invalidJson);

        expect(result.isValid, isFalse);
        expect(result.itinerary, isNull);
        expect(result.errors, isNotEmpty);
        expect(result.errors.first, contains('Invalid JSON format'));
        expect(result.regenerationRequest, isNotNull);
      });

      test('should reject missing required fields', () {
        const missingFieldsJson = '''
        {
          "title": "Test Trip",
          "startDate": "2024-03-15"
        }
        ''';

        final result = JsonValidator.validateAndParseItinerary(missingFieldsJson);

        expect(result.isValid, isFalse);
        expect(result.errors, isNotEmpty);
        expect(result.errors.any((e) => e.contains('endDate')), isTrue);
        expect(result.errors.any((e) => e.contains('days')), isTrue);
        expect(result.regenerationRequest, isNotNull);
      });

      test('should reject invalid field types', () {
        const invalidTypesJson = '''
        {
          "title": 123,
          "startDate": "2024-03-15",
          "endDate": "2024-03-17",
          "days": "not an array"
        }
        ''';

        final result = JsonValidator.validateAndParseItinerary(invalidTypesJson);

        expect(result.isValid, isFalse);
        expect(result.errors, isNotEmpty);
        expect(result.errors.any((e) => e.contains('title') && e.contains('string')), isTrue);
        expect(result.errors.any((e) => e.contains('days') && e.contains('array')), isTrue);
      });

      test('should reject invalid date formats', () {
        const invalidDateJson = '''
        {
          "title": "Test Trip",
          "startDate": "15-03-2024",
          "endDate": "17-03-2024",
          "days": []
        }
        ''';

        final result = JsonValidator.validateAndParseItinerary(invalidDateJson);

        expect(result.isValid, isFalse);
        expect(result.errors, isNotEmpty);
        expect(result.errors.any((e) => e.contains('startDate') && e.contains('YYYY-MM-DD')), isTrue);
        expect(result.errors.any((e) => e.contains('endDate') && e.contains('YYYY-MM-DD')), isTrue);
      });

      test('should reject invalid time formats', () {
        const invalidTimeJson = '''
        {
          "title": "Test Trip",
          "startDate": "2024-03-15",
          "endDate": "2024-03-17",
          "days": [
            {
              "date": "2024-03-15",
              "summary": "Test day",
              "items": [
                {
                  "time": "9:00 AM",
                  "activity": "Test activity",
                  "location": "Test location"
                }
              ]
            }
          ]
        }
        ''';

        final result = JsonValidator.validateAndParseItinerary(invalidTimeJson);

        expect(result.isValid, isFalse);
        expect(result.errors, isNotEmpty);
        expect(result.errors.any((e) => e.contains('time') && e.contains('HH:MM')), isTrue);
      });

      test('should reject empty arrays', () {
        const emptyArraysJson = '''
        {
          "title": "",
          "startDate": "2024-03-15",
          "endDate": "2024-03-17",
          "days": []
        }
        ''';

        final result = JsonValidator.validateAndParseItinerary(emptyArraysJson);

        expect(result.isValid, isFalse);
        expect(result.errors, isNotEmpty);
        expect(result.errors.any((e) => e.contains('title') && e.contains('empty')), isTrue);
        expect(result.errors.any((e) => e.contains('days') && e.contains('empty')), isTrue);
      });

      test('should reject end date before start date', () {
        const invalidDateRangeJson = '''
        {
          "title": "Test Trip",
          "startDate": "2024-03-17",
          "endDate": "2024-03-15",
          "days": [
            {
              "date": "2024-03-15",
              "summary": "Test day",
              "items": [
                {
                  "time": "09:00",
                  "activity": "Test activity",
                  "location": "Test location"
                }
              ]
            }
          ]
        }
        ''';

        final result = JsonValidator.validateAndParseItinerary(invalidDateRangeJson);

        expect(result.isValid, isFalse);
        expect(result.errors, isNotEmpty);
        expect(result.errors.any((e) => e.contains('endDate') && e.contains('after start date')), isTrue);
      });

      test('should reject invalid day structure', () {
        const invalidDayJson = '''
        {
          "title": "Test Trip",
          "startDate": "2024-03-15",
          "endDate": "2024-03-17",
          "days": [
            {
              "date": "2024-03-15",
              "summary": "Test day",
              "items": "not an array"
            }
          ]
        }
        ''';

        final result = JsonValidator.validateAndParseItinerary(invalidDayJson);

        expect(result.isValid, isFalse);
        expect(result.errors, isNotEmpty);
        expect(result.errors.any((e) => e.contains('items') && e.contains('array')), isTrue);
      });

      test('should reject invalid item structure', () {
        const invalidItemJson = '''
        {
          "title": "Test Trip",
          "startDate": "2024-03-15",
          "endDate": "2024-03-17",
          "days": [
            {
              "date": "2024-03-15",
              "summary": "Test day",
              "items": [
                {
                  "time": "09:00",
                  "activity": "Test activity"
                }
              ]
            }
          ]
        }
        ''';

        final result = JsonValidator.validateAndParseItinerary(invalidItemJson);

        expect(result.isValid, isFalse);
        expect(result.errors, isNotEmpty);
        expect(result.errors.any((e) => e.contains('location') && e.contains('missing')), isTrue);
      });
    });

    group('ValidationError Types', () {
      test('should categorize different types of validation errors', () {
        const invalidJson = '''
        {
          "title": 123,
          "startDate": "invalid-date",
          "endDate": "2024-03-17",
          "days": "not-array"
        }
        ''';

        final result = JsonValidator.validateAndParseItinerary(invalidJson);

        expect(result.isValid, isFalse);
        expect(result.errors, isNotEmpty);
        
        // Check for specific error types
        expect(result.errors.any((e) => e.contains('title') && e.contains('string')), isTrue);
        expect(result.errors.any((e) => e.contains('startDate') && e.contains('YYYY-MM-DD')), isTrue);
        expect(result.errors.any((e) => e.contains('days') && e.contains('array')), isTrue);
      });
    });

    group('Regeneration Request Generation', () {
      test('should generate detailed regeneration request', () {
        const invalidJson = '''
        {
          "title": "",
          "startDate": "invalid",
          "endDate": "2024-03-17",
          "days": []
        }
        ''';

        final result = JsonValidator.validateAndParseItinerary(invalidJson);

        expect(result.isValid, isFalse);
        expect(result.regenerationRequest, isNotNull);
        expect(result.regenerationRequest!, contains('validation errors'));
        expect(result.regenerationRequest!, contains('title'));
        expect(result.regenerationRequest!, contains('startDate'));
        expect(result.regenerationRequest!, contains('days'));
        expect(result.regenerationRequest!, contains('schema'));
      });

      test('should include expected vs actual values in regeneration request', () {
        const invalidJson = '''
        {
          "title": 123,
          "startDate": "2024-03-15",
          "endDate": "2024-03-17",
          "days": []
        }
        ''';

        final result = JsonValidator.validateAndParseItinerary(invalidJson);

        expect(result.isValid, isFalse);
        expect(result.regenerationRequest, isNotNull);
        expect(result.regenerationRequest!, contains('Expected:'));
        expect(result.regenerationRequest!, contains('Actual:'));
      });
    });

    group('Utility Methods', () {
      test('should check if JSON is valid without parsing', () {
        const validJson = '''
        {
          "title": "Test Trip",
          "startDate": "2024-03-15",
          "endDate": "2024-03-17",
          "days": [
            {
              "date": "2024-03-15",
              "summary": "Test day",
              "items": [
                {
                  "time": "09:00",
                  "activity": "Test activity",
                  "location": "Test location"
                }
              ]
            }
          ]
        }
        ''';

        const invalidJson = '''
        {
          "title": "Test Trip",
          "startDate": "invalid-date",
          "endDate": "2024-03-17",
          "days": []
        }
        ''';

        expect(JsonValidator.isValidItineraryJson(validJson), isTrue);
        expect(JsonValidator.isValidItineraryJson(invalidJson), isFalse);
      });

      test('should get validation errors without parsing', () {
        const invalidJson = '''
        {
          "title": "",
          "startDate": "invalid-date",
          "endDate": "2024-03-17",
          "days": []
        }
        ''';

        final errors = JsonValidator.getValidationErrors(invalidJson);

        expect(errors, isNotEmpty);
        expect(errors.any((e) => e.contains('title')), isTrue);
        expect(errors.any((e) => e.contains('startDate')), isTrue);
        expect(errors.any((e) => e.contains('days')), isTrue);
      });
    });

    group('Edge Cases', () {
      test('should handle null values in JSON', () {
        const nullValuesJson = '''
        {
          "title": null,
          "startDate": "2024-03-15",
          "endDate": "2024-03-17",
          "days": null
        }
        ''';

        final result = JsonValidator.validateAndParseItinerary(nullValuesJson);

        expect(result.isValid, isFalse);
        expect(result.errors, isNotEmpty);
        expect(result.errors.any((e) => e.contains('title') && e.contains('null')), isTrue);
        expect(result.errors.any((e) => e.contains('days') && e.contains('null')), isTrue);
      });

      test('should handle whitespace-only strings', () {
        const whitespaceJson = '''
        {
          "title": "   ",
          "startDate": "2024-03-15",
          "endDate": "2024-03-17",
          "days": [
            {
              "date": "2024-03-15",
              "summary": "   ",
              "items": [
                {
                  "time": "09:00",
                  "activity": "   ",
                  "location": "   "
                }
              ]
            }
          ]
        }
        ''';

        final result = JsonValidator.validateAndParseItinerary(whitespaceJson);

        expect(result.isValid, isFalse);
        expect(result.errors, isNotEmpty);
        expect(result.errors.any((e) => e.contains('title') && e.contains('empty')), isTrue);
        expect(result.errors.any((e) => e.contains('summary') && e.contains('empty')), isTrue);
        expect(result.errors.any((e) => e.contains('activity') && e.contains('empty')), isTrue);
        expect(result.errors.any((e) => e.contains('location') && e.contains('empty')), isTrue);
      });

      test('should handle very large JSON', () {
        // Create a large itinerary with many days and items
        final days = <String>[];
        for (int i = 1; i <= 30; i++) {
          final day = '''
          {
            "date": "2024-03-${i.toString().padLeft(2, '0')}",
            "summary": "Day $i activities",
            "items": [
              {
                "time": "09:00",
                "activity": "Morning activity $i",
                "location": "Location $i"
              },
              {
                "time": "14:00",
                "activity": "Afternoon activity $i",
                "location": "Location $i"
              }
            ]
          }''';
          days.add(day);
        }

        final largeJson = '''
        {
          "title": "30-Day Adventure",
          "startDate": "2024-03-01",
          "endDate": "2024-03-30",
          "days": [${days.join(',')}]
        }
        ''';

        final result = JsonValidator.validateAndParseItinerary(largeJson);

        expect(result.isValid, isTrue);
        expect(result.itinerary, isNotNull);
        expect(result.itinerary!.days, hasLength(30));
      });
    });

    group('ValidationResult Factory Methods', () {
      test('should create success result correctly', () {
        final itinerary = Itinerary(
          title: 'Test Trip',
          startDate: '2024-03-15',
          endDate: '2024-03-17',
          days: [],
        );

        final result = ValidationResult.success(itinerary);

        expect(result.isValid, isTrue);
        expect(result.itinerary, equals(itinerary));
        expect(result.errors, isEmpty);
        expect(result.regenerationRequest, isNull);
      });

      test('should create failure result correctly', () {
        final errors = ['Error 1', 'Error 2'];
        const regenerationRequest = 'Please fix the errors';

        final result = ValidationResult.failure(errors, regenerationRequest: regenerationRequest);

        expect(result.isValid, isFalse);
        expect(result.itinerary, isNull);
        expect(result.errors, equals(errors));
        expect(result.regenerationRequest, equals(regenerationRequest));
      });
    });
  });
}



