import 'dart:isolate';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
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

/// Agent Isolate Service - Implements serverless function/isolate for agent logic
/// This service runs in a separate isolate to handle LLM interactions with function-calling
class AgentIsolateService {
  static const String _openaiBaseUrl = 'https://api.openai.com/v1';
  static const String _geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  
  final Dio _dio;
  final String? _openaiApiKey;
  final String? _geminiApiKey;
  final bool _useOpenAI;
  final WebSearchService _webSearchService;
  final bool _enableWebSearch;

  AgentIsolateService({
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

  /// Main entry point for the isolate - processes agent requests
  static Future<Map<String, dynamic>> processAgentRequest(
    Map<String, dynamic> request,
  ) async {
    try {
      final service = AgentIsolateService._fromRequest(request);
      final result = await service._processRequest(request);
      return result;
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'errorType': e.runtimeType.toString(),
      };
    }
  }

  /// Create service instance from request data
  factory AgentIsolateService._fromRequest(Map<String, dynamic> request) {
    return AgentIsolateService(
      openaiApiKey: request['openaiApiKey'] as String?,
      geminiApiKey: request['geminiApiKey'] as String?,
      useOpenAI: request['useOpenAI'] as bool? ?? true,
      enableWebSearch: request['enableWebSearch'] as bool? ?? true,
    );
  }

  /// Process the agent request
  Future<Map<String, dynamic>> _processRequest(Map<String, dynamic> request) async {
    final userInput = request['userInput'] as String;
    final previousItineraryJson = request['previousItinerary'] as Map<String, dynamic>?;
    final chatHistoryJson = request['chatHistory'] as List<dynamic>?;
    final isRefinement = request['isRefinement'] as bool? ?? false;

    // Parse previous itinerary if provided
    Itinerary? previousItinerary;
    if (previousItineraryJson != null) {
      previousItinerary = Itinerary.fromJson(previousItineraryJson);
    }

    // Parse chat history
    final chatHistory = (chatHistoryJson ?? [])
        .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
        .toList();

    try {
      // Generate itinerary with LLM function-calling
      final itinerary = await _generateItineraryWithFunctionCalling(
        userInput: userInput,
        previousItinerary: previousItinerary,
        chatHistory: chatHistory,
        isRefinement: isRefinement,
      );

      // Validate the response
      final validationResult = _validateItinerary(itinerary);
      if (!validationResult['isValid']) {
        throw InvalidJsonError('Invalid itinerary: ${validationResult['errors']}');
      }

      return {
        'success': true,
        'itinerary': itinerary.toJson(),
        'validationResult': validationResult,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'errorType': e.runtimeType.toString(),
      };
    }
  }

  /// Generate itinerary using LLM with function-calling enabled
  Future<Itinerary> _generateItineraryWithFunctionCalling({
    required String userInput,
    Itinerary? previousItinerary,
    required List<ChatMessage> chatHistory,
    required bool isRefinement,
  }) async {
    // Validate input
    _validateInput(userInput);
    
    // Perform web search for real-time information
    Map<String, dynamic> webSearchData = {};
    if (_enableWebSearch) {
      webSearchData = await _performWebSearch(userInput, previousItinerary);
    }
    
    // Build the prompt
    final prompt = _buildPrompt(
      userInput: userInput,
      previousItinerary: previousItinerary,
      chatHistory: chatHistory,
      isRefinement: isRefinement,
      webSearchData: webSearchData,
    );

    // Call LLM with function-calling
    final response = _useOpenAI 
        ? await _callOpenAIWithFunctionCalling(prompt)
        : await _callGeminiWithFunctionCalling(prompt);

    // Parse and validate response
    final itinerary = _parseLLMResponse(response);

    // Enhance with web search data
    if (webSearchData.isNotEmpty) {
      return _enhanceItineraryWithWebData(itinerary, webSearchData);
    }

    return itinerary;
  }

  /// Call OpenAI with function-calling enabled
  Future<Map<String, dynamic>> _callOpenAIWithFunctionCalling(String prompt) async {
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
            'content': _getSystemPrompt(),
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'tools': [
          {
            'type': 'function',
            'function': {
              'name': 'generate_itinerary',
              'description': 'Generate a travel itinerary based on user requirements',
              'parameters': _getFunctionSchema(),
            }
          }
        ],
        'tool_choice': {'type': 'function', 'function': {'name': 'generate_itinerary'}},
        'temperature': 0.7,
        'max_tokens': 2000,
      },
    );

    return _extractOpenAIResponse(response.data);
  }

  /// Call Gemini with function-calling enabled
  Future<Map<String, dynamic>> _callGeminiWithFunctionCalling(String prompt) async {
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
                'text': '${_getSystemPrompt()}\n\n$prompt',
              }
            ]
          }
        ],
        'tools': [
          {
            'function_declarations': [
              {
                'name': 'generate_itinerary',
                'description': 'Generate a travel itinerary based on user requirements',
                'parameters': _getFunctionSchema(),
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

  /// Extract response from OpenAI API
  Map<String, dynamic> _extractOpenAIResponse(Map<String, dynamic> data) {
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw const InvalidJsonError('No response from OpenAI');
    }

    final message = choices[0]['message'] as Map<String, dynamic>?;
    if (message == null) {
      throw const InvalidJsonError('Invalid response format from OpenAI');
    }

    final toolCalls = message['tool_calls'] as List?;
    if (toolCalls == null || toolCalls.isEmpty) {
      throw const InvalidJsonError('No tool calls in OpenAI response');
    }

    final functionCall = toolCalls[0]['function'] as Map<String, dynamic>?;
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

  /// Extract response from Gemini API
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

    // Look for function call in parts
    for (final part in parts) {
      if (part['functionCall'] != null) {
        final functionCall = part['functionCall'] as Map<String, dynamic>;
        final args = functionCall['args'] as Map<String, dynamic>?;
        if (args != null) {
          return args;
        }
      }
    }

    // Fallback to text extraction
    final text = parts[0]['text'] as String?;
    if (text == null) {
      throw const InvalidJsonError('No text content in Gemini response');
    }

    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch == null) {
        throw const InvalidJsonError('No JSON found in Gemini response');
      }

      return json.decode(jsonMatch.group(0)!) as Map<String, dynamic>;
    } catch (e) {
      throw InvalidJsonError('Failed to parse Gemini response: $e');
    }
  }

  /// Parse LLM response into Itinerary object
  Itinerary _parseLLMResponse(Map<String, dynamic> response) {
    try {
      // Validate the response structure
      if (!response.containsKey('title') || 
          !response.containsKey('startDate') || 
          !response.containsKey('endDate') || 
          !response.containsKey('days')) {
        throw const InvalidJsonError('Missing required fields in LLM response');
      }

      // Parse the itinerary
      return Itinerary.fromJson(response);
    } catch (e) {
      throw InvalidJsonError('Failed to parse LLM response: $e');
    }
  }

  /// Validate itinerary structure
  Map<String, dynamic> _validateItinerary(Itinerary itinerary) {
    final errors = <String>[];

    // Validate title
    if (itinerary.title.trim().isEmpty) {
      errors.add('Title cannot be empty');
    }

    // Validate dates
    try {
      final startDate = DateTime.parse(itinerary.startDate);
      final endDate = DateTime.parse(itinerary.endDate);
      if (endDate.isBefore(startDate)) {
        errors.add('End date must be after start date');
      }
    } catch (e) {
      errors.add('Invalid date format');
    }

    // Validate days
    if (itinerary.days.isEmpty) {
      errors.add('Itinerary must have at least one day');
    }

    for (int i = 0; i < itinerary.days.length; i++) {
      final day = itinerary.days[i];
      
      // Validate day date
      try {
        DateTime.parse(day.date);
      } catch (e) {
        errors.add('Day ${i + 1}: Invalid date format');
      }

      // Validate day summary
      if (day.summary.trim().isEmpty) {
        errors.add('Day ${i + 1}: Summary cannot be empty');
      }

      // Validate items
      if (day.items.isEmpty) {
        errors.add('Day ${i + 1}: Must have at least one activity');
      }

      for (int j = 0; j < day.items.length; j++) {
        final item = day.items[j];
        
        // Validate time format
        if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(item.time)) {
          errors.add('Day ${i + 1}, Item ${j + 1}: Invalid time format (use HH:MM)');
        }

        // Validate activity
        if (item.activity.trim().isEmpty) {
          errors.add('Day ${i + 1}, Item ${j + 1}: Activity cannot be empty');
        }

        // Validate location
        if (item.location.trim().isEmpty) {
          errors.add('Day ${i + 1}, Item ${j + 1}: Location cannot be empty');
        }
      }
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
    };
  }

  /// Get system prompt for LLM
  String _getSystemPrompt() {
    return '''
You are a professional travel planner AI assistant. Your task is to generate detailed, practical travel itineraries based on user requests.

Key requirements:
1. Always respond with valid JSON matching the exact schema provided
2. Include realistic timing and locations
3. Consider travel time between locations
4. Provide diverse activities (sightseeing, dining, cultural experiences)
5. Use proper date formats (YYYY-MM-DD) and time formats (HH:MM)
6. Include specific locations with addresses or coordinates when possible
7. Make itineraries practical and achievable

When refining existing itineraries:
- Only modify the parts that need to be changed
- Maintain the overall structure unless specifically requested to change it
- Preserve good activities and only replace problematic ones

Always ensure the response is valid JSON that can be parsed directly.
''';
  }

  /// Get function schema for LLM function-calling
  Map<String, dynamic> _getFunctionSchema() {
    return {
      'type': 'object',
      'properties': {
        'title': {
          'type': 'string',
          'description': 'Trip title (e.g., "Tokyo 5-Day Adventure")',
        },
        'startDate': {
          'type': 'string',
          'description': 'Start date in YYYY-MM-DD format',
        },
        'endDate': {
          'type': 'string',
          'description': 'End date in YYYY-MM-DD format',
        },
        'days': {
          'type': 'array',
          'description': 'Array of day plans',
          'items': {
            'type': 'object',
            'properties': {
              'date': {
                'type': 'string',
                'description': 'Date in YYYY-MM-DD format',
              },
              'summary': {
                'type': 'string',
                'description': 'Brief summary of the day (e.g., "Explore historic temples and local cuisine")',
              },
              'items': {
                'type': 'array',
                'description': 'Array of activities for the day',
                'items': {
                  'type': 'object',
                  'properties': {
                    'time': {
                      'type': 'string',
                      'description': 'Time in HH:MM format (24-hour)',
                    },
                    'activity': {
                      'type': 'string',
                      'description': 'Detailed activity description',
                    },
                    'location': {
                      'type': 'string',
                      'description': 'Location address, coordinates, or landmark name',
                    },
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
    };
  }

  /// Build the prompt for LLM
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
      buffer.writeln('Current itinerary: ${json.encode(previousItinerary.toJson())}');
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

    buffer.writeln('\nPlease generate a detailed travel itinerary using the generate_itinerary function.');

    return buffer.toString();
  }

  /// Validate user input
  void _validateInput(String userInput) {
    if (userInput.trim().isEmpty) {
      throw const InvalidItineraryError('User input cannot be empty');
    }
    
    if (userInput.length > 1000) {
      throw const InvalidItineraryError('User input is too long');
    }
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
      return {};
    }
  }

  /// Extract search queries from user input
  List<String> _extractSearchQueries(String userInput, Itinerary? previousItinerary) {
    final queries = <String>[];
    final inputLower = userInput.toLowerCase();

    final location = _extractLocationFromInput(userInput);
    if (location != null) {
      if (inputLower.contains('restaurant') || inputLower.contains('food') || inputLower.contains('eat')) {
        queries.add('best restaurants in $location');
      }
      if (inputLower.contains('hotel') || inputLower.contains('accommodation') || inputLower.contains('stay')) {
        queries.add('best hotels in $location');
      }
      if (inputLower.contains('attraction') || inputLower.contains('sightseeing') || inputLower.contains('visit')) {
        queries.add('top attractions in $location');
      }
      if (queries.isEmpty) {
        queries.add('travel guide $location');
      }
    }

    return queries;
  }

  /// Extract location from user input
  String? _extractLocationFromInput(String userInput) {
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

/// Agent Isolate Manager - Manages isolate lifecycle and communication
class AgentIsolateManager {
  static Isolate? _isolate;
  static SendPort? _sendPort;
  static ReceivePort? _receivePort;

  /// Initialize the agent isolate
  static Future<void> initialize() async {
    if (_isolate != null) return;

    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(
      _isolateEntryPoint,
      _receivePort!.sendPort,
    );

    _sendPort = await _receivePort!.first as SendPort;
  }

  /// Process agent request in isolate
  static Future<Map<String, dynamic>> processRequest(
    Map<String, dynamic> request,
  ) async {
    if (_sendPort == null) {
      await initialize();
    }

    final completer = Completer<Map<String, dynamic>>();
    final responsePort = ReceivePort();

    _sendPort!.send({
      'request': request,
      'responsePort': responsePort.sendPort,
    });

    responsePort.listen((response) {
      completer.complete(response as Map<String, dynamic>);
      responsePort.close();
    });

    return completer.future;
  }

  /// Clean up isolate
  static void dispose() {
    _isolate?.kill();
    _isolate = null;
    _sendPort = null;
    _receivePort?.close();
    _receivePort = null;
  }

  /// Isolate entry point
  static void _isolateEntryPoint(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) async {
      final request = message['request'] as Map<String, dynamic>;
      final responsePort = message['responsePort'] as SendPort;

      try {
        final result = await AgentIsolateService.processAgentRequest(request);
        responsePort.send(result);
      } catch (e) {
        responsePort.send({
          'success': false,
          'error': e.toString(),
          'errorType': e.runtimeType.toString(),
        });
      }
    });
  }
}

/// Factory for creating agent isolate requests
class AgentIsolateRequestFactory {
  static Map<String, dynamic> createRequest({
    required String userInput,
    Itinerary? previousItinerary,
    List<ChatMessage> chatHistory = const [],
    bool isRefinement = false,
    String? openaiApiKey,
    String? geminiApiKey,
    bool useOpenAI = true,
    bool enableWebSearch = true,
  }) {
    return {
      'userInput': userInput,
      'previousItinerary': previousItinerary?.toJson(),
      'chatHistory': chatHistory.map((msg) => msg.toJson()).toList(),
      'isRefinement': isRefinement,
      'openaiApiKey': openaiApiKey,
      'geminiApiKey': geminiApiKey,
      'useOpenAI': useOpenAI,
      'enableWebSearch': enableWebSearch,
    };
  }
}
