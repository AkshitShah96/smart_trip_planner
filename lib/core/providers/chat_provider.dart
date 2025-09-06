import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/agent_streaming_service.dart';
import '../services/agent_service.dart';
import '../models/chat_streaming_models.dart';
import '../../data/models/itinerary.dart';

/// Provider for AgentStreamingService
final agentStreamingServiceProvider = Provider<AgentStreamingService>((ref) {
  final agentService = ref.watch(agentServiceProvider);
  return AgentStreamingServiceFactory.create(agentService: agentService);
});

/// Provider for AgentService
final agentServiceProvider = Provider<AgentService>((ref) {
  // For demo purposes, create a mock service when no real API key is provided
  return AgentServiceFactory.createMockService();
});

/// Chat state notifier
class ChatNotifier extends StateNotifier<ChatState> {
  final AgentStreamingService _streamingService;
  StreamSubscription<ChatStreamEvent>? _streamSubscription;

  ChatNotifier(this._streamingService) : super(ChatState.initial()) {
    _setupStreamListener();
  }

  void _setupStreamListener() {
    _streamSubscription = _streamingService.stream.listen(
      (chunk) {
        _handleStreamChunk(chunk);
      },
      onError: (error) {
        _handleStreamError(error);
      },
    );
  }

  void _handleStreamChunk(ChatStreamEvent event) {
    if (state.currentStreamId == null) return;

    // Convert ChatStreamEvent to StreamChunk
    final chunk = _convertEventToChunk(event);
    
    // Update the current stream response
    final currentStream = state.getCurrentStream() ?? StreamResponse.empty();
    final updatedStream = currentStream.addChunk(chunk);
    
    state = state.updateStream(state.currentStreamId!, updatedStream);

    // Update the last message if it's streaming
    if (state.lastMessage?.isStreaming == true) {
      final updatedMessage = state.lastMessage!.updateWithStream(updatedStream);
      state = state.updateMessage(state.lastMessage!.id, updatedMessage);
    }

    // If stream is complete, finalize the message
    if (chunk.type == StreamResponseType.complete) {
      _finalizeCurrentMessage();
    }
  }

  void _handleStreamError(dynamic error) {
    // Add error message
    final errorMessage = StreamingChatMessage.ai('Sorry, I encountered an error: ${error.toString()}');
    state = state.addMessage(errorMessage);
    state = state.stopStreaming();
  }

  StreamChunk _convertEventToChunk(ChatStreamEvent event) {
    switch (event.type) {
      case ChatStreamEventType.start:
        return StreamChunk.thinking();
      case ChatStreamEventType.content:
        return StreamChunk.text(event.content ?? '');
      case ChatStreamEventType.itinerary:
        return StreamChunk.json(event.itinerary?.toJson().toString() ?? '');
      case ChatStreamEventType.complete:
        return StreamChunk.complete();
      case ChatStreamEventType.error:
        return StreamChunk.error(event.error ?? 'Unknown error');
    }
  }

  void _finalizeCurrentMessage() {
    if (state.lastMessage?.isStreaming == true) {
      final completedMessage = state.lastMessage!.complete();
      state = state.updateMessage(completedMessage.id, completedMessage);
    }
    state = state.stopStreaming();
  }

  /// Send a message and get AI response
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Add user message
    final userMessage = StreamingChatMessage.user(content);
    state = state.addMessage(userMessage);

    // Start streaming response
    final streamId = DateTime.now().millisecondsSinceEpoch.toString();
    state = state.startStreaming(streamId);

    // Create streaming AI message
    final aiMessage = StreamingChatMessage.streaming('');
    state = state.addMessage(aiMessage);

    try {
      // Generate streaming response
      await _streamingService.generateStreamingResponse(
        userInput: content,
        chatHistory: state.messages.map((m) => m.toChatMessage()).toList(),
        previousItinerary: state.lastItinerary,
        isRefinement: _isRefinementRequest(content),
      );

    } catch (e) {
      // Handle error with more user-friendly message
      String errorText;
      if (e.toString().contains('AuthenticationError')) {
        errorText = 'I\'m currently running in demo mode. I can help you plan your trip to $content! Let me create a sample itinerary for you.';
      } else {
        errorText = 'Sorry, I encountered an error: ${e.toString()}';
      }
      
      final errorMessage = StreamingChatMessage.ai(errorText);
      state = state.updateMessage(aiMessage.id, errorMessage);
    } finally {
      state = state.stopStreaming();
    }
  }

  /// Check if the request is a refinement
  bool _isRefinementRequest(String content) {
    final refinementKeywords = [
      'change', 'modify', 'update', 'edit', 'add', 'remove', 'replace',
      'instead', 'rather', 'better', 'different', 'refine', 'adjust'
    ];
    
    final contentLower = content.toLowerCase();
    return refinementKeywords.any((keyword) => contentLower.contains(keyword));
  }

  /// Clear chat history
  void clearChat() {
    state = ChatState.initial();
  }

  /// Get messages with itineraries
  List<StreamingChatMessage> getMessagesWithItineraries() {
    return state.messagesWithItineraries;
  }

  /// Get the last itinerary
  Itinerary? getLastItinerary() {
    return state.lastItinerary;
  }

  /// Check if currently streaming
  bool get isStreaming => state.isStreaming;

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _streamingService.dispose();
    super.dispose();
  }
}

/// Provider for ChatNotifier
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final streamingService = ref.watch(agentStreamingServiceProvider);
  return ChatNotifier(streamingService);
});

/// Provider for messages with itineraries
final messagesWithItinerariesProvider = Provider<List<StreamingChatMessage>>((ref) {
  final chatState = ref.watch(chatProvider);
  return chatState.messagesWithItineraries;
});

/// Provider for last itinerary
final lastItineraryProvider = Provider<Itinerary?>((ref) {
  final chatState = ref.watch(chatProvider);
  return chatState.lastItinerary;
});

/// Provider for streaming status
final isStreamingProvider = Provider<bool>((ref) {
  final chatState = ref.watch(chatProvider);
  return chatState.isStreaming;
});

/// Extension for ChatState
extension ChatStateExtension on ChatState {
  ChatState copyWith({
    List<StreamingChatMessage>? messages,
    bool? isStreaming,
    String? currentStreamId,
    Itinerary? lastItinerary,
    Map<String, StreamResponse>? activeStreams,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      currentStreamId: currentStreamId ?? this.currentStreamId,
      lastItinerary: lastItinerary ?? this.lastItinerary,
      activeStreams: activeStreams ?? this.activeStreams,
    );
  }
}


