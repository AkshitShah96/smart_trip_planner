import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:smart_trip_planner/core/services/agent_service.dart';
import 'package:smart_trip_planner/core/errors/itinerary_errors.dart';
import 'package:smart_trip_planner/domain/entities/chat_message.dart';

import 'agent_service_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  group('AgentService', () {
    late AgentService agentService;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      agentService = AgentService(
        openaiApiKey: 'test-api-key',
        useOpenAI: true,
        dio: mockDio,
      );
    });

    group('Input Validation', () {
      test('should throw error for empty user input', () async {
        expect(
          () => agentService.generateItinerary(userInput: ''),
          throwsA(isA<InvalidItineraryError>()),
        );
      });

      test('should throw error for too long user input', () async {
        final longInput = 'a' * 1001;
        expect(
          () => agentService.generateItinerary(userInput: longInput),
          throwsA(isA<InvalidItineraryError>()),
        );
      });
    });

    group('OpenAI Integration', () {
      test('should call OpenAI API with correct parameters', () async {
        // Mock successful response
        when(mockDio.post(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => Response(
          data: {
            'choices': [
              {
                'message': {
                  'function_call': {
                    'arguments': json.encode({
                      'title': 'Test Trip',
                      'startDate': '2024-01-01',
                      'endDate': '2024-01-03',
                      'days': [
                        {
                          'date': '2024-01-01',
                          'summary': 'Day 1',
                          'items': [
                            {
                              'time': '09:00',
                              'activity': 'Test Activity',
                              'location': 'Test Location',
                            }
                          ]
                        }
                      ]
                    })
                  }
                }
              }
            ]
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));

        final result = await agentService.generateItinerary(
          userInput: 'Plan a trip to Paris',
        );

        expect(result.title, 'Test Trip');
        expect(result.startDate, '2024-01-01');
        expect(result.endDate, '2024-01-03');
        expect(result.days.length, 1);
      });

      test('should handle OpenAI API errors', () async {
        when(mockDio.post(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: ''),
          ),
        ));

        expect(
          () => agentService.generateItinerary(userInput: 'Test input'),
          throwsA(isA<AuthenticationError>()),
        );
      });

      test('should handle rate limit errors', () async {
        when(mockDio.post(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            statusCode: 429,
            requestOptions: RequestOptions(path: ''),
          ),
        ));

        expect(
          () => agentService.generateItinerary(userInput: 'Test input'),
          throwsA(isA<RateLimitError>()),
        );
      });
    });

    group('JSON Schema Validation', () {
      test('should validate required fields', () async {
        when(mockDio.post(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => Response(
          data: {
            'choices': [
              {
                'message': {
                  'function_call': {
                    'arguments': json.encode({
                      'title': 'Test Trip',
                      'startDate': '2024-01-01',
                      'endDate': '2024-01-03',
                      'days': [
                        {
                          'date': '2024-01-01',
                          'summary': 'Day 1',
                          'items': [
                            {
                              'time': '09:00',
                              'activity': 'Test Activity',
                              'location': 'Test Location',
                            }
                          ]
                        }
                      ]
                    })
                  }
                }
              }
            ]
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));

        final result = await agentService.generateItinerary(
          userInput: 'Test input',
        );

        expect(result.title, isNotEmpty);
        expect(result.startDate, isNotEmpty);
        expect(result.endDate, isNotEmpty);
        expect(result.days, isNotEmpty);
      });

      test('should throw error for missing required fields', () async {
        when(mockDio.post(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => Response(
          data: {
            'choices': [
              {
                'message': {
                  'function_call': {
                    'arguments': json.encode({
                      'title': 'Test Trip',
                      // Missing startDate, endDate, days
                    })
                  }
                }
              }
            ]
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));

        expect(
          () => agentService.generateItinerary(userInput: 'Test input'),
          throwsA(isA<InvalidItineraryError>()),
        );
      });
    });

    group('Refinement', () {
      test('should handle refinement requests', () async {
        final previousItinerary = Itinerary(
          title: 'Original Trip',
          startDate: '2024-01-01',
          endDate: '2024-01-03',
          days: [],
        );

        when(mockDio.post(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => Response(
          data: {
            'choices': [
              {
                'message': {
                  'function_call': {
                    'arguments': json.encode({
                      'title': 'Updated Trip',
                      'startDate': '2024-01-01',
                      'endDate': '2024-01-03',
                      'days': [
                        {
                          'date': '2024-01-01',
                          'summary': 'Updated Day 1',
                          'items': [
                            {
                              'time': '10:00',
                              'activity': 'Updated Activity',
                              'location': 'Updated Location',
                            }
                          ]
                        }
                      ]
                    })
                  }
                }
              }
            ]
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));

        final result = await agentService.generateItinerary(
          userInput: 'Update the first day',
          previousItinerary: previousItinerary,
          isRefinement: true,
        );

        expect(result.title, 'Updated Trip');
        expect(result.days.first.summary, 'Updated Day 1');
      });
    });
  });

  group('AgentServiceFactory', () {
    test('should create OpenAI service', () {
      final service = AgentServiceFactory.createOpenAIService(
        apiKey: 'test-key',
      );
      expect(service, isA<AgentService>());
    });

    test('should create Gemini service', () {
      final service = AgentServiceFactory.createGeminiService(
        apiKey: 'test-key',
      );
      expect(service, isA<AgentService>());
    });

    test('should create service from config with OpenAI preference', () {
      final service = AgentServiceFactory.createFromConfig(
        openaiApiKey: 'test-openai-key',
        geminiApiKey: 'test-gemini-key',
        preferOpenAI: true,
      );
      expect(service, isA<AgentService>());
    });

    test('should throw error when no API key provided', () {
      expect(
        () => AgentServiceFactory.createFromConfig(),
        throwsA(isA<AuthenticationError>()),
      );
    });
  });
}




