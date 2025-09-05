import 'dart:async';
import 'dart:convert';
import 'package:smart_trip_planner/core/services/agent_service.dart';
import 'package:smart_trip_planner/core/models/chat_streaming_models.dart';
import 'package:smart_trip_planner/core/models/itinerary_change.dart';
import 'package:smart_trip_planner/data/models/itinerary.dart';
import 'package:smart_trip_planner/domain/entities/chat_message.dart';
import 'package:smart_trip_planner/core/utils/json_validator.dart';
import 'package:smart_trip_planner/core/utils/itinerary_diff_engine.dart';

/// Service for streaming AI responses with itinerary parsing
class AgentStreamingService {
  final AgentService _agentService;
  final StreamController<StreamChunk> _streamController = StreamController<StreamChunk>.broadcast();
  final Map<String, StreamSubscription> _activeStreams = {};

  AgentStreamingService({required AgentService agentService}) 
      : _agentService = agentService;

  /// Stream of chunks
  Stream<StreamChunk> get stream => _streamController.stream;

  /// Generate streaming response
  Future<StreamResponse> generateStreamingResponse({
    required String userInput,
    required List<ChatMessage> chatHistory,
    Itinerary? lastItinerary,
    bool isRefinement = false,
  }) async {
    final streamId = DateTime.now().millisecondsSinceEpoch.toString();
    final response = StreamResponse.empty();

    try {
      // Emit thinking chunk
      _emitChunk(StreamChunk.thinking());

      // Generate response using AgentService
      final result = await _agentService.generateItineraryWithDiff(
        userInput: userInput,
        previousItinerary: lastItinerary,
        chatHistory: chatHistory,
        isRefinement: isRefinement,
      );

      // Simulate streaming by chunking the response
      await _simulateStreaming(result, streamId);

      // Complete the response
      final completedResponse = response.complete(
        itinerary: result.itinerary,
        diff: result.diff,
      );

      _emitChunk(StreamChunk.complete());
      return completedResponse;

    } catch (e) {
      _emitChunk(StreamChunk.error('Error: ${e.toString()}'));
      return StreamResponse.error('Failed to generate response: ${e.toString()}');
    }
  }

  /// Simulate streaming by chunking the response
  Future<void> _simulateStreaming(ItineraryDiffResult result, String streamId) async {
    final itinerary = result.itinerary;
    final chunks = <String>[];

    // Create response chunks
    chunks.add('I\'ve generated your itinerary: "${itinerary.title}"\n\n');
    chunks.add('📅 ${itinerary.startDate} to ${itinerary.endDate}\n\n');

    for (int i = 0; i < itinerary.days.length; i++) {
      final day = itinerary.days[i];
      chunks.add('**Day ${i + 1} - ${day.date}**\n');
      chunks.add('${day.summary}\n\n');

      for (int j = 0; j < day.items.length; j++) {
        final item = day.items[j];
        chunks.add('• ${item.time}: ${item.activity}\n');
        chunks.add('  📍 ${item.location}\n');
      }
      chunks.add('\n');
    }

    // Add change information if available
    if (result.hasChanges) {
      chunks.add('\n**Changes Made:**\n');
      chunks.add(result.getChangesSummary());
      chunks.add('\n');
    }

    // Stream chunks with delay
    for (final chunk in chunks) {
      await Future.delayed(const Duration(milliseconds: 50));
      _emitChunk(StreamChunk.text(chunk));
    }
  }

  /// Generate streaming response with real streaming (if supported)
  Future<StreamResponse> generateRealStreamingResponse({
    required String userInput,
    required List<ChatMessage> chatHistory,
    Itinerary? lastItinerary,
    bool isRefinement = false,
  }) async {
    final streamId = DateTime.now().millisecondsSinceEpoch.toString();
    final response = StreamResponse.empty();

    try {
      // Emit thinking chunk
      _emitChunk(StreamChunk.thinking());

      // For now, use the regular AgentService
      // In a real implementation, this would use streaming APIs
      final result = await _agentService.generateItineraryWithDiff(
        userInput: userInput,
        previousItinerary: lastItinerary,
        chatHistory: chatHistory,
        isRefinement: isRefinement,
      );

      // Stream the response
      await _streamResponse(result, streamId);

      // Complete the response
      final completedResponse = response.complete(
        itinerary: result.itinerary,
        diff: result.diff,
      );

      _emitChunk(StreamChunk.complete());
      return completedResponse;

    } catch (e) {
      _emitChunk(StreamChunk.error('Error: ${e.toString()}'));
      return StreamResponse.error('Failed to generate response: ${e.toString()}');
    }
  }

  /// Stream the response in real-time
  Future<void> _streamResponse(ItineraryDiffResult result, String streamId) async {
    final itinerary = result.itinerary;
    
    // Stream title
    _emitChunk(StreamChunk.text('I\'ve generated your itinerary: "'));
    await Future.delayed(const Duration(milliseconds: 100));
    _emitChunk(StreamChunk.text('${itinerary.title}"\n\n'));

    // Stream date range
    _emitChunk(StreamChunk.text('📅 '));
    await Future.delayed(const Duration(milliseconds: 50));
    _emitChunk(StreamChunk.text('${itinerary.startDate} to ${itinerary.endDate}\n\n'));

    // Stream days
    for (int i = 0; i < itinerary.days.length; i++) {
      final day = itinerary.days[i];
      
      _emitChunk(StreamChunk.text('**Day ${i + 1} - ${day.date}**\n'));
      await Future.delayed(const Duration(milliseconds: 100));
      
      _emitChunk(StreamChunk.text('${day.summary}\n\n'));
      await Future.delayed(const Duration(milliseconds: 100));

      // Stream items
      for (int j = 0; j < day.items.length; j++) {
        final item = day.items[j];
        
        _emitChunk(StreamChunk.text('• ${item.time}: '));
        await Future.delayed(const Duration(milliseconds: 50));
        _emitChunk(StreamChunk.text('${item.activity}\n'));
        await Future.delayed(const Duration(milliseconds: 50));
        _emitChunk(StreamChunk.text('  📍 ${item.location}\n'));
        await Future.delayed(const Duration(milliseconds: 50));
      }
      _emitChunk(StreamChunk.text('\n'));
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Stream change information if available
    if (result.hasChanges) {
      _emitChunk(StreamChunk.text('\n**Changes Made:**\n'));
      await Future.delayed(const Duration(milliseconds: 100));
      _emitChunk(StreamChunk.text(result.getChangesSummary()));
      _emitChunk(StreamChunk.text('\n'));
    }
  }

  /// Parse JSON from streaming response
  Future<Itinerary?> parseItineraryFromStream(StreamResponse response) async {
    if (response.jsonContent == null) return null;

    try {
      final validationResult = JsonValidator.validateAndParseItinerary(response.jsonContent!);
      if (validationResult.isValid) {
        return validationResult.itinerary;
      } else {
        _emitChunk(StreamChunk.error('Invalid JSON: ${validationResult.errors.join(', ')}'));
        return null;
      }
    } catch (e) {
      _emitChunk(StreamChunk.error('Failed to parse JSON: ${e.toString()}'));
      return null;
    }
  }

  /// Create diff between itineraries
  Future<ItineraryDiff?> createDiff(Itinerary? oldItinerary, Itinerary? newItinerary) async {
    if (oldItinerary == null || newItinerary == null) return null;
    
    try {
      return ItineraryDiffEngine.compareItineraries(oldItinerary, newItinerary);
    } catch (e) {
      _emitChunk(StreamChunk.error('Failed to create diff: ${e.toString()}'));
      return null;
    }
  }

  /// Emit a chunk to the stream
  void _emitChunk(StreamChunk chunk) {
    _streamController.add(chunk);
  }

  /// Cancel a specific stream
  void cancelStream(String streamId) {
    _activeStreams[streamId]?.cancel();
    _activeStreams.remove(streamId);
  }

  /// Cancel all streams
  void cancelAllStreams() {
    for (final subscription in _activeStreams.values) {
      subscription.cancel();
    }
    _activeStreams.clear();
  }

  /// Dispose the service
  void dispose() {
    cancelAllStreams();
    _streamController.close();
  }
}

/// Factory for creating AgentStreamingService
class AgentStreamingServiceFactory {
  static AgentStreamingService create({
    required AgentService agentService,
  }) {
    return AgentStreamingService(agentService: agentService);
  }

  static AgentStreamingService createWithWebSearch({
    String? openaiApiKey,
    String? geminiApiKey,
    bool preferOpenAI = true,
    bool useDummyWebSearch = false,
  }) {
    final agentService = AgentServiceFactory.createWithWebSearch(
      openaiApiKey: openaiApiKey,
      geminiApiKey: geminiApiKey,
      preferOpenAI: preferOpenAI,
      useDummyWebSearch: useDummyWebSearch,
    );

    return AgentStreamingService(agentService: agentService);
  }
}


