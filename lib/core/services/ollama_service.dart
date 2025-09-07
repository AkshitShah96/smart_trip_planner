import 'dart:convert';
import 'package:dio/dio.dart';
import '../errors/itinerary_errors.dart';
import '../../data/models/itinerary.dart';
import '../../data/models/day_plan.dart';
import '../../data/models/day_item.dart';
import '../../domain/entities/chat_message.dart';
import 'web_search_service.dart';
import '../utils/json_validator.dart';
import '../models/itinerary_change.dart';
import '../utils/itinerary_diff_engine.dart';

class OllamaService {
  static const String _defaultBaseUrl = 'http://localhost:11434';
  
  final Dio _dio;
  final String _baseUrl;
  final String _model;
  final WebSearchService _webSearchService;
  final bool _enableWebSearch;

  OllamaService({
    String baseUrl = _defaultBaseUrl,
    String model = 'llama2',
    Dio? dio,
    WebSearchService? webSearchService,
    bool enableWebSearch = true,
  }) : _baseUrl = baseUrl,
       _model = model,
       _dio = dio ?? Dio(),
       _webSearchService = webSearchService ?? WebSearchServiceFactory.createAuto(),
       _enableWebSearch = enableWebSearch {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
    
    _dio.options.headers['Access-Control-Allow-Origin'] = '*';
    _dio.options.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS';
    _dio.options.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization';
  }

  Future<ItineraryDiffResult> generateItineraryWithDiff({
    required String userInput,
    Itinerary? previousItinerary,
    List<ChatMessage> chatHistory = const [],
    bool isRefinement = false,
  }) async {
    try {
      final newItinerary = await generateItinerary(
        userInput: userInput,
        previousItinerary: previousItinerary,
        chatHistory: chatHistory,
        isRefinement: isRefinement,
      );

      ItineraryDiff? diff;
      if (previousItinerary != null) {
        diff = ItineraryDiffEngine.compareItineraries(previousItinerary, newItinerary);
      }

      return ItineraryDiffResult(
        itinerary: newItinerary,
        diff: diff,
        hasChanges: diff?.hasChanges ?? false,
      );
    } catch (e) {
      throw UnknownError('Failed to generate itinerary with diff: ${e.toString()}');
    }
  }

  Future<Itinerary> generateItinerary({
    required String userInput,
    Itinerary? previousItinerary,
    List<ChatMessage> chatHistory = const [],
    bool isRefinement = false,
  }) async {
    try {
      _validateInput(userInput);
      
      Map<String, dynamic> webSearchData = {};
      if (_enableWebSearch) {
        webSearchData = await _performWebSearch(userInput, previousItinerary);
      }
      
      final prompt = _buildPrompt(
        userInput: userInput,
        previousItinerary: previousItinerary,
        chatHistory: chatHistory,
        isRefinement: isRefinement,
        webSearchData: webSearchData,
      );

      final response = await _callOllama(prompt);

      final validationResult = _parseAndValidateResponse(response, isRefinement);

      if (!validationResult.isValid) {
        throw InvalidJsonError('Invalid JSON response: ${validationResult.errors.join(', ')}');
      }

      final itinerary = validationResult.itinerary!;

      if (webSearchData.isNotEmpty) {
        return _enhanceItineraryWithWebData(itinerary, webSearchData);
      }

      return itinerary;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnknownError('Failed to generate itinerary: ${e.toString()}');
    }
  }

  String _buildPrompt({
    required String userInput,
    Itinerary? previousItinerary,
    required List<ChatMessage> chatHistory,
    required bool isRefinement,
    Map<String, dynamic> webSearchData = const {},
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('You are a professional travel planner. Generate detailed itineraries based on user requests.');
    buffer.writeln('Always respond with valid JSON matching the provided schema.');
    buffer.writeln();
    
    if (isRefinement && previousItinerary != null) {
      buffer.writeln('REFINEMENT REQUEST:');
      buffer.writeln('Current itinerary: ${previousItinerary.toJson()}');
      buffer.writeln('User request: $userInput');
      buffer.writeln('Please modify only the affected parts of the itinerary.');
    } else {
      buffer.writeln('NEW ITINERARY REQUEST:');
      buffer.writeln('User input: $userInput');
    }

    if (chatHistory.isNotEmpty) {
      buffer.writeln('\nCHAT HISTORY:');
      for (final message in chatHistory.take(10)) {
        buffer.writeln('${message.type.name.toUpperCase()}: ${message.content}');
      }
    }

    if (webSearchData.isNotEmpty) {
      buffer.writeln('\nREAL-TIME INFORMATION:');
      buffer.writeln('Use this current information to enhance the itinerary:');
      buffer.writeln(json.encode(webSearchData));
    }

    buffer.writeln('\nPlease generate a detailed travel itinerary in the following JSON format:');
    buffer.writeln(_getJsonSchema());
    buffer.writeln('\nReturn ONLY valid JSON, no additional text.');

    return buffer.toString();
  }

  Future<Map<String, dynamic>> _callOllama(String prompt) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/generate',
        data: {
          'model': _model,
          'prompt': prompt,
          'stream': false,
          'options': {
            'temperature': 0.7,
            'top_p': 0.9,
            'max_tokens': 2000,
          },
        },
      );

      return _extractOllamaResponse(response.data);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        throw const NetworkError('Ollama server not found. Please ensure Ollama is running on $_defaultBaseUrl');
      }
      rethrow;
    }
  }

  Map<String, dynamic> _extractOllamaResponse(Map<String, dynamic> data) {
    final response = data['response'] as String?;
    if (response == null || response.isEmpty) {
      throw const InvalidJsonError('No response from Ollama');
    }

    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) {
        throw const InvalidJsonError('No JSON found in Ollama response');
      }

      return json.decode(jsonMatch.group(0)!) as Map<String, dynamic>;
    } catch (e) {
      throw InvalidJsonError('Failed to parse Ollama response: $e');
    }
  }

  ValidationResult _parseAndValidateResponse(Map<String, dynamic> response, bool isRefinement) {
    try {
      final content = response['response'] as String;
      if (content == null) {
        throw const InvalidJsonError('No content in Ollama response');
      }

      return JsonValidator.validateAndParseItinerary(content);
    } catch (e) {
      return ValidationResult.failure(
        ['Failed to parse Ollama response: ${e.toString()}'],
        regenerationRequest: _generateGenericRegenerationRequest(),
      );
    }
  }

  String _generateGenericRegenerationRequest() {
    return '''
The generated JSON is invalid. Please ensure it follows this exact schema:

{
  "title": "string (required, non-empty trip title)",
  "startDate": "string (required, YYYY-MM-DD format)",
  "endDate": "string (required, YYYY-MM-DD format, must be after startDate)",
  "days": [
    {
      "date": "string (required, YYYY-MM-DD format)",
      "summary": "string (required, non-empty day summary)",
      "items": [
        {
          "time": "string (required, HH:MM format)",
          "activity": "string (required, non-empty activity description)",
          "location": "string (required, non-empty location)"
        }
      ]
    }
  ]
}

Make sure all required fields are present and have the correct data types.
''';
  }

  void _validateInput(String userInput) {
    if (userInput.trim().isEmpty) {
      throw const InvalidItineraryError('User input cannot be empty');
    }
    
    if (userInput.length > 1000) {
      throw const InvalidItineraryError('User input is too long');
    }
  }

  ItineraryError _handleDioError(DioException e) {
    switch (e.response?.statusCode) {
      case 404:
        return const NetworkError('Ollama server not found. Please ensure Ollama is running.');
      case 500:
        return const NetworkError('Ollama server error');
      default:
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          return const NetworkError('Connection timeout');
        }
        return NetworkError('Network error: ${e.message}');
    }
  }

  String _getJsonSchema() {
    return '''
{
  "title": "string (trip title)",
  "startDate": "string (YYYY-MM-DD)",
  "endDate": "string (YYYY-MM-DD)",
  "days": [
    {
      "date": "string (YYYY-MM-DD)",
      "summary": "string (day summary)",
      "items": [
        {
          "time": "string (HH:MM)",
          "activity": "string (activity description)",
          "location": "string (coordinates or address)"
        }
      ]
    }
  ]
}
''';
  }

  /// Perform web search for real-time information
  Future<Map<String, dynamic>> _performWebSearch(String userInput, Itinerary? previousItinerary) async {
    try {
      final searchQueries = _extractSearchQueries(userInput, previousItinerary);
      final webSearchData = <String, dynamic>{};

      for (final query in searchQueries) {
        final results = await _webSearchService.performWebSearch(query);
        if (results.isNotEmpty) {
          webSearchData[query] = results.map((r) => r.toJson()).toList();
        }
      }

      return webSearchData;
    } catch (e) {
      // Return empty data if web search fails
      return {};
    }
  }

  /// Extract search queries from user input and itinerary
  List<String> _extractSearchQueries(String userInput, Itinerary? previousItinerary) {
    final queries = <String>[];
    final inputLower = userInput.toLowerCase();

    // Extract location from user input
    final location = _extractLocationFromInput(userInput);
    if (location != null) {
      // Add specific search queries based on common travel needs
      if (inputLower.contains('restaurant') || inputLower.contains('food') || inputLower.contains('eat')) {
        queries.add('best restaurants in $location');
      }
      if (inputLower.contains('hotel') || inputLower.contains('accommodation') || inputLower.contains('stay')) {
        queries.add('best hotels in $location');
      }
      if (inputLower.contains('attraction') || inputLower.contains('sightseeing') || inputLower.contains('visit')) {
        queries.add('top attractions in $location');
      }
      if (inputLower.contains('temple') || inputLower.contains('shrine')) {
        queries.add('famous temples and shrines in $location');
      }
      if (inputLower.contains('transport') || inputLower.contains('travel') || inputLower.contains('get around')) {
        queries.add('transportation in $location');
      }
      if (inputLower.contains('event') || inputLower.contains('festival')) {
        queries.add('events and festivals in $location');
      }
    }

    // If no specific queries found, add a general search
    if (queries.isEmpty && location != null) {
      queries.add('travel guide $location');
    }

    return queries;
  }

  /// Extract location from user input
  String? _extractLocationFromInput(String userInput) {
    // Simple location extraction - can be enhanced with NLP
    final commonLocations = [
      'tokyo', 'kyoto', 'osaka', 'hiroshima', 'nara', 'kanazawa', 'takayama',
      'paris', 'london', 'rome', 'barcelona', 'amsterdam', 'berlin',
      'new york', 'san francisco', 'los angeles', 'chicago', 'boston',
      'seoul', 'singapore', 'bangkok', 'ho chi minh', 'hanoi',
      'sydney', 'melbourne', 'auckland', 'wellington'
    ];

    final inputLower = userInput.toLowerCase();
    for (final location in commonLocations) {
      if (inputLower.contains(location)) {
        return location;
      }
    }

    // Try to extract location from common patterns
    final locationPattern = RegExp(r'\b(in|to|at|near|around)\s+([a-zA-Z\s]+?)(?:\s|,|\.|$)');
    final match = locationPattern.firstMatch(inputLower);
    if (match != null) {
      return match.group(2)?.trim();
    }

    return null;
  }

  /// Enhance itinerary with web search data
  Itinerary _enhanceItineraryWithWebData(Itinerary itinerary, Map<String, dynamic> webSearchData) {
    final enhancedDays = itinerary.days.map((day) {
      final enhancedItems = day.items.map((item) {
        // Add web search data to items if available
        final searchKey = _findRelevantSearchData(item.activity, webSearchData);
        if (searchKey != null && webSearchData[searchKey] != null) {
          final searchResults = webSearchData[searchKey] as List;
          if (searchResults.isNotEmpty) {
            final firstResult = searchResults.first as Map<String, dynamic>;
            return DayItem(
              time: item.time,
              activity: item.activity,
              location: firstResult['address'] ?? item.location,
              additionalInfo: {
                'webSearchData': firstResult,
                'rating': firstResult['rating'],
                'phone': firstResult['phone'],
                'priceRange': firstResult['priceRange'],
              },
            );
          }
        }
        return item;
      }).toList();

      final enhancedDay = DayPlan(
        date: day.date,
        summary: day.summary,
      );
      enhancedDay.items.addAll(enhancedItems);
      return enhancedDay;
    }).toList();

    final enhancedItinerary = Itinerary(
      title: itinerary.title,
      startDate: itinerary.startDate,
      endDate: itinerary.endDate,
    );
    enhancedItinerary.days.addAll(enhancedDays);
    return enhancedItinerary;
  }

  /// Find relevant search data for an activity
  String? _findRelevantSearchData(String activity, Map<String, dynamic> webSearchData) {
    final activityLower = activity.toLowerCase();
    
    for (final key in webSearchData.keys) {
      if (key.toLowerCase().contains('restaurant') && 
          (activityLower.contains('eat') || activityLower.contains('dinner') || activityLower.contains('lunch'))) {
        return key;
      }
      if (key.toLowerCase().contains('hotel') && 
          (activityLower.contains('stay') || activityLower.contains('accommodation'))) {
        return key;
      }
      if (key.toLowerCase().contains('attraction') && 
          (activityLower.contains('visit') || activityLower.contains('see') || activityLower.contains('explore'))) {
        return key;
      }
    }
    
    return null;
  }

  /// Check if Ollama server is available
  Future<bool> isServerAvailable() async {
    try {
      final response = await _dio.get('$_baseUrl/api/tags');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get available models from Ollama
  Future<List<String>> getAvailableModels() async {
    try {
      final response = await _dio.get('$_baseUrl/api/tags');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final models = data['models'] as List<dynamic>?;
        if (models != null) {
          return models.map((model) => model['name'] as String).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

/// Factory class for creating OllamaService instances
class OllamaServiceFactory {
  static OllamaService createService({
    String baseUrl = 'http://localhost:11434',
    String model = 'llama2',
    WebSearchService? webSearchService,
    bool enableWebSearch = true,
  }) {
    return OllamaService(
      baseUrl: baseUrl,
      model: model,
      webSearchService: webSearchService,
      enableWebSearch: enableWebSearch,
    );
  }

  static OllamaService createWithWebSearch({
    String baseUrl = 'http://localhost:11434',
    String model = 'llama2',
    bool useDummyWebSearch = false,
  }) {
    final webSearchService = useDummyWebSearch 
        ? WebSearchServiceFactory.createWithDummyData()
        : WebSearchServiceFactory.createAuto();

    return createService(
      baseUrl: baseUrl,
      model: model,
      webSearchService: webSearchService,
      enableWebSearch: true,
    );
  }
}

