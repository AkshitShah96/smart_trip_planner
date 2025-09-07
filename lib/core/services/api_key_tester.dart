import 'dart:convert';
import 'package:dio/dio.dart';
import '../errors/itinerary_errors.dart';

class ApiKeyTester {
  final Dio _dio;
  
  ApiKeyTester({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
  }

  Future<ApiKeyTestResult> testOpenAIKey(String apiKey) async {
    try {
      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'user',
              'content': 'Hello, please respond with "API key is working"',
            }
          ],
          'max_tokens': 10,
          'temperature': 0.1,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>?;
          if (message != null && message['content'] != null) {
            return ApiKeyTestResult(
              isValid: true,
              provider: 'OpenAI',
              message: 'API key is working',
              usage: data['usage'] as Map<String, dynamic>?,
            );
          }
        }
      }
      
      return ApiKeyTestResult(
        isValid: false,
        provider: 'OpenAI',
        message: 'Invalid response format',
      );
    } on DioException catch (e) {
      String errorMessage = 'Unknown error';
      
      switch (e.response?.statusCode) {
        case 401:
          errorMessage = 'Invalid API key';
          break;
        case 429:
          errorMessage = 'Rate limit exceeded';
          break;
        case 500:
          errorMessage = 'Server error';
          break;
        default:
          errorMessage = e.message ?? 'Network error';
      }
      
      return ApiKeyTestResult(
        isValid: false,
        provider: 'OpenAI',
        message: errorMessage,
        error: e,
      );
    } catch (e) {
      return ApiKeyTestResult(
        isValid: false,
        provider: 'OpenAI',
        message: 'Unexpected error: ${e.toString()}',
        error: e,
      );
    }
  }

  Future<ApiKeyTestResult> testGeminiKey(String apiKey) async {
    try {
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent',
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
                  'text': 'Hello, please respond with "API key is working"',
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 10,
          },
        },
        queryParameters: {
          'key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          if (content != null) {
            final parts = content['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'] as String?;
              if (text != null) {
                return ApiKeyTestResult(
                  isValid: true,
                  provider: 'Gemini',
                  message: 'API key is working',
                  usage: data['usageMetadata'] as Map<String, dynamic>?,
                );
              }
            }
          }
        }
      }
      
      return ApiKeyTestResult(
        isValid: false,
        provider: 'Gemini',
        message: 'Invalid response format',
      );
    } on DioException catch (e) {
      String errorMessage = 'Unknown error';
      
      switch (e.response?.statusCode) {
        case 400:
          errorMessage = 'Invalid API key or request';
          break;
        case 429:
          errorMessage = 'Rate limit exceeded';
          break;
        case 500:
          errorMessage = 'Server error';
          break;
        default:
          errorMessage = e.message ?? 'Network error';
      }
      
      return ApiKeyTestResult(
        isValid: false,
        provider: 'Gemini',
        message: errorMessage,
        error: e,
      );
    } catch (e) {
      return ApiKeyTestResult(
        isValid: false,
        provider: 'Gemini',
        message: 'Unexpected error: ${e.toString()}',
        error: e,
      );
    }
  }

  Future<List<ApiKeyTestResult>> testMultipleKeys(List<String> apiKeys) async {
    final results = <ApiKeyTestResult>[];
    
    for (final key in apiKeys) {
      final openAIResult = await testOpenAIKey(key);
      if (openAIResult.isValid) {
        results.add(openAIResult);
        continue;
      }
      
      final geminiResult = await testGeminiKey(key);
      if (geminiResult.isValid) {
        results.add(geminiResult);
      } else {
        results.add(ApiKeyTestResult(
          isValid: false,
          provider: 'Unknown',
          message: 'Failed both OpenAI and Gemini tests',
        ));
      }
    }
    
    return results;
  }

  Future<ItineraryTestResult> testItineraryGeneration({
    required String apiKey,
    required String provider,
  }) async {
    try {
      final testPrompt = '''
Generate a simple 2-day travel itinerary for Tokyo in JSON format:

{
  "title": "Tokyo 2-Day Trip",
  "startDate": "2025-01-15",
  "endDate": "2025-01-17",
  "days": [
    {
      "date": "2025-01-15",
      "summary": "Arrival and exploration",
      "items": [
        {
          "time": "09:00",
          "activity": "Arrive at Tokyo Station",
          "location": "Tokyo Station, Japan"
        },
        {
          "time": "14:00",
          "activity": "Visit Senso-ji Temple",
          "location": "Senso-ji Temple, Tokyo"
        }
      ]
    }
  ]
}
''';

      if (provider == 'OpenAI') {
        return await _testOpenAIItinerary(apiKey, testPrompt);
      } else {
        return await _testGeminiItinerary(apiKey, testPrompt);
      }
    } catch (e) {
      return ItineraryTestResult(
        isValid: false,
        message: 'Error testing itinerary generation: ${e.toString()}',
      );
    }
  }

  Future<ItineraryTestResult> _testOpenAIItinerary(String apiKey, String prompt) async {
    final response = await _dio.post(
      'https://api.openai.com/v1/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'model': 'gpt-4',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a travel planner. Generate detailed itineraries in valid JSON format.',
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'temperature': 0.7,
        'max_tokens': 1000,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data;
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final message = choices[0]['message'] as Map<String, dynamic>?;
        if (message != null && message['content'] != null) {
          final content = message['content'] as String;
          
          try {
            final jsonData = json.decode(content);
            return ItineraryTestResult(
              isValid: true,
              message: 'Itinerary generation working',
              sampleItinerary: jsonData,
            );
          } catch (e) {
            return ItineraryTestResult(
              isValid: false,
              message: 'Generated content is not valid JSON',
              rawResponse: content,
            );
          }
        }
      }
    }
    
    return ItineraryTestResult(
      isValid: false,
      message: 'Invalid response format',
    );
  }

  Future<ItineraryTestResult> _testGeminiItinerary(String apiKey, String prompt) async {
    final response = await _dio.post(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent',
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
          'maxOutputTokens': 1000,
        },
      },
      queryParameters: {
        'key': apiKey,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data;
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'] as Map<String, dynamic>?;
        if (content != null) {
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String?;
            if (text != null) {
              try {
                final jsonData = json.decode(text);
                return ItineraryTestResult(
                  isValid: true,
                  message: 'Itinerary generation working',
                  sampleItinerary: jsonData,
                );
              } catch (e) {
                return ItineraryTestResult(
                  isValid: false,
                  message: 'Generated content is not valid JSON',
                  rawResponse: text,
                );
              }
            }
          }
        }
      }
    }
    
    return ItineraryTestResult(
      isValid: false,
      message: 'Invalid response format',
    );
  }
}

class ApiKeyTestResult {
  final bool isValid;
  final String provider;
  final String message;
  final Map<String, dynamic>? usage;
  final dynamic error;

  ApiKeyTestResult({
    required this.isValid,
    required this.provider,
    required this.message,
    this.usage,
    this.error,
  });

  @override
  String toString() {
    return 'ApiKeyTestResult(isValid: $isValid, provider: $provider, message: $message)';
  }
}

class ItineraryTestResult {
  final bool isValid;
  final String message;
  final Map<String, dynamic>? sampleItinerary;
  final String? rawResponse;

  ItineraryTestResult({
    required this.isValid,
    required this.message,
    this.sampleItinerary,
    this.rawResponse,
  });

  @override
  String toString() {
    return 'ItineraryTestResult(isValid: $isValid, message: $message)';
  }
}


