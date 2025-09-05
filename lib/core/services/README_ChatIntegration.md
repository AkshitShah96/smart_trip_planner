# Chat Integration with AgentService Documentation

## Overview

The Chat Integration system provides a complete chat interface that integrates with the AgentService to deliver real-time AI responses with streaming, itinerary parsing, and diff highlighting. Users can interact with the AI through a natural chat interface while getting structured itinerary responses with change tracking.

## Features

- **Real-time Streaming**: AI responses stream in real-time with typewriter effect
- **Itinerary Integration**: Automatic parsing and display of itinerary JSON responses
- **Diff Highlighting**: Visual highlighting of changes when refining itineraries
- **Interactive UI**: Tap to view detailed itinerary information
- **State Management**: Comprehensive state management with Riverpod
- **Error Handling**: Robust error handling and user feedback
- **Message History**: Persistent chat history with itinerary tracking

## Architecture

### Core Components

1. **`StreamingChatMessage`** - Enhanced chat message with itinerary support
2. **`StreamResponse`** - Streaming response management
3. **`AgentStreamingService`** - Service for streaming AI responses
4. **`ChatNotifier`** - Riverpod state notifier for chat management
5. **`ChatMessageWidget`** - Flutter widget for displaying messages
6. **`ItineraryDiffWidget`** - Widget for displaying itinerary changes

## Usage

### Basic Chat Integration

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_trip_planner/core/providers/chat_provider.dart';

class MyChatPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);
    final messages = chatState.messages;
    final isStreaming = chatState.isStreaming;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return ChatMessageWidget(
                  message: message,
                  onItineraryTap: () => _showItineraryDetails(context, message),
                );
              },
            ),
          ),
          TextField(
            onSubmitted: (message) {
              ref.read(chatProvider.notifier).sendMessage(message);
            },
          ),
        ],
      ),
    );
  }
}
```

### Sending Messages

```dart
// Send a user message
ref.read(chatProvider.notifier).sendMessage('Plan a trip to Tokyo');

// The system will automatically:
// 1. Add user message to chat
// 2. Start streaming AI response
// 3. Parse itinerary JSON
// 4. Display with diff highlighting if refinement
```

### Handling Itinerary Responses

```dart
// Check if message contains itinerary
if (message.hasItinerary) {
  // Display itinerary card
  return ChatItineraryWidget(
    message: message,
    onTap: () => _showItineraryDetails(context, message),
  );
}

// Check if message has changes
if (message.hasChanges) {
  // Show diff highlighting
  return ItineraryDiffWidget(
    diffResult: ItineraryDiffResult(
      itinerary: message.itinerary!,
      diff: message.diff,
      hasChanges: true,
    ),
  );
}
```

## Streaming Response System

### StreamResponse Types

```dart
enum StreamResponseType {
  text,           // Plain text response
  json,           // JSON response (itinerary)
  error,          // Error response
  thinking,       // AI is thinking
  complete,       // Stream complete
}
```

### Creating Stream Responses

```dart
// Create text chunk
final textChunk = StreamChunk.text('Hello!');

// Create JSON chunk
final jsonChunk = StreamChunk.json('{"title": "Tokyo Trip"}');

// Create error chunk
final errorChunk = StreamChunk.error('Something went wrong');

// Create thinking chunk
final thinkingChunk = StreamChunk.thinking();

// Create complete chunk
final completeChunk = StreamChunk.complete();
```

### Building Stream Response

```dart
// Start with empty response
var response = StreamResponse.empty();

// Add chunks
response = response.addChunk(StreamChunk.text('I\'ve generated your itinerary: '));
response = response.addChunk(StreamChunk.text('"Tokyo Adventure"\n\n'));
response = response.addChunk(StreamChunk.text('📅 2024-03-15 to 2024-03-17\n\n'));

// Complete with final data
response = response.complete(
  itinerary: parsedItinerary,
  diff: itineraryDiff,
);
```

## Message Types

### StreamingChatMessage

```dart
class StreamingChatMessage {
  final String id;
  final ChatMessageType type;
  final String content;
  final DateTime timestamp;
  final StreamResponse? streamResponse;
  final Itinerary? itinerary;
  final ItineraryDiff? diff;
  final bool isStreaming;
  final bool hasItinerary;
  final bool hasChanges;
}
```

### Creating Messages

```dart
// User message
final userMessage = StreamingChatMessage.user('Plan a trip to Tokyo');

// AI message
final aiMessage = StreamingChatMessage.ai('I\'ve planned your trip!');

// Streaming message
final streamingMessage = StreamingChatMessage.streaming('Generating...');

// Update with stream response
final updatedMessage = streamingMessage.updateWithStream(streamResponse);
```

## State Management

### ChatState

```dart
class ChatState {
  final List<StreamingChatMessage> messages;
  final bool isStreaming;
  final String? currentStreamId;
  final Itinerary? lastItinerary;
  final Map<String, StreamResponse> activeStreams;
}
```

### State Operations

```dart
// Add message
final newState = state.addMessage(message);

// Update message
final updatedState = state.updateMessage(messageId, updatedMessage);

// Start streaming
final streamingState = state.startStreaming(streamId);

// Stop streaming
final finalState = state.stopStreaming();

// Update stream
final streamState = state.updateStream(streamId, response);
```

### Riverpod Providers

```dart
// Main chat provider
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final streamingService = ref.watch(agentStreamingServiceProvider);
  return ChatNotifier(streamingService);
});

// Messages with itineraries
final messagesWithItinerariesProvider = Provider<List<StreamingChatMessage>>((ref) {
  final chatState = ref.watch(chatProvider);
  return chatState.messagesWithItineraries;
});

// Last itinerary
final lastItineraryProvider = Provider<Itinerary?>((ref) {
  final chatState = ref.watch(chatProvider);
  return chatState.lastItinerary;
});

// Streaming status
final isStreamingProvider = Provider<bool>((ref) {
  final chatState = ref.watch(chatProvider);
  return chatState.isStreaming;
});
```

## UI Components

### ChatMessageWidget

Main widget for displaying chat messages with itinerary support:

```dart
ChatMessageWidget(
  message: message,
  showTimestamp: true,
  onItineraryTap: () => _showItineraryDetails(context, message),
)
```

Features:
- **User/AI Message Bubbles**: Different styling for user and AI messages
- **Streaming Indicators**: Shows when AI is thinking or streaming
- **Itinerary Cards**: Displays itinerary information in chat
- **Change Highlighting**: Highlights modified elements
- **Interactive Elements**: Tap to view detailed information

### ChatItineraryWidget

Specialized widget for displaying itineraries in chat:

```dart
ChatItineraryWidget(
  message: message,
  onTap: () => _showItineraryDetails(context, message),
  showDiff: true,
)
```

Features:
- **Itinerary Preview**: Shows title, dates, and day summaries
- **Change Indicators**: Visual indicators for modified elements
- **Interactive Cards**: Tap to view full details
- **Responsive Design**: Adapts to different screen sizes

### StreamingTextWidget

Widget for displaying streaming text with typewriter effect:

```dart
StreamingTextWidget(
  text: 'I\'ve generated your itinerary...',
  style: TextStyle(fontSize: 16),
  delay: Duration(milliseconds: 30),
)
```

## AgentService Integration

### AgentStreamingService

Service that wraps AgentService with streaming capabilities:

```dart
final streamingService = AgentStreamingServiceFactory.createWithWebSearch(
  openaiApiKey: 'your-key',
  useDummyWebSearch: true,
);

// Generate streaming response
final response = await streamingService.generateStreamingResponse(
  userInput: 'Plan a trip to Tokyo',
  chatHistory: chatHistory,
  lastItinerary: lastItinerary,
  isRefinement: false,
);
```

### Streaming Response Generation

```dart
// Simulate streaming by chunking response
await _simulateStreaming(result, streamId);

// Stream in real-time
await _streamResponse(result, streamId);

// Parse JSON from stream
final itinerary = await parseItineraryFromStream(response);

// Create diff
final diff = await createDiff(oldItinerary, newItinerary);
```

## Error Handling

### Error Types

```dart
// Stream errors
final errorChunk = StreamChunk.error('Network error');

// Response errors
final errorResponse = StreamResponse.error('Failed to generate response');

// Message errors
final errorMessage = StreamingChatMessage.ai('Sorry, I encountered an error');
```

### Error Handling in UI

```dart
// Check for errors
if (message.streamResponse?.hasError == true) {
  return Container(
    color: Colors.red[50],
    child: Text('Error: ${message.streamResponse?.errorMessage}'),
  );
}

// Handle streaming errors
ref.listen(chatProvider, (previous, next) {
  if (next.lastMessage?.streamResponse?.hasError == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${next.lastMessage?.streamResponse?.errorMessage}'),
        backgroundColor: Colors.red,
      ),
    );
  }
});
```

## Advanced Features

### Change Detection and Highlighting

```dart
// Check if message has changes
if (message.hasChanges) {
  // Show diff highlighting
  return ItineraryDiffWidget(
    diffResult: ItineraryDiffResult(
      itinerary: message.itinerary!,
      diff: message.diff,
      hasChanges: true,
    ),
    onAcceptChanges: () => _acceptChanges(),
    onRejectChanges: () => _rejectChanges(),
  );
}
```

### Itinerary History

```dart
// Get messages with itineraries
final messagesWithItineraries = ref.read(chatProvider).messagesWithItineraries;

// Display history
ListView.builder(
  itemCount: messagesWithItineraries.length,
  itemBuilder: (context, index) {
    final message = messagesWithItineraries[index];
    return ListTile(
      title: Text(message.itinerary?.title ?? 'Unknown'),
      subtitle: Text('${message.itinerary?.startDate} - ${message.itinerary?.endDate}'),
      trailing: message.hasChanges ? Icon(Icons.edit) : null,
      onTap: () => _showItineraryDetails(context, message),
    );
  },
);
```

### Custom Message Styling

```dart
// Custom message bubble
Container(
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: message.type == ChatMessageType.user 
        ? Colors.blue[600] 
        : Colors.grey[200],
    borderRadius: BorderRadius.circular(18),
  ),
  child: Text(
    message.content,
    style: TextStyle(
      color: message.type == ChatMessageType.user 
          ? Colors.white 
          : Colors.black87,
    ),
  ),
)
```

## Performance Optimization

### Streaming Optimization

```dart
// Debounce rapid updates
Timer? _debounceTimer;
void _updateStream(StreamChunk chunk) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(milliseconds: 100), () {
    // Update UI
  });
}

// Batch updates
void _batchUpdate(List<StreamChunk> chunks) {
  // Process multiple chunks at once
}
```

### Memory Management

```dart
// Limit message history
if (messages.length > 100) {
  messages = messages.skip(50).toList();
}

// Dispose streams
@override
void dispose() {
  _streamSubscription?.cancel();
  _streamingService.dispose();
  super.dispose();
}
```

## Testing

### Unit Tests

```dart
test('should create user message', () {
  final message = StreamingChatMessage.user('Hello');
  expect(message.type, ChatMessageType.user);
  expect(message.content, 'Hello');
  expect(message.isStreaming, false);
});

test('should handle streaming response', () {
  final response = StreamResponse.empty();
  final updatedResponse = response.addChunk(StreamChunk.text('Hello'));
  expect(updatedResponse.fullText, 'Hello');
});
```

### Widget Tests

```dart
testWidgets('should display chat message', (tester) async {
  final message = StreamingChatMessage.user('Hello');
  
  await tester.pumpWidget(
    MaterialApp(
      home: ChatMessageWidget(message: message),
    ),
  );
  
  expect(find.text('Hello'), findsOneWidget);
});
```

## Best Practices

### Message Handling

1. **Always Check for Errors**: Verify message state before displaying
2. **Handle Streaming States**: Show appropriate indicators
3. **Manage Memory**: Limit message history and dispose resources
4. **Provide Feedback**: Show loading states and error messages

### UI Design

1. **Consistent Styling**: Use consistent colors and spacing
2. **Responsive Design**: Adapt to different screen sizes
3. **Accessibility**: Provide proper labels and descriptions
4. **Performance**: Optimize for smooth scrolling and updates

### State Management

1. **Immutable State**: Always create new state objects
2. **Proper Disposal**: Clean up resources and subscriptions
3. **Error Boundaries**: Handle errors gracefully
4. **Testing**: Write comprehensive tests

## Troubleshooting

### Common Issues

1. **Streaming Not Working**
   - Check AgentService configuration
   - Verify API keys
   - Check network connectivity

2. **Itinerary Not Parsing**
   - Verify JSON format
   - Check JsonValidator
   - Review error messages

3. **UI Not Updating**
   - Check Riverpod providers
   - Verify state changes
   - Review widget rebuilds

### Debug Mode

```dart
// Enable debug logging
final chatState = ref.watch(chatProvider);
print('Chat state: ${chatState.toString()}');
print('Messages: ${chatState.messages.length}');
print('Streaming: ${chatState.isStreaming}');
```

## Future Enhancements

- **Voice Input**: Speech-to-text integration
- **File Attachments**: Support for image and document uploads
- **Real-time Collaboration**: Multi-user chat support
- **Advanced AI Features**: Context awareness and memory
- **Custom Themes**: User-defined styling options
- **Export Functionality**: Save chat history and itineraries
- **Offline Support**: Local storage and sync
- **Push Notifications**: Real-time updates


