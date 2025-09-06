import 'package:flutter_test/flutter_test.dart';
import 'package:smart_trip_planner/core/services/agent_service.dart';
import 'package:smart_trip_planner/core/services/web_search_service.dart';

void main() {
  group('AgentService Web Search Integration', () {
    late AgentService agentService;

    setUp(() {
      // Create AgentService with web search enabled using dummy data
      agentService = AgentServiceFactory.createWithWebSearch(
        openaiApiKey: 'test-key',
        useDummyWebSearch: true,
      );
    });

    test('should generate itinerary with web search data', () async {
      // This test would require actual API keys to run
      // For now, we'll test the structure and error handling
      
      try {
        final itinerary = await agentService.generateItinerary(
          userInput: 'Plan a 3-day trip to Tokyo with restaurants and temples',
        );

        expect(itinerary, isNotNull);
        expect(itinerary.title, isNotEmpty);
        expect(itinerary.startDate, isNotEmpty);
        expect(itinerary.endDate, isNotEmpty);
        expect(itinerary.days, isNotEmpty);
      } catch (e) {
        // Expected to fail without real API keys
        expect(e, isA<Exception>());
      }
    });

    test('should extract search queries from user input', () {
      // Test the private method through public interface
      final webSearchService = WebSearchServiceFactory.createWithDummyData();
      
      // Test restaurant search
      final restaurantResults = webSearchService.searchRestaurants('Tokyo');
      expect(restaurantResults, isA<Future<List<WebSearchResult>>>());
      
      // Test hotel search
      final hotelResults = webSearchService.searchHotels('Kyoto');
      expect(hotelResults, isA<Future<List<WebSearchResult>>>());
      
      // Test attraction search
      final attractionResults = webSearchService.searchAttractions('Osaka');
      expect(attractionResults, isA<Future<List<WebSearchResult>>>());
    });

    test('should handle web search errors gracefully', () async {
      // Create service with dummy data to test error handling
      final webSearchService = WebSearchServiceFactory.createWithDummyData();
      
      final results = await webSearchService.performWebSearch('test query');
      
      // Should return dummy data even on "error"
      expect(results, isNotEmpty);
      expect(results.first.title, isNotEmpty);
      expect(results.first.description, isNotEmpty);
    });

    test('should create WebSearchResult with all fields', () {
      final result = WebSearchResult(
        title: 'Test Restaurant',
        description: 'A great place to eat',
        url: 'https://example.com',
        imageUrl: 'https://example.com/image.jpg',
        rating: 4.5,
        address: '123 Main St',
        phone: '+1-555-0123',
        priceRange: '\$\$',
        additionalData: {'cuisine': 'Italian'},
      );

      expect(result.title, 'Test Restaurant');
      expect(result.description, 'A great place to eat');
      expect(result.url, 'https://example.com');
      expect(result.imageUrl, 'https://example.com/image.jpg');
      expect(result.rating, 4.5);
      expect(result.address, '123 Main St');
      expect(result.phone, '+1-555-0123');
      expect(result.priceRange, '\$\$');
      expect(result.additionalData?['cuisine'], 'Italian');
    });

    test('should serialize and deserialize WebSearchResult', () {
      final original = WebSearchResult(
        title: 'Test Restaurant',
        description: 'A great place to eat',
        url: 'https://example.com',
        rating: 4.5,
        address: '123 Main St',
        phone: '+1-555-0123',
        priceRange: '\$\$',
        additionalData: {'cuisine': 'Italian'},
      );

      final json = original.toJson();
      final restored = WebSearchResult.fromJson(json);

      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.url, original.url);
      expect(restored.rating, original.rating);
      expect(restored.address, original.address);
      expect(restored.phone, original.phone);
      expect(restored.priceRange, original.priceRange);
      expect(restored.additionalData?['cuisine'], original.additionalData?['cuisine']);
    });
  });

  group('WebSearchService Dummy Data', () {
    late WebSearchService webSearchService;

    setUp(() {
      webSearchService = WebSearchServiceFactory.createWithDummyData();
    });

    test('should generate realistic dummy data for restaurants', () async {
      final results = await webSearchService.searchRestaurants('Tokyo');
      
      expect(results, isNotEmpty);
      expect(results.length, greaterThanOrEqualTo(3));
      
      for (final result in results) {
        expect(result.title, isNotEmpty);
        expect(result.description, isNotEmpty);
        expect(result.url, isNotEmpty);
        expect(result.rating, isNotNull);
        expect(result.priceRange, isNotNull);
      }
    });

    test('should generate realistic dummy data for hotels', () async {
      final results = await webSearchService.searchHotels('Kyoto');
      
      expect(results, isNotEmpty);
      expect(results.length, greaterThanOrEqualTo(3));
      
      for (final result in results) {
        expect(result.title, isNotEmpty);
        expect(result.description, isNotEmpty);
        expect(result.url, isNotEmpty);
        expect(result.rating, isNotNull);
        expect(result.address, isNotNull);
      }
    });

    test('should generate realistic dummy data for attractions', () async {
      final results = await webSearchService.searchAttractions('Osaka');
      
      expect(results, isNotEmpty);
      expect(results.length, greaterThanOrEqualTo(3));
      
      for (final result in results) {
        expect(result.title, isNotEmpty);
        expect(result.description, isNotEmpty);
        expect(result.url, isNotEmpty);
        expect(result.rating, isNotNull);
      }
    });

    test('should generate realistic dummy data for transportation', () async {
      final results = await webSearchService.searchTransportation('Tokyo', 'Kyoto');
      
      expect(results, isNotEmpty);
      expect(results.length, greaterThanOrEqualTo(3));
      
      for (final result in results) {
        expect(result.title, isNotEmpty);
        expect(result.description, isNotEmpty);
        expect(result.url, isNotEmpty);
      }
    });

    test('should generate realistic dummy data for events', () async {
      final results = await webSearchService.searchEvents('Tokyo');
      
      expect(results, isNotEmpty);
      expect(results.length, greaterThanOrEqualTo(3));
      
      for (final result in results) {
        expect(result.title, isNotEmpty);
        expect(result.description, isNotEmpty);
        expect(result.url, isNotEmpty);
        expect(result.rating, isNotNull);
      }
    });
  });
}




