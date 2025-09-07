import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import '../errors/itinerary_errors.dart';
import '../../data/models/itinerary.dart';
import '../../data/models/day_plan.dart';
import '../../data/models/day_item.dart';
import '../../domain/entities/chat_message.dart';
import 'web_search_service.dart';
import '../utils/json_validator.dart';
import '../models/itinerary_change.dart';
import '../utils/itinerary_diff_engine.dart';

class AgentService {
  static const String _openaiBaseUrl = 'https://api.openai.com/v1';
  static const String _geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  
  final Dio _dio;
  final String? _openaiApiKey;
  final String? _geminiApiKey;
  final bool _useOpenAI;
  final WebSearchService _webSearchService;
  final bool _enableWebSearch;

  AgentService({
    String? openaiApiKey,
    String? geminiApiKey,
    bool useOpenAI = true,
    Dio? dio,
    WebSearchService? webSearchService,
    bool enableWebSearch = true,
  }) : _openaiApiKey = openaiApiKey,
       _geminiApiKey = geminiApiKey,
       _useOpenAI = useOpenAI,
       _dio = dio ?? Dio(),
       _webSearchService = webSearchService ?? WebSearchServiceFactory.createAuto(),
       _enableWebSearch = enableWebSearch {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
  }

  String? get openaiApiKey => _openaiApiKey;
  String? get geminiApiKey => _geminiApiKey;
  bool get useOpenAI => _useOpenAI;

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

      final response = _useOpenAI 
          ? await _callOpenAI(prompt)
          : await _callGemini(prompt);

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

    return buffer.toString();
  }

  /// Call OpenAI API with function calling
  Future<Map<String, dynamic>> _callOpenAI(String prompt) async {
    if (_openaiApiKey == null) {
      throw const AuthenticationError('OpenAI API key not configured');
    }

    final response = await _dio.post(
      '$_openaiBaseUrl/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer $_openaiApiKey',
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'model': 'gpt-4',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a professional travel planner. Generate detailed itineraries based on user requests. Always respond with valid JSON matching the provided schema.',
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'functions': [
          {
            'name': 'generate_itinerary',
            'description': 'Generate a travel itinerary',
            'parameters': {
              'type': 'object',
              'properties': {
                'title': {'type': 'string', 'description': 'Trip title'},
                'startDate': {'type': 'string', 'description': 'Start date (YYYY-MM-DD)'},
                'endDate': {'type': 'string', 'description': 'End date (YYYY-MM-DD)'},
                'days': {
                  'type': 'array',
                  'items': {
                    'type': 'object',
                    'properties': {
                      'date': {'type': 'string', 'description': 'Date (YYYY-MM-DD)'},
                      'summary': {'type': 'string', 'description': 'Day summary'},
                      'items': {
                        'type': 'array',
                        'items': {
                          'type': 'object',
                          'properties': {
                            'time': {'type': 'string', 'description': 'Time (HH:MM)'},
                            'activity': {'type': 'string', 'description': 'Activity description'},
                            'location': {'type': 'string', 'description': 'Location coordinates or address'},
                          },
                          'required': ['time', 'activity', 'location'],
                        },
                      },
                    },
                    'required': ['date', 'summary', 'items'],
                  },
                },
              },
              'required': ['title', 'startDate', 'endDate', 'days'],
            },
          }
        ],
        'function_call': {'name': 'generate_itinerary'},
        'temperature': 0.7,
        'max_tokens': 2000,
      },
    );

    return _extractOpenAIResponse(response.data);
  }

  /// Call Gemini API
  Future<Map<String, dynamic>> _callGemini(String prompt) async {
    if (_geminiApiKey == null) {
      throw const AuthenticationError('Gemini API key not configured');
    }

    final response = await _dio.post(
      '$_geminiBaseUrl/models/gemini-pro:generateContent',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'contents': [
          {
            'parts': [
              {
                'text': prompt,
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 2000,
        },
      },
      queryParameters: {
        'key': _geminiApiKey,
      },
    );

    return _extractGeminiResponse(response.data);
  }

  Map<String, dynamic> _extractOpenAIResponse(Map<String, dynamic> data) {
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw const InvalidJsonError('No response from OpenAI');
    }

    final message = choices[0]['message'] as Map<String, dynamic>?;
    if (message == null) {
      throw const InvalidJsonError('Invalid response format from OpenAI');
    }

    final functionCall = message['function_call'];
    if (functionCall == null) {
      throw const InvalidJsonError('No function call in OpenAI response');
    }

    final arguments = functionCall['arguments'] as String?;
    if (arguments == null) {
      throw const InvalidJsonError('No arguments in OpenAI function call');
    }

    try {
      return json.decode(arguments) as Map<String, dynamic>;
    } catch (e) {
      throw InvalidJsonError('Failed to parse OpenAI response: $e');
    }
  }

  Map<String, dynamic> _extractGeminiResponse(Map<String, dynamic> data) {
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw const InvalidJsonError('No response from Gemini');
    }

    final content = candidates[0]['content'] as Map<String, dynamic>?;
    if (content == null) {
      throw const InvalidJsonError('Invalid response format from Gemini');
    }

    final parts = content['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw const InvalidJsonError('No content parts in Gemini response');
    }

    final text = parts[0]['text'] as String?;
    if (text == null) {
      throw const InvalidJsonError('No text content in Gemini response');
    }

    try {
      // Extract JSON from the response text
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch == null) {
        throw const InvalidJsonError('No JSON found in Gemini response');
      }

      return json.decode(jsonMatch.group(0)!) as Map<String, dynamic>;
    } catch (e) {
      throw InvalidJsonError('Failed to parse Gemini response: $e');
    }
  }

  ValidationResult _parseAndValidateResponse(Map<String, dynamic> response, bool isRefinement) {
    try {
      String jsonString;
      
      if (_useOpenAI) {
        // OpenAI returns function call result
        final functionCall = response['choices']?[0]?['message']?['function_call'];
        if (functionCall == null) {
          throw const InvalidJsonError('No function call in OpenAI response');
        }
        jsonString = functionCall['arguments'] as String;
      } else {
        // Gemini returns content directly
        final content = response['candidates']?[0]?['content'];
        if (content == null) {
          throw const InvalidJsonError('No content in Gemini response');
        }
        jsonString = content['parts']?[0]?['text'] as String;
      }

      return JsonValidator.validateAndParseItinerary(jsonString);
    } catch (e) {
      return ValidationResult.failure(
        ['Failed to parse AI response: ${e.toString()}'],
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
      case 401:
        return const AuthenticationError('Invalid API key');
      case 429:
        return const RateLimitError('Rate limit exceeded');
      case 500:
        return const NetworkError('Server error');
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
    // This method can be enhanced to merge web search data into the itinerary
    // For now, we'll add web search data as additional metadata
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
}

/// Factory class for creating AgentService instances
class AgentServiceFactory {
  static AgentService createOpenAIService({
    required String apiKey,
    WebSearchService? webSearchService,
    bool enableWebSearch = true,
  }) {
    return AgentService(
      openaiApiKey: apiKey,
      useOpenAI: true,
      webSearchService: webSearchService,
      enableWebSearch: enableWebSearch,
    );
  }

  static AgentService createGeminiService({
    required String apiKey,
    WebSearchService? webSearchService,
    bool enableWebSearch = true,
  }) {
    return AgentService(
      geminiApiKey: apiKey,
      useOpenAI: false,
      webSearchService: webSearchService,
      enableWebSearch: enableWebSearch,
    );
  }

  static AgentService createFromConfig({
    String? openaiApiKey,
    String? geminiApiKey,
    bool preferOpenAI = true,
    WebSearchService? webSearchService,
    bool enableWebSearch = true,
  }) {
    if (preferOpenAI && openaiApiKey != null) {
      return createOpenAIService(
        apiKey: openaiApiKey,
        webSearchService: webSearchService,
        enableWebSearch: enableWebSearch,
      );
    } else if (geminiApiKey != null) {
      return createGeminiService(
        apiKey: geminiApiKey,
        webSearchService: webSearchService,
        enableWebSearch: enableWebSearch,
      );
    } else {
      throw const AuthenticationError('No API key provided');
    }
  }

  static AgentService createWithWebSearch({
    String? openaiApiKey,
    String? geminiApiKey,
    bool preferOpenAI = true,
    bool useDummyWebSearch = false,
  }) {
    final webSearchService = useDummyWebSearch 
        ? WebSearchServiceFactory.createWithDummyData()
        : WebSearchServiceFactory.createAuto();

    return createFromConfig(
      openaiApiKey: openaiApiKey,
      geminiApiKey: geminiApiKey,
      preferOpenAI: preferOpenAI,
      webSearchService: webSearchService,
      enableWebSearch: true,
    );
  }

  /// Create a mock service for demo purposes
  static AgentService createMockService() {
    return MockAgentService();
  }
}

/// Mock AgentService for demo purposes when no API key is available
class MockAgentService extends AgentService {
  MockAgentService() : super(
    openaiApiKey: null,
    geminiApiKey: null,
    useOpenAI: true,
    enableWebSearch: false,
  );

  @override
  Future<Itinerary> generateItinerary({
    required String userInput,
    Itinerary? previousItinerary,
    List<ChatMessage> chatHistory = const [],
    bool isRefinement = false,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Generate a mock itinerary based on user input
    final location = userInput.toLowerCase().trim();
    
    return _generateMockItinerary(location);
  }

  @override
  Future<ItineraryDiffResult> generateItineraryWithDiff({
    required String userInput,
    Itinerary? previousItinerary,
    List<ChatMessage> chatHistory = const [],
    bool isRefinement = false,
  }) async {
    final itinerary = await generateItinerary(
      userInput: userInput,
      previousItinerary: previousItinerary,
      chatHistory: chatHistory,
      isRefinement: isRefinement,
    );
    
    return ItineraryDiffResult(
      itinerary: itinerary,
      diff: null, // No diff for new itineraries
      hasChanges: false,
    );
  }

  Itinerary _generateMockItinerary(String location) {
    final now = DateTime.now();
    final startDate = now.add(const Duration(days: 7));
    final endDate = startDate.add(const Duration(days: 3));
    
    final itinerary = Itinerary(
      title: 'Trip to ${location.toUpperCase()}',
      startDate: '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
      endDate: '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
    );
    
    // Add sample days
    for (int i = 0; i < 3; i++) {
      final dayDate = startDate.add(Duration(days: i));
      final dayPlan = DayPlan(
        date: '${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}',
        summary: 'Day ${i + 1} in $location',
      );
      
      // Add sample items for each day
      final sampleActivities = _getSampleActivities(location, i);
      dayPlan.items.addAll(sampleActivities);
      
      itinerary.days.add(dayPlan);
    }
    
    return itinerary;
  }
  
  List<DayItem> _getSampleActivities(String location, int dayIndex) {
    final activities = [
      ['Morning: Arrive and check into hotel', 'Hotel check-in'],
      ['Afternoon: Visit local attractions', 'Sightseeing'],
      ['Evening: Try local cuisine', 'Dining'],
    ];
    
    if (dayIndex < activities.length) {
      return [
        DayItem(
          activity: activities[dayIndex][0],
          location: location,
          time: dayIndex == 0 ? '09:00' : '10:00',
        ),
        DayItem(
          activity: activities[dayIndex][1],
          location: 'Various locations',
          time: dayIndex == 0 ? '14:00' : '15:00',
        ),
      ];
    }
    
    return [];
  }
}
