import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/errors/itinerary_errors.dart';
import '../models/itinerary.dart';
import '../models/day_plan.dart';
import '../models/day_item.dart';

class OpenAIItineraryService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  static const String _endpoint = '/chat/completions';
  
  final Dio _dio;
  final String _apiKey;

  OpenAIItineraryService({
    required String apiKey,
    Dio? dio,
  }) : _apiKey = apiKey,
       _dio = dio ?? Dio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
  }

  /// Generates an itinerary from a user prompt using OpenAI's API
  Future<Itinerary> generateItinerary(String userPrompt) async {
    try {
      final response = await _dio.post(
        _endpoint,
        data: _buildRequestPayload(userPrompt),
      );

      if (response.statusCode == 200) {
        return _parseResponse(response.data);
      } else {
        throw _handleHttpError(response.statusCode, response.data);
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnknownError('Unexpected error: ${e.toString()}');
    }
  }

  /// Builds the request payload for OpenAI API
  Map<String, dynamic> _buildRequestPayload(String userPrompt) {
    return {
      'model': 'gpt-4o-mini', // Using GPT-4o-mini for cost efficiency
      'messages': [
        {
          'role': 'system',
          'content': _getSystemPrompt(),
        },
        {
          'role': 'user',
          'content': userPrompt,
        },
      ],
      'temperature': 0.7,
      'max_tokens': 2000,
      'response_format': {'type': 'json_object'},
    };
  }

  /// System prompt that instructs the AI to return structured JSON
  String _getSystemPrompt() {
    return '''
You are a professional travel planner. Generate a detailed itinerary in the following JSON format:

{
  "title": "Trip Title",
  "startDate": "YYYY-MM-DD",
  "endDate": "YYYY-MM-DD",
  "days": [
    {
      "date": "YYYY-MM-DD",
      "summary": "Brief description of the day",
      "items": [
        {
          "time": "HH:MM",
          "activity": "Activity description",
          "location": "latitude,longitude or address"
        }
      ]
    }
  ]
}

Guidelines:
- Create realistic, detailed itineraries
- Include specific times for activities
- Provide coordinates when possible, or descriptive addresses
- Make activities practical and achievable
- Consider travel time between locations
- Include meal times and breaks
- Vary activity types (sightseeing, dining, relaxation)
- Ensure dates are in YYYY-MM-DD format
- Times should be in HH:MM format (24-hour)
- Return ONLY valid JSON, no additional text
''';
  }

  /// Parses the OpenAI response into an Itinerary model
  Itinerary _parseResponse(Map<String, dynamic> responseData) {
    try {
      final choices = responseData['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw InvalidJsonError('No choices in response');
      }

      final message = choices[0]['message'] as Map<String, dynamic>?;
      if (message == null) {
        throw InvalidJsonError('No message in response');
      }

      final content = message['content'] as String?;
      if (content == null || content.isEmpty) {
        throw InvalidJsonError('Empty content in response');
      }

      // Parse the JSON content
      final Map<String, dynamic> itineraryJson;
      try {
        itineraryJson = json.decode(content) as Map<String, dynamic>;
      } catch (e) {
        throw InvalidJsonError('Failed to parse JSON content: ${e.toString()}');
      }

      // Validate and create Itinerary model
      return _createItineraryFromJson(itineraryJson);
    } catch (e) {
      if (e is ItineraryError) {
        rethrow;
      }
      throw InvalidJsonError('Failed to parse response: ${e.toString()}');
    }
  }

  /// Creates an Itinerary model from parsed JSON with validation
  Itinerary _createItineraryFromJson(Map<String, dynamic> json) {
    try {
      // Validate required fields
      final title = json['title'] as String?;
      final startDate = json['startDate'] as String?;
      final endDate = json['endDate'] as String?;
      final days = json['days'] as List<dynamic>?;

      if (title == null || title.isEmpty) {
        throw InvalidItineraryError('Missing or empty title');
      }
      if (startDate == null || startDate.isEmpty) {
        throw InvalidItineraryError('Missing or empty startDate');
      }
      if (endDate == null || endDate.isEmpty) {
        throw InvalidItineraryError('Missing or empty endDate');
      }
      if (days == null || days.isEmpty) {
        throw InvalidItineraryError('Missing or empty days array');
      }

      // Create the itinerary
      final itinerary = Itinerary(
        title: title,
        startDate: startDate,
        endDate: endDate,
      );

      // Parse and add days
      for (final dayJson in days) {
        if (dayJson is! Map<String, dynamic>) {
          throw InvalidItineraryError('Invalid day structure');
        }

        final day = _createDayPlanFromJson(dayJson);
        itinerary.days.add(day);
      }

      return itinerary;
    } catch (e) {
      if (e is ItineraryError) {
        rethrow;
      }
      throw InvalidItineraryError('Failed to create itinerary: ${e.toString()}');
    }
  }

  /// Creates a DayPlan model from JSON
  DayPlan _createDayPlanFromJson(Map<String, dynamic> json) {
    final date = json['date'] as String?;
    final summary = json['summary'] as String?;
    final items = json['items'] as List<dynamic>?;

    if (date == null || date.isEmpty) {
      throw InvalidItineraryError('Missing or empty date in day plan');
    }
    if (summary == null || summary.isEmpty) {
      throw InvalidItineraryError('Missing or empty summary in day plan');
    }
    if (items == null) {
      throw InvalidItineraryError('Missing items array in day plan');
    }

    final dayPlan = DayPlan(
      date: date,
      summary: summary,
    );

    // Parse and add items
    for (final itemJson in items) {
      if (itemJson is! Map<String, dynamic>) {
        throw InvalidItineraryError('Invalid item structure');
      }

      final item = _createDayItemFromJson(itemJson);
      dayPlan.items.add(item);
    }

    return dayPlan;
  }

  /// Creates a DayItem model from JSON
  DayItem _createDayItemFromJson(Map<String, dynamic> json) {
    final time = json['time'] as String?;
    final activity = json['activity'] as String?;
    final location = json['location'] as String?;

    if (time == null || time.isEmpty) {
      throw InvalidItineraryError('Missing or empty time in day item');
    }
    if (activity == null || activity.isEmpty) {
      throw InvalidItineraryError('Missing or empty activity in day item');
    }
    if (location == null || location.isEmpty) {
      throw InvalidItineraryError('Missing or empty location in day item');
    }

    return DayItem(
      time: time,
      activity: activity,
      location: location,
    );
  }

  /// Handles Dio-specific errors
  ItineraryError _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkError('Request timeout');
      
      case DioExceptionType.connectionError:
        return const NetworkError('Connection failed');
      
      case DioExceptionType.badResponse:
        return _handleHttpError(error.response?.statusCode, error.response?.data);
      
      case DioExceptionType.cancel:
        return const UnknownError('Request was cancelled');
      
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return const NetworkError('No internet connection');
        }
        return UnknownError('Unknown error: ${error.message}');
      
      default:
        return UnknownError('Dio error: ${error.message}');
    }
  }

  /// Handles HTTP status code errors
  ItineraryError _handleHttpError(int? statusCode, dynamic responseData) {
    switch (statusCode) {
      case 401:
        return const AuthenticationError('Invalid API key');
      case 429:
        return const RateLimitError('Too many requests');
      case 400:
        return InvalidJsonError('Bad request: ${responseData?.toString()}');
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerError(statusCode ?? 500, responseData?.toString());
      default:
        return ServerError(statusCode ?? 0, responseData?.toString());
    }
  }
}













