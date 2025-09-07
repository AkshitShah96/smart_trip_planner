import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import '../errors/itinerary_errors.dart';

class WebSearchResult {
  final String title;
  final String description;
  final String url;
  final String? imageUrl;
  final double? rating;
  final String? address;
  final String? phone;
  final String? priceRange;
  final Map<String, dynamic>? additionalData;

  const WebSearchResult({
    required this.title,
    required this.description,
    required this.url,
    this.imageUrl,
    this.rating,
    this.address,
    this.phone,
    this.priceRange,
    this.additionalData,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'url': url,
      'imageUrl': imageUrl,
      'rating': rating,
      'address': address,
      'phone': phone,
      'priceRange': priceRange,
      'additionalData': additionalData,
    };
  }

  factory WebSearchResult.fromJson(Map<String, dynamic> json) {
    return WebSearchResult(
      title: json['title'] as String,
      description: json['description'] as String,
      url: json['url'] as String,
      imageUrl: json['imageUrl'] as String?,
      rating: json['rating'] as double?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      priceRange: json['priceRange'] as String?,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }
}

class WebSearchService {
  static const String _serpApiKey = String.fromEnvironment('SERP_API_KEY');
  static const String _googleSearchApiKey = String.fromEnvironment('GOOGLE_SEARCH_API_KEY');
  static const String _googleSearchEngineId = String.fromEnvironment('GOOGLE_SEARCH_ENGINE_ID');
  
  final Dio _dio;
  final bool _useDummyData;

  WebSearchService({
    Dio? dio,
    bool useDummyData = false,
  }) : _dio = dio ?? Dio(),
       _useDummyData = useDummyData {
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  Future<List<WebSearchResult>> performWebSearch(String query) async {
    try {
      if (_useDummyData || (!_hasApiKeys() && _useDummyData)) {
        return _generateDummyData(query);
      }

      if (_serpApiKey.isNotEmpty) {
        return await _searchWithSerpApi(query);
      } else if (_googleSearchApiKey.isNotEmpty && _googleSearchEngineId.isNotEmpty) {
        return await _searchWithGoogleCustomSearch(query);
      } else {
        return _generateDummyData(query);
      }
    } catch (e) {
      return _generateDummyData(query);
    }
  }

  Future<List<WebSearchResult>> searchRestaurants(String location) async {
    final query = 'best restaurants in $location';
    return await performWebSearch(query);
  }

  Future<List<WebSearchResult>> searchHotels(String location, {String? near}) async {
    final query = near != null 
        ? 'hotels near $near in $location'
        : 'best hotels in $location';
    return await performWebSearch(query);
  }

  Future<List<WebSearchResult>> searchAttractions(String location) async {
    final query = 'top attractions in $location';
    return await performWebSearch(query);
  }

  Future<List<WebSearchResult>> searchTransportation(String from, String to) async {
    final query = 'transportation from $from to $to';
    return await performWebSearch(query);
  }

  Future<List<WebSearchResult>> searchEvents(String location, {String? date}) async {
    final query = date != null 
        ? 'events in $location on $date'
        : 'upcoming events in $location';
    return await performWebSearch(query);
  }

  Future<List<WebSearchResult>> _searchWithSerpApi(String query) async {
    final response = await _dio.get(
      'https://serpapi.com/search',
      queryParameters: {
        'api_key': _serpApiKey,
        'q': query,
        'engine': 'google',
        'num': '10',
        'gl': 'us',
        'hl': 'en',
      },
    );

    return _parseSerpApiResponse(response.data);
  }

  Future<List<WebSearchResult>> _searchWithGoogleCustomSearch(String query) async {
    final response = await _dio.get(
      'https://www.googleapis.com/customsearch/v1',
      queryParameters: {
        'key': _googleSearchApiKey,
        'cx': _googleSearchEngineId,
        'q': query,
        'num': '10',
      },
    );

    return _parseGoogleCustomSearchResponse(response.data);
  }

  List<WebSearchResult> _parseSerpApiResponse(Map<String, dynamic> data) {
    final results = <WebSearchResult>[];
    final organicResults = data['organic_results'] as List?;

    if (organicResults == null) return results;

    for (final result in organicResults) {
      try {
        results.add(WebSearchResult(
          title: result['title'] as String? ?? '',
          description: result['snippet'] as String? ?? '',
          url: result['link'] as String? ?? '',
          imageUrl: result['thumbnail'] as String?,
          rating: _parseRating(result['rating']),
          address: result['address'] as String?,
          phone: result['phone'] as String?,
          priceRange: result['price'] as String?,
          additionalData: _extractAdditionalData(result),
        ));
      } catch (e) {
        continue;
      }
    }

    return results;
  }

  List<WebSearchResult> _parseGoogleCustomSearchResponse(Map<String, dynamic> data) {
    final results = <WebSearchResult>[];
    final items = data['items'] as List?;

    if (items == null) return results;

    for (final item in items) {
      try {
        results.add(WebSearchResult(
          title: item['title'] as String? ?? '',
          description: item['snippet'] as String? ?? '',
          url: item['link'] as String? ?? '',
          imageUrl: item['pagemap']?['cse_image']?[0]?['src'] as String?,
          additionalData: {
            'displayLink': item['displayLink'] as String?,
            'formattedUrl': item['formattedUrl'] as String?,
          },
        ));
      } catch (e) {
        continue;
      }
    }

    return results;
  }

  List<WebSearchResult> _generateDummyData(String query) {
    final queryLower = query.toLowerCase();
    
    if (queryLower.contains('restaurant')) {
      return _generateDummyRestaurants(query);
    } else if (queryLower.contains('hotel')) {
      return _generateDummyHotels(query);
    } else if (queryLower.contains('attraction') || queryLower.contains('temple') || queryLower.contains('shrine')) {
      return _generateDummyAttractions(query);
    } else if (queryLower.contains('transportation') || queryLower.contains('train') || queryLower.contains('bus')) {
      return _generateDummyTransportation(query);
    } else if (queryLower.contains('event')) {
      return _generateDummyEvents(query);
    } else {
      return _generateGenericDummyData(query);
    }
  }

  List<WebSearchResult> _generateDummyRestaurants(String query) {
    return [
      WebSearchResult(
        title: 'Sukiyabashi Jiro',
        description: 'World-famous sushi restaurant with Michelin stars',
        url: 'https://example.com/sukiyabashi-jiro',
        rating: 4.8,
        address: 'Tsukamoto Sogyo Building, 2-15-12 Ginza, Chuo City, Tokyo',
        phone: '+81-3-3535-3600',
        priceRange: '¥¥¥¥',
        additionalData: {'cuisine': 'Sushi', 'reservation_required': true},
      ),
      WebSearchResult(
        title: 'Narisawa',
        description: 'Innovative Japanese cuisine with seasonal ingredients',
        url: 'https://example.com/narisawa',
        rating: 4.6,
        address: '2-6-15 Minami Aoyama, Minato City, Tokyo',
        phone: '+81-3-5785-0799',
        priceRange: '¥¥¥¥',
        additionalData: {'cuisine': 'Japanese Fusion', 'reservation_required': true},
      ),
      WebSearchResult(
        title: 'Tsukiji Outer Market',
        description: 'Fresh seafood and traditional Japanese street food',
        url: 'https://example.com/tsukiji-market',
        rating: 4.4,
        address: '4-16-2 Tsukiji, Chuo City, Tokyo',
        phone: '+81-3-3542-1111',
        priceRange: '¥¥',
        additionalData: {'cuisine': 'Seafood', 'market': true},
      ),
    ];
  }

  List<WebSearchResult> _generateDummyHotels(String query) {
    return [
      WebSearchResult(
        title: 'The Ritz-Carlton Tokyo',
        description: 'Luxury hotel with stunning city views and exceptional service',
        url: 'https://example.com/ritz-carlton-tokyo',
        rating: 4.7,
        address: '9-7-1 Akasaka, Minato City, Tokyo',
        phone: '+81-3-3423-8000',
        priceRange: '¥¥¥¥¥',
        additionalData: {'stars': 5, 'amenities': ['Spa', 'Pool', 'Concierge']},
      ),
      WebSearchResult(
        title: 'Hotel Okura Tokyo',
        description: 'Classic luxury hotel with traditional Japanese hospitality',
        url: 'https://example.com/hotel-okura-tokyo',
        rating: 4.5,
        address: '2-10-4 Toranomon, Minato City, Tokyo',
        phone: '+81-3-3582-0111',
        priceRange: '¥¥¥¥',
        additionalData: {'stars': 5, 'amenities': ['Spa', 'Multiple Restaurants']},
      ),
      WebSearchResult(
        title: 'Shibuya Sky Hotel',
        description: 'Modern hotel in the heart of Shibuya with rooftop views',
        url: 'https://example.com/shibuya-sky-hotel',
        rating: 4.3,
        address: '2-1-1 Shibuya, Shibuya City, Tokyo',
        phone: '+81-3-5456-0111',
        priceRange: '¥¥¥',
        additionalData: {'stars': 4, 'amenities': ['Rooftop Bar', 'Fitness Center']},
      ),
    ];
  }

  List<WebSearchResult> _generateDummyAttractions(String query) {
    return [
      WebSearchResult(
        title: 'Fushimi Inari Shrine',
        description: 'Famous shrine with thousands of vermillion torii gates',
        url: 'https://example.com/fushimi-inari',
        rating: 4.6,
        address: '68 Fukakusa Yabunouchicho, Fushimi Ward, Kyoto',
        phone: '+81-75-641-7331',
        additionalData: {'type': 'Shrine', 'free_entry': true, 'best_time': 'Early morning'},
      ),
      WebSearchResult(
        title: 'Kiyomizu-dera Temple',
        description: 'Historic temple with panoramic views of Kyoto',
        url: 'https://example.com/kiyomizu-dera',
        rating: 4.5,
        address: '1-294 Kiyomizu, Higashiyama Ward, Kyoto',
        phone: '+81-75-551-1234',
        additionalData: {'type': 'Temple', 'entrance_fee': '¥400', 'unesco_site': true},
      ),
      WebSearchResult(
        title: 'Arashiyama Bamboo Grove',
        description: 'Peaceful bamboo forest perfect for morning walks',
        url: 'https://example.com/arashiyama-bamboo',
        rating: 4.4,
        address: 'Sagaogurayama Tabuchiyamacho, Ukyo Ward, Kyoto',
        additionalData: {'type': 'Natural Site', 'free_entry': true, 'best_time': 'Early morning'},
      ),
    ];
  }

  List<WebSearchResult> _generateDummyTransportation(String query) {
    return [
      WebSearchResult(
        title: 'JR Pass Information',
        description: 'Japan Rail Pass for unlimited travel on JR lines',
        url: 'https://example.com/jr-pass',
        rating: 4.5,
        additionalData: {'type': 'Rail Pass', 'validity': '7/14/21 days'},
      ),
      WebSearchResult(
        title: 'Tokyo Metro',
        description: 'Efficient subway system covering all major areas',
        url: 'https://example.com/tokyo-metro',
        rating: 4.3,
        additionalData: {'type': 'Subway', 'coverage': 'Tokyo area'},
      ),
      WebSearchResult(
        title: 'Shinkansen (Bullet Train)',
        description: 'High-speed rail connecting major cities',
        url: 'https://example.com/shinkansen',
        rating: 4.7,
        additionalData: {'type': 'High-speed Rail', 'speed': '320 km/h'},
      ),
    ];
  }

  List<WebSearchResult> _generateDummyEvents(String query) {
    return [
      WebSearchResult(
        title: 'Cherry Blossom Festival',
        description: 'Annual spring festival celebrating sakura season',
        url: 'https://example.com/cherry-blossom-festival',
        rating: 4.6,
        additionalData: {'season': 'Spring', 'free_event': true},
      ),
      WebSearchResult(
        title: 'Gion Matsuri',
        description: 'Traditional festival with elaborate floats and parades',
        url: 'https://example.com/gion-matsuri',
        rating: 4.8,
        additionalData: {'season': 'Summer', 'traditional': true},
      ),
      WebSearchResult(
        title: 'Tokyo International Film Festival',
        description: 'Premier film festival showcasing international cinema',
        url: 'https://example.com/tiff',
        rating: 4.4,
        additionalData: {'season': 'Autumn', 'ticketed_event': true},
      ),
    ];
  }

  List<WebSearchResult> _generateGenericDummyData(String query) {
    return [
      WebSearchResult(
        title: 'Search Result 1',
        description: 'This is a sample search result for: $query',
        url: 'https://example.com/result1',
        rating: 4.0,
      ),
      WebSearchResult(
        title: 'Search Result 2',
        description: 'Another sample search result for: $query',
        url: 'https://example.com/result2',
        rating: 3.8,
      ),
    ];
  }

  bool _hasApiKeys() {
    return _serpApiKey.isNotEmpty || 
           (_googleSearchApiKey.isNotEmpty && _googleSearchEngineId.isNotEmpty);
  }

  double? _parseRating(dynamic rating) {
    if (rating == null) return null;
    if (rating is double) return rating;
    if (rating is int) return rating.toDouble();
    if (rating is String) return double.tryParse(rating);
    return null;
  }

  Map<String, dynamic>? _extractAdditionalData(Map<String, dynamic> result) {
    final additionalData = <String, dynamic>{};
    
    if (result['cuisine'] != null) additionalData['cuisine'] = result['cuisine'];
    if (result['price'] != null) additionalData['price'] = result['price'];
    if (result['hours'] != null) additionalData['hours'] = result['hours'];
    if (result['amenities'] != null) additionalData['amenities'] = result['amenities'];
    if (result['type'] != null) additionalData['type'] = result['type'];
    
    return additionalData.isNotEmpty ? additionalData : null;
  }
}

class WebSearchServiceFactory {
  static WebSearchService createWithApiKeys() {
    return WebSearchService(useDummyData: false);
  }

  static WebSearchService createWithDummyData() {
    return WebSearchService(useDummyData: true);
  }

  static WebSearchService createAuto() {
    return WebSearchService(useDummyData: false);
  }
}




