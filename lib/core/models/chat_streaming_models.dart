import 'package:smart_trip_planner/data/models/itinerary.dart';
import 'package:smart_trip_planner/domain/entities/chat_message.dart';
import 'itinerary_change.dart';

/// Types of streaming responses
enum StreamResponseType {
  text,           // Plain text response
  json,           // JSON response (itinerary)
  error,          // Error response
  thinking,       // AI is thinking
  complete,       // Stream complete
}

/// A single chunk of streaming response
class StreamChunk {
  final StreamResponseType type;
  final String content;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  const StreamChunk({
    required this.type,
    required this.content,
    this.metadata,
    required this.timestamp,
  });

  factory StreamChunk.text(String content) {
    return StreamChunk(
      type: StreamResponseType.text,
      content: content,
      timestamp: DateTime.now(),
    );
  }

  factory StreamChunk.json(String content) {
    return StreamChunk(
      type: StreamResponseType.json,
      content: content,
      timestamp: DateTime.now(),
    );
  }

  factory StreamChunk.error(String content) {
    return StreamChunk(
      type: StreamResponseType.error,
      content: content,
      timestamp: DateTime.now(),
    );
  }

  factory StreamChunk.thinking() {
    return StreamChunk(
      type: StreamResponseType.thinking,
      content: 'Thinking...',
      timestamp: DateTime.now(),
    );
  }

  factory StreamChunk.complete() {
    return StreamChunk(
      type: StreamResponseType.complete,
      content: 'Complete',
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'StreamChunk(type: $type, content: $content)';
  }
}

/// Complete streaming response
class StreamResponse {
  final List<StreamChunk> chunks;
  final String fullText;
  final String? jsonContent;
  final Itinerary? itinerary;
  final ItineraryDiff? diff;
  final bool hasItinerary;
  final bool hasChanges;
  final bool isComplete;
  final String? error;

  const StreamResponse({
    required this.chunks,
    required this.fullText,
    this.jsonContent,
    this.itinerary,
    this.diff,
    required this.hasItinerary,
    required this.hasChanges,
    required this.isComplete,
    this.error,
  });

  /// Create an empty response
  factory StreamResponse.empty() {
    return StreamResponse(
      chunks: [],
      fullText: '',
      hasItinerary: false,
      hasChanges: false,
      isComplete: false,
    );
  }

  /// Create a response with error
  factory StreamResponse.error(String error) {
    return StreamResponse(
      chunks: [StreamChunk.error(error)],
      fullText: error,
      hasItinerary: false,
      hasChanges: false,
      isComplete: true,
      error: error,
    );
  }

  /// Add a chunk to the response
  StreamResponse addChunk(StreamChunk chunk) {
    final newChunks = [...chunks, chunk];
    final newFullText = newChunks
        .where((c) => c.type == StreamResponseType.text)
        .map((c) => c.content)
        .join('');
    
    return StreamResponse(
      chunks: newChunks,
      fullText: newFullText,
      jsonContent: jsonContent,
      itinerary: itinerary,
      diff: diff,
      hasItinerary: hasItinerary,
      hasChanges: hasChanges,
      isComplete: chunk.type == StreamResponseType.complete,
      error: error,
    );
  }

  /// Mark as complete with final data
  StreamResponse complete({
    String? jsonContent,
    Itinerary? itinerary,
    ItineraryDiff? diff,
  }) {
    return StreamResponse(
      chunks: [...chunks, StreamChunk.complete()],
      fullText: fullText,
      jsonContent: jsonContent ?? this.jsonContent,
      itinerary: itinerary ?? this.itinerary,
      diff: diff ?? this.diff,
      hasItinerary: itinerary != null,
      hasChanges: diff?.hasChanges ?? false,
      isComplete: true,
      error: error,
    );
  }

  /// Get the last chunk
  StreamChunk? get lastChunk => chunks.isNotEmpty ? chunks.last : null;

  /// Get text chunks only
  List<StreamChunk> get textChunks => chunks
      .where((c) => c.type == StreamResponseType.text)
      .toList();

  /// Get JSON chunks only
  List<StreamChunk> get jsonChunks => chunks
      .where((c) => c.type == StreamResponseType.json)
      .toList();

  /// Check if response has error
  bool get hasError => error != null || 
      chunks.any((c) => c.type == StreamResponseType.error);

  /// Get error message
  String? get errorMessage => error ?? 
      chunks.firstWhere(
        (c) => c.type == StreamResponseType.error,
        orElse: () => StreamChunk.text(''),
      ).content;

  @override
  String toString() {
    return 'StreamResponse(chunks: ${chunks.length}, complete: $isComplete, hasItinerary: $hasItinerary)';
  }
}

/// Chat message with streaming support
class StreamingChatMessage {
  final String id;
  final MessageType type;
  final String content;
  final DateTime timestamp;
  final StreamResponse? streamResponse;
  final Itinerary? itinerary;
  final ItineraryDiff? diff;
  final bool isStreaming;
  final bool hasItinerary;
  final bool hasChanges;

  const StreamingChatMessage({
    required this.id,
    required this.type,
    required this.content,
    required this.timestamp,
    this.streamResponse,
    this.itinerary,
    this.diff,
    required this.isStreaming,
    required this.hasItinerary,
    required this.hasChanges,
  });

  /// Create a user message
  factory StreamingChatMessage.user(String content) {
    return StreamingChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: MessageType.user,
      content: content,
      timestamp: DateTime.now(),
      isStreaming: false,
      hasItinerary: false,
      hasChanges: false,
    );
  }

  /// Create an AI message
  factory StreamingChatMessage.ai(String content) {
    return StreamingChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: MessageType.ai,
      content: content,
      timestamp: DateTime.now(),
      isStreaming: false,
      hasItinerary: false,
      hasChanges: false,
    );
  }

  /// Create a streaming AI message
  factory StreamingChatMessage.streaming(String initialContent) {
    return StreamingChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: MessageType.ai,
      content: initialContent,
      timestamp: DateTime.now(),
      isStreaming: true,
      hasItinerary: false,
      hasChanges: false,
    );
  }

  /// Update with stream response
  StreamingChatMessage updateWithStream(StreamResponse streamResponse) {
    return StreamingChatMessage(
      id: id,
      type: type,
      content: streamResponse.fullText,
      timestamp: timestamp,
      streamResponse: streamResponse,
      itinerary: streamResponse.itinerary,
      diff: streamResponse.diff,
      isStreaming: !streamResponse.isComplete,
      hasItinerary: streamResponse.hasItinerary,
      hasChanges: streamResponse.hasChanges,
    );
  }

  /// Mark as complete
  StreamingChatMessage complete() {
    return StreamingChatMessage(
      id: id,
      type: type,
      content: content,
      timestamp: timestamp,
      streamResponse: streamResponse,
      itinerary: itinerary,
      diff: diff,
      isStreaming: false,
      hasItinerary: hasItinerary,
      hasChanges: hasChanges,
    );
  }

  /// Convert to regular ChatMessage
  ChatMessage toChatMessage() {
    return ChatMessage(
      id: id,
      type: type,
      content: content,
      timestamp: timestamp,
    );
  }

  /// Check if a specific day has changes
  bool hasChangesInDay(int dayIndex) {
    if (diff == null) return false;
    return diff!.hasChangesInDay(dayIndex);
  }

  /// Check if a specific item has changes
  bool hasChangesInItem(int dayIndex, int itemIndex) {
    if (diff == null) return false;
    return diff!.hasChangesInItem(dayIndex, itemIndex);
  }

  @override
  String toString() {
    return 'StreamingChatMessage(id: $id, type: $type, streaming: $isStreaming, hasItinerary: $hasItinerary)';
  }
}

/// Chat state for managing streaming responses
class ChatState {
  final List<StreamingChatMessage> messages;
  final bool isStreaming;
  final String? currentStreamId;
  final Itinerary? lastItinerary;
  final Map<String, StreamResponse> activeStreams;

  const ChatState({
    required this.messages,
    required this.isStreaming,
    this.currentStreamId,
    this.lastItinerary,
    required this.activeStreams,
  });

  /// Create initial state
  factory ChatState.initial() {
    return ChatState(
      messages: [],
      isStreaming: false,
      activeStreams: {},
    );
  }

  /// Add a message
  ChatState addMessage(StreamingChatMessage message) {
    return ChatState(
      messages: [...messages, message],
      isStreaming: isStreaming,
      currentStreamId: currentStreamId,
      lastItinerary: lastItinerary,
      activeStreams: activeStreams,
    );
  }

  /// Update a message
  ChatState updateMessage(String messageId, StreamingChatMessage updatedMessage) {
    final updatedMessages = messages.map((msg) {
      return msg.id == messageId ? updatedMessage : msg;
    }).toList();

    return ChatState(
      messages: updatedMessages,
      isStreaming: isStreaming,
      currentStreamId: currentStreamId,
      lastItinerary: lastItinerary,
      activeStreams: activeStreams,
    );
  }

  /// Start streaming
  ChatState startStreaming(String streamId) {
    return ChatState(
      messages: messages,
      isStreaming: true,
      currentStreamId: streamId,
      lastItinerary: lastItinerary,
      activeStreams: activeStreams,
    );
  }

  /// Stop streaming
  ChatState stopStreaming() {
    return ChatState(
      messages: messages,
      isStreaming: false,
      currentStreamId: null,
      lastItinerary: lastItinerary,
      activeStreams: activeStreams,
    );
  }

  /// Update stream response
  ChatState updateStream(String streamId, StreamResponse response) {
    final updatedStreams = Map<String, StreamResponse>.from(activeStreams);
    updatedStreams[streamId] = response;

    return ChatState(
      messages: messages,
      isStreaming: isStreaming,
      currentStreamId: currentStreamId,
      lastItinerary: response.itinerary ?? lastItinerary,
      activeStreams: updatedStreams,
    );
  }

  /// Get current stream response
  StreamResponse? getCurrentStream() {
    if (currentStreamId == null) return null;
    return activeStreams[currentStreamId];
  }

  /// Get the last message
  StreamingChatMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;

  /// Get messages with itineraries
  List<StreamingChatMessage> get messagesWithItineraries => messages
      .where((msg) => msg.hasItinerary)
      .toList();

  @override
  String toString() {
    return 'ChatState(messages: ${messages.length}, streaming: $isStreaming)';
  }
}
