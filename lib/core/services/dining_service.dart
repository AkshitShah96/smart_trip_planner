import 'dart:convert';
import 'package:dio/dio.dart';
import '../errors/itinerary_errors.dart';
import 'web_search_service.dart';

class DiningSuggestion {
  final String name;
  final String description;
  final String address;
  final String? phone;
  final double? rating;
  final String? priceRange;
  final String? cuisine;
  final String? hours;
  final String? website;
  final List<String>? specialties;
  final Map<String, dynamic>? additionalInfo;

  const DiningSuggestion({
    required this.name,
    required this.description,
    required this.address,
    this.phone,
    this.rating,
    this.priceRange,
    this.cuisine,
    this.hours,
    this.website,
    this.specialties,
    this.additionalInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'address': address,
      'phone': phone,
      'rating': rating,
      'priceRange': priceRange,
      'cuisine': cuisine,
      'hours': hours,
      'website': website,
      'specialties': specialties,
      'additionalInfo': additionalInfo,
    };
  }

  factory DiningSuggestion.fromJson(Map<String, dynamic> json) {
    return DiningSuggestion(
      name: json['name'] as String,
      description: json['description'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String?,
      rating: json['rating'] as double?,
      priceRange: json['priceRange'] as String?,
      cuisine: json['cuisine'] as String?,
      hours: json['hours'] as String?,
      website: json['website'] as String?,
      specialties: json['specialties'] != null 
          ? List<String>.from(json['specialties']) 
          : null,
      additionalInfo: json['additionalInfo'] as Map<String, dynamic>?,
    );
  }
}

class DiningService {
  final Dio _dio;
  final WebSearchService _webSearchService;

  DiningService({
    Dio? dio,
    WebSearchService? webSearchService,
  }) : _dio = dio ?? Dio(),
       _webSearchService = webSearchService ?? WebSearchServiceFactory.createAuto() {
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  Future<List<DiningSuggestion>> getDiningSuggestions({
    required String location,
    String? cuisine,
    String? priceRange,
    int limit = 10,
  }) async {
    try {
      final queries = _buildDiningQueries(location, cuisine, priceRange);
      final allSuggestions = <DiningSuggestion>[];

      for (final query in queries) {
        final searchResults = await _webSearchService.performWebSearch(query);
        final suggestions = _parseDiningResults(searchResults, location);
        allSuggestions.addAll(suggestions);
      }

      final uniqueSuggestions = _removeDuplicates(allSuggestions);
      final sortedSuggestions = _sortByRating(uniqueSuggestions);

      return sortedSuggestions.take(limit).toList();
    } catch (e) {
      throw UnknownError('Failed to get dining suggestions: ${e.toString()}');
    }
  }

  Future<DiningSuggestion?> getRestaurantDetails({
    required String restaurantName,
    required String location,
  }) async {
    try {
      final query = '$restaurantName $location restaurant details menu hours';
      final searchResults = await _webSearchService.performWebSearch(query);
      
      if (searchResults.isNotEmpty) {
        return _parseRestaurantDetails(searchResults.first, restaurantName);
      }
      
      return null;
    } catch (e) {
      throw UnknownError('Failed to get restaurant details: ${e.toString()}');
    }
  }

  Future<List<DiningSuggestion>> getMealSuggestions({
    required String location,
    required String mealTime, // breakfast, lunch, dinner
    String? cuisine,
  }) async {
    try {
      final queries = _buildMealQueries(location, mealTime, cuisine);
      final allSuggestions = <DiningSuggestion>[];

      for (final query in queries) {
        final searchResults = await _webSearchService.performWebSearch(query);
        final suggestions = _parseDiningResults(searchResults, location);
        allSuggestions.addAll(suggestions);
      }

      final uniqueSuggestions = _removeDuplicates(allSuggestions);
      return _sortByRating(uniqueSuggestions).take(5).toList();
    } catch (e) {
      throw UnknownError('Failed to get meal suggestions: ${e.toString()}');
    }
  }

  List<String> _buildDiningQueries(String location, String? cuisine, String? priceRange) {
    final queries = <String>[];
    
    queries.add('best restaurants in $location');
    queries.add('top rated restaurants $location');
    
    if (cuisine != null) {
      queries.add('best $cuisine restaurants in $location');
      queries.add('top rated $cuisine food $location');
    }
    
    if (priceRange != null) {
      queries.add('$priceRange restaurants in $location');
    }
    
    queries.add('local food $location');
    queries.add('traditional restaurants $location');
    queries.add('fine dining $location');
    queries.add('casual dining $location');
    
    return queries;
  }

  List<String> _buildMealQueries(String location, String mealTime, String? cuisine) {
    final queries = <String>[];
    
    switch (mealTime.toLowerCase()) {
      case 'breakfast':
        queries.add('best breakfast places in $location');
        queries.add('breakfast restaurants $location');
        queries.add('morning food $location');
        break;
      case 'lunch':
        queries.add('best lunch spots in $location');
        queries.add('lunch restaurants $location');
        queries.add('quick lunch $location');
        break;
      case 'dinner':
        queries.add('best dinner restaurants in $location');
        queries.add('dinner places $location');
        queries.add('evening dining $location');
        break;
    }
    
    if (cuisine != null) {
      queries.add('$cuisine $mealTime $location');
    }
    
    return queries;
  }

  List<DiningSuggestion> _parseDiningResults(List<WebSearchResult> results, String location) {
    final suggestions = <DiningSuggestion>[];
    
    for (final result in results) {
      try {
        final suggestion = _parseDiningResult(result, location);
        if (suggestion != null) {
          suggestions.add(suggestion);
        }
      } catch (e) {
        continue;
      }
    }
    
    return suggestions;
  }

  DiningSuggestion? _parseDiningResult(WebSearchResult result, String location) {
    try {
      final name = _extractRestaurantName(result.title);
      if (name == null || name.isEmpty) return null;

      final rating = _extractRating(result.description, result.additionalData);
      
      final priceRange = _extractPriceRange(result.description);
      
      final cuisine = _extractCuisine(result.description);
      
      final phone = _extractPhone(result.description, result.additionalData);
      
      final hours = _extractHours(result.description);
      
      final specialties = _extractSpecialties(result.description);

      return DiningSuggestion(
        name: name,
        description: result.description,
        address: result.address ?? location,
        phone: phone,
        rating: rating,
        priceRange: priceRange,
        cuisine: cuisine,
        hours: hours,
        website: result.url,
        specialties: specialties,
        additionalInfo: result.additionalData,
      );
    } catch (e) {
      return null;
    }
  }

  DiningSuggestion? _parseRestaurantDetails(WebSearchResult result, String restaurantName) {
    try {
      final rating = _extractRating(result.description, result.additionalData);
      final priceRange = _extractPriceRange(result.description);
      final cuisine = _extractCuisine(result.description);
      final phone = _extractPhone(result.description, result.additionalData);
      final hours = _extractHours(result.description);
      final specialties = _extractSpecialties(result.description);

      return DiningSuggestion(
        name: restaurantName,
        description: result.description,
        address: result.address ?? 'Address not available',
        phone: phone,
        rating: rating,
        priceRange: priceRange,
        cuisine: cuisine,
        hours: hours,
        website: result.url,
        specialties: specialties,
        additionalInfo: result.additionalData,
      );
    } catch (e) {
      return null;
    }
  }

  String? _extractRestaurantName(String title) {
    final cleanTitle = title
        .replaceAll(RegExp(r'\s*-\s*.*$'), '')
        .replaceAll(RegExp(r'\s*\|\s*.*$'), '')
        .replaceAll(RegExp(r'\s*Restaurant.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*Cafe.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*Bar.*$', caseSensitive: false), '')
        .trim();
    
    return cleanTitle.isNotEmpty ? cleanTitle : null;
  }

  double? _extractRating(String text, Map<String, dynamic>? additionalData) {
    if (additionalData != null) {
      final rating = additionalData['rating'];
      if (rating is num) return rating.toDouble();
    }

    final ratingPattern = RegExp(r'(\d+\.?\d*)\s*(?:stars?|/5|/10)');
    final match = ratingPattern.firstMatch(text.toLowerCase());
    if (match != null) {
      final rating = double.tryParse(match.group(1)!);
      if (rating != null && rating <= 5.0) return rating;
    }

    return null;
  }

  String? _extractPriceRange(String text) {
    final pricePatterns = [
      RegExp(r'\$\$?\$?\$?', caseSensitive: false),
      RegExp(r'(?:budget|cheap|affordable|moderate|expensive|luxury)', caseSensitive: false),
      RegExp(r'(?:under|below)\s*\$?\d+', caseSensitive: false),
    ];

    for (final pattern in pricePatterns) {
      final match = pattern.firstMatch(text.toLowerCase());
      if (match != null) {
        return match.group(0)?.toUpperCase();
      }
    }

    return null;
  }

  String? _extractCuisine(String text) {
    final cuisines = [
      'italian', 'chinese', 'japanese', 'mexican', 'indian', 'thai',
      'french', 'mediterranean', 'american', 'korean', 'vietnamese',
      'greek', 'spanish', 'german', 'british', 'middle eastern',
      'seafood', 'steakhouse', 'vegetarian', 'vegan', 'fusion'
    ];

    final textLower = text.toLowerCase();
    for (final cuisine in cuisines) {
      if (textLower.contains(cuisine)) {
        return cuisine.toUpperCase();
      }
    }

    return null;
  }

  String? _extractPhone(String text, Map<String, dynamic>? additionalData) {
    if (additionalData != null) {
      final phone = additionalData['phone'];
      if (phone is String) return phone;
    }

    final phonePattern = RegExp(r'\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}');
    final match = phonePattern.firstMatch(text);
    return match?.group(0);
  }

  String? _extractHours(String text) {
    final hoursPattern = RegExp(r'(?:open|hours?)\s*:?\s*([^.]*)', caseSensitive: false);
    final match = hoursPattern.firstMatch(text);
    if (match != null) {
      final hours = match.group(1)?.trim();
      if (hours != null && hours.isNotEmpty) {
        return hours;
      }
    }
    return null;
  }

  List<String>? _extractSpecialties(String text) {
    final specialties = <String>[];
    final specialtyKeywords = [
      'signature dish', 'specialty', 'famous for', 'known for',
      'best known for', 'specializes in', 'expert in'
    ];

    final textLower = text.toLowerCase();
    for (final keyword in specialtyKeywords) {
      if (textLower.contains(keyword)) {
        final index = textLower.indexOf(keyword);
        final afterKeyword = text.substring(index + keyword.length).trim();
        final endIndex = afterKeyword.indexOf('.');
        final specialty = endIndex > 0 
            ? afterKeyword.substring(0, endIndex).trim()
            : afterKeyword.trim();
        
        if (specialty.isNotEmpty && specialty.length < 100) {
          specialties.add(specialty);
        }
      }
    }

    return specialties.isNotEmpty ? specialties : null;
  }

  /// Remove duplicate dining suggestions
  List<DiningSuggestion> _removeDuplicates(List<DiningSuggestion> suggestions) {
    final seen = <String>{};
    return suggestions.where((suggestion) {
      final key = suggestion.name.toLowerCase();
      if (seen.contains(key)) {
        return false;
      }
      seen.add(key);
      return true;
    }).toList();
  }

  /// Sort suggestions by rating (highest first)
  List<DiningSuggestion> _sortByRating(List<DiningSuggestion> suggestions) {
    suggestions.sort((a, b) {
      final ratingA = a.rating ?? 0.0;
      final ratingB = b.rating ?? 0.0;
      return ratingB.compareTo(ratingA);
    });
    return suggestions;
  }
}

/// Factory class for creating DiningService instances
class DiningServiceFactory {
  static DiningService createService({
    Dio? dio,
    WebSearchService? webSearchService,
  }) {
    return DiningService(
      dio: dio,
      webSearchService: webSearchService,
    );
  }

  static DiningService createWithWebSearch({
    bool useDummyWebSearch = false,
  }) {
    final webSearchService = useDummyWebSearch 
        ? WebSearchServiceFactory.createWithDummyData()
        : WebSearchServiceFactory.createAuto();

    return createService(webSearchService: webSearchService);
  }
}

