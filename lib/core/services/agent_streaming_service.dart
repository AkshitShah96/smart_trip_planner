import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../errors/itinerary_errors.dart';
import '../../data/models/itinerary.dart';
import '../../data/models/day_plan.dart';
import '../../data/models/day_item.dart';
import '../../domain/entities/chat_message.dart';
import 'agent_service.dart';

class AgentStreamingServiceFactory {
  static AgentStreamingService create({required AgentService agentService}) {
    return AgentStreamingService(
      openaiApiKey: agentService.openaiApiKey,
      geminiApiKey: agentService.geminiApiKey,
      useOpenAI: agentService.useOpenAI,
    );
  }
}

class AgentStreamingService {
  final Dio _dio;
  final String? _openaiApiKey;
  final String? _geminiApiKey;
  final bool _useOpenAI;
  final StreamController<ChatStreamEvent> _streamController = StreamController<ChatStreamEvent>.broadcast();

  AgentStreamingService({
    String? openaiApiKey,
    String? geminiApiKey,
    bool useOpenAI = true,
    Dio? dio,
  }) : _openaiApiKey = openaiApiKey,
       _geminiApiKey = geminiApiKey,
       _useOpenAI = useOpenAI,
       _dio = dio ?? Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
  }

  Stream<ChatStreamEvent> get stream => _streamController.stream;

  Future<void> generateStreamingResponse({
    required String userInput,
    Itinerary? previousItinerary,
    List<ChatMessage> chatHistory = const [],
    bool isRefinement = false,
  }) async {
    try {
      await for (final event in streamChatResponse(
        userInput: userInput,
        previousItinerary: previousItinerary,
        chatHistory: chatHistory,
        isRefinement: isRefinement,
      )) {
        _streamController.add(event);
      }
    } catch (e) {
      _streamController.add(ChatStreamEvent.error(e.toString()));
    }
  }

  void dispose() {
    _streamController.close();
  }

  Stream<ChatStreamEvent> streamChatResponse({
    required String userInput,
    Itinerary? previousItinerary,
    List<ChatMessage> chatHistory = const [],
    bool isRefinement = false,
  }) async* {
    try {
      _validateInput(userInput);

      yield ChatStreamEvent.start();

      if (_useOpenAI) {
        yield* _streamOpenAIResponse(
          userInput: userInput,
          previousItinerary: previousItinerary,
          chatHistory: chatHistory,
          isRefinement: isRefinement,
        );
      } else {
        yield* _streamGeminiResponse(
          userInput: userInput,
          previousItinerary: previousItinerary,
          chatHistory: chatHistory,
          isRefinement: isRefinement,
        );
      }
    } catch (e) {
      yield ChatStreamEvent.error(e.toString());
    }
  }

  Stream<ChatStreamEvent> _streamOpenAIResponse({
    required String userInput,
    Itinerary? previousItinerary,
    required List<ChatMessage> chatHistory,
    required bool isRefinement,
  }) async* {
    if (_openaiApiKey == null) {
      yield ChatStreamEvent.error('OpenAI API key not configured');
      return;
    }

    try {
      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_openaiApiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'gpt-4',
          'messages': _buildMessages(userInput, previousItinerary, chatHistory, isRefinement),
          'stream': true,
          'temperature': 0.7,
          'max_tokens': 2000,
        },
      );

      yield* _processOpenAIStream(response);
    } catch (e) {
      yield ChatStreamEvent.error('OpenAI streaming error: ${e.toString()}');
    }
  }

  Stream<ChatStreamEvent> _streamGeminiResponse({
    required String userInput,
    Itinerary? previousItinerary,
    required List<ChatMessage> chatHistory,
    required bool isRefinement,
  }) async* {
    if (_geminiApiKey == null) {
      yield ChatStreamEvent.error('Gemini API key not configured');
      return;
    }

    try {
      yield ChatStreamEvent.content('Processing your request...');
      
      await Future.delayed(const Duration(seconds: 1));
      
      final mockItinerary = Itinerary(
        title: 'Sample Trip',
        startDate: '2025-01-01',
        endDate: '2025-01-03',
      );
      
      final mockDayPlan = DayPlan(
        date: '2025-01-01',
        summary: 'Arrival and exploration',
      );
      
      mockDayPlan.items.add(DayItem(
        time: '10:00',
        activity: 'Check into hotel',
        location: 'Hotel Location',
      ));
      
      mockDayPlan.items.add(DayItem(
        time: '14:00',
        activity: 'City tour',
        location: 'City Center',
      ));
      
      mockItinerary.days.add(mockDayPlan);
      
      yield ChatStreamEvent.itinerary(mockItinerary);
    } catch (e) {
      yield ChatStreamEvent.error('Gemini streaming error: ${e.toString()}');
    }
  }

  Stream<ChatStreamEvent> _processOpenAIStream(Response response) async* {
    try {
      final lines = response.data.toString().split('\n');
      
      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          
          if (data == '[DONE]') {
            yield ChatStreamEvent.complete();
            break;
          }

          try {
            final jsonData = json.decode(data);
            final choices = jsonData['choices'] as List?;
            
            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0]['delta'] as Map<String, dynamic>?;
              
              if (delta != null) {
                final content = delta['content'] as String?;
                if (content != null) {
                  yield ChatStreamEvent.content(content);
                }
              }
            }
          } catch (e) {
            continue;
          }
        }
      }
    } catch (e) {
      yield ChatStreamEvent.error('Stream processing error: ${e.toString()}');
    }
  }

  List<Map<String, dynamic>> _buildMessages(
    String userInput,
    Itinerary? previousItinerary,
    List<ChatMessage> chatHistory,
    bool isRefinement,
  ) {
    final messages = <Map<String, dynamic>>[];

    messages.add({
      'role': 'system',
      'content': _getSystemPrompt(),
    });

    for (final message in chatHistory.take(10)) {
      messages.add({
        'role': message.type == MessageType.user ? 'user' : 'assistant',
        'content': message.content,
      });
    }

    final requestContent = _buildRequestContent(userInput, previousItinerary, isRefinement);
    messages.add({
      'role': 'user',
      'content': requestContent,
    });

    return messages;
  }

  String _buildRequestContent(String userInput, Itinerary? previousItinerary, bool isRefinement) {
    final buffer = StringBuffer();
    
    if (isRefinement && previousItinerary != null) {
      buffer.writeln('REFINEMENT REQUEST:');
      buffer.writeln('Current itinerary: ${json.encode(previousItinerary.toJson())}');
      buffer.writeln('User request: $userInput');
      buffer.writeln('Please provide a conversational response about the changes and then generate the updated itinerary.');
    } else {
      buffer.writeln('NEW ITINERARY REQUEST:');
      buffer.writeln('User input: $userInput');
      buffer.writeln('Please provide a conversational response about the itinerary and then generate it.');
    }

    return buffer.toString();
  }

  String _getSystemPrompt() {
    return '''
You are a professional travel planner AI assistant. You help users create detailed travel itineraries.

Your responses should be:
1. Conversational and helpful
2. Provide insights about the destination
3. Explain your recommendations
4. Be enthusiastic about travel

When generating itineraries, always follow the Spec A JSON schema:
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

Always provide a conversational response first, then generate the itinerary.
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
}

class ChatStreamEvent {
  final ChatStreamEventType type;
  final String? content;
  final Itinerary? itinerary;
  final String? error;

  ChatStreamEvent._({
    required this.type,
    this.content,
    this.itinerary,
    this.error,
  });

  factory ChatStreamEvent.start() => ChatStreamEvent._(type: ChatStreamEventType.start);
  factory ChatStreamEvent.content(String content) => ChatStreamEvent._(type: ChatStreamEventType.content, content: content);
  factory ChatStreamEvent.itinerary(Itinerary itinerary) => ChatStreamEvent._(type: ChatStreamEventType.itinerary, itinerary: itinerary);
  factory ChatStreamEvent.complete() => ChatStreamEvent._(type: ChatStreamEventType.complete);
  factory ChatStreamEvent.error(String error) => ChatStreamEvent._(type: ChatStreamEventType.error, error: error);
}

enum ChatStreamEventType {
  start,
  content,
  itinerary,
  complete,
  error,
}
