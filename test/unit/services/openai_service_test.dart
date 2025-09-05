import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:smart_trip_planner/data/services/openai_itinerary_service.dart';
import 'package:smart_trip_planner/core/errors/itinerary_errors.dart';

void main() {
  group('OpenAIItineraryService Tests', () {
    late Dio dio;
    late DioAdapter dioAdapter;
    late OpenAIItineraryService service;

    setUp(() {
      dio = Dio();
      dioAdapter = DioAdapter(dio: dio);
      service = OpenAIItineraryService(
        apiKey: 'test-api-key',
        dio: dio,
      );
    });

    tearDown(() {
      dio.close();
    });

    test('should generate itinerary successfully with valid response', () async {
      // Arrange
      const mockResponse = {
        'choices': [
          {
            'message': {
              'content': '''
{
  "title": "Kyoto 5-Day Solo Trip",
  "startDate": "2025-04-10",
  "endDate": "2025-04-15",
  "days": [
    {
      "date": "2025-04-10",
      "summary": "Fushimi Inari & Gion",
      "items": [
        {
          "time": "09:00",
          "activity": "Climb Fushimi Inari Shrine",
          "location": "34.9671,135.7727"
        }
      ]
    }
  ]
}
'''
            }
          }
        ]
      };

      dioAdapter.onPost(
        '/chat/completions',
        (server) => server.reply(200, mockResponse),
        data: any,
        headers: any,
      );

      // Act
      final result = await service.generateItinerary('Plan a trip to Kyoto');

      // Assert
      expect(result.title, equals('Kyoto 5-Day Solo Trip'));
      expect(result.startDate, equals('2025-04-10'));
      expect(result.endDate, equals('2025-04-15'));
      expect(result.days, hasLength(1));
      expect(result.days.first.summary, equals('Fushimi Inari & Gion'));
      expect(result.days.first.items, hasLength(1));
      expect(result.days.first.items.first.activity, equals('Climb Fushimi Inari Shrine'));
    });

    test('should throw AuthenticationError for 401 response', () async {
      // Arrange
      dioAdapter.onPost(
        '/chat/completions',
        (server) => server.reply(401, {'error': 'Invalid API key'}),
        data: any,
        headers: any,
      );

      // Act & Assert
      expect(
        () => service.generateItinerary('Plan a trip to Kyoto'),
        throwsA(isA<AuthenticationError>()),
      );
    });

    test('should throw RateLimitError for 429 response', () async {
      // Arrange
      dioAdapter.onPost(
        '/chat/completions',
        (server) => server.reply(429, {'error': 'Rate limit exceeded'}),
        data: any,
        headers: any,
      );

      // Act & Assert
      expect(
        () => service.generateItinerary('Plan a trip to Kyoto'),
        throwsA(isA<RateLimitError>()),
      );
    });

    test('should throw InvalidJsonError for malformed JSON response', () async {
      // Arrange
      const mockResponse = {
        'choices': [
          {
            'message': {
              'content': 'Invalid JSON content'
            }
          }
        ]
      };

      dioAdapter.onPost(
        '/chat/completions',
        (server) => server.reply(200, mockResponse),
        data: any,
        headers: any,
      );

      // Act & Assert
      expect(
        () => service.generateItinerary('Plan a trip to Kyoto'),
        throwsA(isA<InvalidJsonError>()),
      );
    });

    test('should throw InvalidItineraryError for missing required fields', () async {
      // Arrange
      const mockResponse = {
        'choices': [
          {
            'message': {
              'content': '''
{
  "title": "Test Trip",
  "startDate": "2025-04-10"
}
'''
            }
          }
        ]
      };

      dioAdapter.onPost(
        '/chat/completions',
        (server) => server.reply(200, mockResponse),
        data: any,
        headers: any,
      );

      // Act & Assert
      expect(
        () => service.generateItinerary('Plan a trip to Kyoto'),
        throwsA(isA<InvalidItineraryError>()),
      );
    });

    test('should throw NetworkError for connection timeout', () async {
      // Arrange
      dioAdapter.onPost(
        '/chat/completions',
        (server) => server.timeout(),
        data: any,
        headers: any,
      );

      // Act & Assert
      expect(
        () => service.generateItinerary('Plan a trip to Kyoto'),
        throwsA(isA<NetworkError>()),
      );
    });

    test('should throw ServerError for 500 response', () async {
      // Arrange
      dioAdapter.onPost(
        '/chat/completions',
        (server) => server.reply(500, {'error': 'Internal server error'}),
        data: any,
        headers: any,
      );

      // Act & Assert
      expect(
        () => service.generateItinerary('Plan a trip to Kyoto'),
        throwsA(isA<ServerError>()),
      );
    });

    test('should handle empty choices array', () async {
      // Arrange
      const mockResponse = {
        'choices': []
      };

      dioAdapter.onPost(
        '/chat/completions',
        (server) => server.reply(200, mockResponse),
        data: any,
        headers: any,
      );

      // Act & Assert
      expect(
        () => service.generateItinerary('Plan a trip to Kyoto'),
        throwsA(isA<InvalidJsonError>()),
      );
    });

    test('should handle missing message in response', () async {
      // Arrange
      const mockResponse = {
        'choices': [
          {
            'other_field': 'value'
          }
        ]
      };

      dioAdapter.onPost(
        '/chat/completions',
        (server) => server.reply(200, mockResponse),
        data: any,
        headers: any,
      );

      // Act & Assert
      expect(
        () => service.generateItinerary('Plan a trip to Kyoto'),
        throwsA(isA<InvalidJsonError>()),
      );
    });

    test('should handle empty content in response', () async {
      // Arrange
      const mockResponse = {
        'choices': [
          {
            'message': {
              'content': ''
            }
          }
        ]
      };

      dioAdapter.onPost(
        '/chat/completions',
        (server) => server.reply(200, mockResponse),
        data: any,
        headers: any,
      );

      // Act & Assert
      expect(
        () => service.generateItinerary('Plan a trip to Kyoto'),
        throwsA(isA<InvalidJsonError>()),
      );
    });

    test('should validate request payload structure', () async {
      // Arrange
      const mockResponse = {
        'choices': [
          {
            'message': {
              'content': '''
{
  "title": "Test Trip",
  "startDate": "2025-04-10",
  "endDate": "2025-04-15",
  "days": []
}
'''
            }
          }
        ]
      };

      dioAdapter.onPost(
        '/chat/completions',
        (server) {
          // Verify request structure
          final requestData = server.requestOptions.data as Map<String, dynamic>;
          expect(requestData['model'], equals('gpt-4o-mini'));
          expect(requestData['messages'], isA<List>());
          expect(requestData['messages'], hasLength(2));
          expect(requestData['messages'][0]['role'], equals('system'));
          expect(requestData['messages'][1]['role'], equals('user'));
          expect(requestData['messages'][1]['content'], equals('Plan a trip to Kyoto'));
          expect(requestData['response_format'], equals({'type': 'json_object'}));
          
          server.reply(200, mockResponse);
        },
        data: any,
        headers: any,
      );

      // Act
      await service.generateItinerary('Plan a trip to Kyoto');

      // Assert - Request validation is done in the onPost callback
    });

    test('should handle complex itinerary with multiple days and activities', () async {
      // Arrange
      const mockResponse = {
        'choices': [
          {
            'message': {
              'content': '''
{
  "title": "Tokyo 7-Day Adventure",
  "startDate": "2025-05-01",
  "endDate": "2025-05-07",
  "days": [
    {
      "date": "2025-05-01",
      "summary": "Arrival and Shibuya",
      "items": [
        {
          "time": "14:00",
          "activity": "Check into hotel",
          "location": "Shibuya, Tokyo, Japan"
        },
        {
          "time": "16:00",
          "activity": "Visit Shibuya Crossing",
          "location": "Shibuya Crossing, Tokyo, Japan"
        }
      ]
    },
    {
      "date": "2025-05-02",
      "summary": "Traditional Tokyo",
      "items": [
        {
          "time": "09:00",
          "activity": "Visit Senso-ji Temple",
          "location": "Asakusa, Tokyo, Japan"
        }
      ]
    }
  ]
}
'''
            }
          }
        ]
      };

      dioAdapter.onPost(
        '/chat/completions',
        (server) => server.reply(200, mockResponse),
        data: any,
        headers: any,
      );

      // Act
      final result = await service.generateItinerary('Plan a 7-day trip to Tokyo');

      // Assert
      expect(result.title, equals('Tokyo 7-Day Adventure'));
      expect(result.startDate, equals('2025-05-01'));
      expect(result.endDate, equals('2025-05-07'));
      expect(result.days, hasLength(2));
      
      final firstDay = result.days.first;
      expect(firstDay.date, equals('2025-05-01'));
      expect(firstDay.summary, equals('Arrival and Shibuya'));
      expect(firstDay.items, hasLength(2));
      expect(firstDay.items.first.activity, equals('Check into hotel'));
      
      final secondDay = result.days[1];
      expect(secondDay.date, equals('2025-05-02'));
      expect(secondDay.summary, equals('Traditional Tokyo'));
      expect(secondDay.items, hasLength(1));
    });
  });
}













