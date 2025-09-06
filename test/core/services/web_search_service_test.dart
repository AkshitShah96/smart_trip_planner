import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:smart_trip_planner/core/services/web_search_service.dart';

import 'web_search_service_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  group('WebSearchService', () {
    late WebSearchService webSearchService;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      webSearchService = WebSearchService(dio: mockDio, useDummyData: true);
    });

    group('Dummy Data Generation', () {
      test('should generate dummy restaurants for restaurant queries', () async {
        final results = await webSearchService.performWebSearch('restaurants in Tokyo');
        
        expect(results, isNotEmpty);
        expect(results.first.title, contains('Sukiyabashi Jiro'));
        expect(results.first.rating, isNotNull);
        expect(results.first.priceRange, isNotNull);
      });

      test('should generate dummy hotels for hotel queries', () async {
        final results = await webSearchService.performWebSearch('hotels in Kyoto');
        
        expect(results, isNotEmpty);
        expect(results.first.title, contains('Ritz-Carlton'));
        expect(results.first.rating, isNotNull);
        expect(results.first.address, isNotNull);
      });

      test('should generate dummy attractions for attraction queries', () async {
        final results = await webSearchService.performWebSearch('attractions in Kyoto');
        
        expect(results, isNotEmpty);
        expect(results.first.title, contains('Fushimi Inari'));
        expect(results.first.rating, isNotNull);
      });

      test('should generate dummy transportation for transport queries', () async {
        final results = await webSearchService.performWebSearch('transportation in Tokyo');
        
        expect(results, isNotEmpty);
        expect(results.first.title, contains('JR Pass'));
        expect(results.first.description, isNotEmpty);
      });

      test('should generate dummy events for event queries', () async {
        final results = await webSearchService.performWebSearch('events in Tokyo');
        
        expect(results, isNotEmpty);
        expect(results.first.title, contains('Cherry Blossom'));
        expect(results.first.rating, isNotNull);
      });
    });

    group('Specialized Search Methods', () {
      test('should search for restaurants with location', () async {
        final results = await webSearchService.searchRestaurants('Tokyo');
        
        expect(results, isNotEmpty);
        expect(results.every((r) => r.title.isNotEmpty), isTrue);
        expect(results.every((r) => r.description.isNotEmpty), isTrue);
      });

      test('should search for hotels with location and near parameter', () async {
        final results = await webSearchService.searchHotels('Kyoto', near: 'Fushimi Inari');
        
        expect(results, isNotEmpty);
        expect(results.every((r) => r.title.isNotEmpty), isTrue);
      });

      test('should search for attractions with location', () async {
        final results = await webSearchService.searchAttractions('Osaka');
        
        expect(results, isNotEmpty);
        expect(results.every((r) => r.title.isNotEmpty), isTrue);
      });

      test('should search for transportation between locations', () async {
        final results = await webSearchService.searchTransportation('Tokyo', 'Kyoto');
        
        expect(results, isNotEmpty);
        expect(results.every((r) => r.title.isNotEmpty), isTrue);
      });

      test('should search for events with location and date', () async {
        final results = await webSearchService.searchEvents('Tokyo', date: '2024-03-15');
        
        expect(results, isNotEmpty);
        expect(results.every((r) => r.title.isNotEmpty), isTrue);
      });
    });

    group('WebSearchResult Model', () {
      test('should create WebSearchResult from JSON', () {
        final json = {
          'title': 'Test Restaurant',
          'description': 'A great place to eat',
          'url': 'https://example.com',
          'rating': 4.5,
          'address': '123 Main St',
          'phone': '+1-555-0123',
          'priceRange': '$$',
          'additionalData': {'cuisine': 'Italian'},
        };

        final result = WebSearchResult.fromJson(json);

        expect(result.title, 'Test Restaurant');
        expect(result.description, 'A great place to eat');
        expect(result.url, 'https://example.com');
        expect(result.rating, 4.5);
        expect(result.address, '123 Main St');
        expect(result.phone, '+1-555-0123');
        expect(result.priceRange, '$$');
        expect(result.additionalData?['cuisine'], 'Italian');
      });

      test('should convert WebSearchResult to JSON', () {
        final result = WebSearchResult(
          title: 'Test Restaurant',
          description: 'A great place to eat',
          url: 'https://example.com',
          rating: 4.5,
          address: '123 Main St',
          phone: '+1-555-0123',
          priceRange: '$$',
          additionalData: {'cuisine': 'Italian'},
        );

        final json = result.toJson();

        expect(json['title'], 'Test Restaurant');
        expect(json['description'], 'A great place to eat');
        expect(json['url'], 'https://example.com');
        expect(json['rating'], 4.5);
        expect(json['address'], '123 Main St');
        expect(json['phone'], '+1-555-0123');
        expect(json['priceRange'], '$$');
        expect(json['additionalData']['cuisine'], 'Italian');
      });
    });

    group('Error Handling', () {
      test('should return dummy data when API fails', () async {
        when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: ''),
          ),
        ));

        final results = await webSearchService.performWebSearch('test query');
        
        // Should fallback to dummy data
        expect(results, isNotEmpty);
      });
    });
  });

  group('WebSearchServiceFactory', () {
    test('should create service with API keys', () {
      final service = WebSearchServiceFactory.createWithApiKeys();
      expect(service, isA<WebSearchService>());
    });

    test('should create service with dummy data', () {
      final service = WebSearchServiceFactory.createWithDummyData();
      expect(service, isA<WebSearchService>());
    });

    test('should create auto service', () {
      final service = WebSearchServiceFactory.createAuto();
      expect(service, isA<WebSearchService>());
    });
  });
}




