import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../models/chat_streaming_models.dart';
import '../../data/models/itinerary.dart';
import '../../presentation/widgets/chat_message_widget.dart';
import '../../presentation/widgets/itinerary_diff_widget.dart';

/// Example demonstrating the integrated chat system with AgentService
class ChatIntegrationExample extends ConsumerStatefulWidget {
  const ChatIntegrationExample({super.key});

  @override
  ConsumerState<ChatIntegrationExample> createState() => _ChatIntegrationExampleState();
}

class _ChatIntegrationExampleState extends ConsumerState<ChatIntegrationExample> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final messages = chatState.messages;
    final isStreaming = chatState.isStreaming;

    // Listen for new messages and scroll to bottom
    ref.listen(chatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Trip Planner Chat'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showItineraryHistory(context),
            icon: const Icon(Icons.history),
            tooltip: 'View Itinerary History',
          ),
          IconButton(
            onPressed: () => ref.read(chatProvider.notifier).clearChat(),
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
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
          
          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask about your trip...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: isStreaming ? null : _sendMessage,
                  mini: true,
                  backgroundColor: Colors.blue[600],
                  child: isStreaming
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[400]!, Colors.blue[600]!],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.travel_explore,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Welcome to AI Trip Planner!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'I can help you plan amazing trips. Try asking:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildSuggestionChip('Plan a 3-day trip to Tokyo'),
            _buildSuggestionChip('What should I see in Paris?'),
            _buildSuggestionChip('Add a visit to the Eiffel Tower'),
            _buildSuggestionChip('Change the restaurant for dinner'),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          _messageController.text = text;
          _sendMessage();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.blue[800],
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    ref.read(chatProvider.notifier).sendMessage(message);
  }

  void _showItineraryDetails(BuildContext context, StreamingChatMessage message) {
    if (message.itinerary == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message.itinerary!.title),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: message.hasChanges && message.diff != null
              ? ItineraryDiffWidget(
                  diffResult: ItineraryDiffResult(
                    itinerary: message.itinerary!,
                    diff: message.diff,
                    hasChanges: message.hasChanges,
                  ),
                  showChangeDetails: true,
                  onAcceptChanges: () {
                    Navigator.of(context).pop();
                    _showSnackBar('Changes accepted!', Colors.green);
                  },
                  onRejectChanges: () {
                    Navigator.of(context).pop();
                    _showSnackBar('Changes rejected!', Colors.red);
                  },
                )
              : _buildItineraryDetails(message.itinerary!),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryDetails(Itinerary itinerary) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${itinerary.startDate} - ${itinerary.endDate}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ...itinerary.days.map((day) {
            final dayIndex = itinerary.days.indexOf(day);
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Day ${dayIndex + 1} - ${day.date}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    day.summary,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...day.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 60,
                            child: Text(
                              item.time,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.activity,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 12,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        item.location,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _showItineraryHistory(BuildContext context) {
    final messagesWithItineraries = ref.read(chatProvider).messagesWithItineraries;
    
    if (messagesWithItineraries.isEmpty) {
      _showSnackBar('No itineraries found in chat history', Colors.orange);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Itinerary History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: messagesWithItineraries.length,
            itemBuilder: (context, index) {
              final message = messagesWithItineraries[index];
              return ListTile(
                leading: Icon(
                  Icons.travel_explore,
                  color: message.hasChanges ? Colors.orange : Colors.blue,
                ),
                title: Text(message.itinerary?.title ?? 'Unknown'),
                subtitle: Text(
                  '${message.itinerary?.startDate} - ${message.itinerary?.endDate}',
                ),
                trailing: message.hasChanges
                    ? const Icon(Icons.edit, color: Colors.orange)
                    : null,
                onTap: () {
                  Navigator.of(context).pop();
                  _showItineraryDetails(context, message);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}

/// Example of using the chat system programmatically
class ChatSystemExample {
  static Future<void> demonstrateChatFlow() async {
    // This would be used in a test or demo context
    print('=== Chat System Integration Demo ===');
    
    // 1. User sends initial message
    print('1. User: "Plan a 2-day trip to Kyoto"');
    
    // 2. AI generates itinerary with streaming
    print('2. AI: Generating itinerary with streaming response...');
    
    // 3. Display itinerary in chat
    print('3. Display: Itinerary card with 2 days planned');
    
    // 4. User requests refinement
    print('4. User: "Add a visit to Fushimi Inari Shrine"');
    
    // 5. AI shows diff with changes
    print('5. AI: Shows modified itinerary with diff highlighting');
    
    // 6. User accepts changes
    print('6. User: Accepts changes');
    
    print('=== Demo Complete ===');
  }

  static void demonstrateMessageTypes() {
    print('=== Message Types Demo ===');
    
    // User message
    final userMessage = StreamingChatMessage.user('Plan a trip to Tokyo');
    print('User Message: ${userMessage.content}');
    
    // AI message with itinerary
    final aiMessage = StreamingChatMessage.ai('I\'ve planned your Tokyo trip!');
    print('AI Message: ${aiMessage.content}');
    
    // Streaming message
    final streamingMessage = StreamingChatMessage.streaming('Generating...');
    print('Streaming Message: ${streamingMessage.isStreaming}');
    
    print('=== Message Types Demo Complete ===');
  }

  static void demonstrateStreamingResponse() {
    print('=== Streaming Response Demo ===');
    
    // Create stream response
    final response = StreamResponse.empty();
    
    // Add chunks
    final chunk1 = StreamChunk.text('I\'ve generated your itinerary: ');
    final chunk2 = StreamChunk.text('"Tokyo Adventure"\n\n');
    final chunk3 = StreamChunk.text('📅 2024-03-15 to 2024-03-17\n\n');
    final chunk4 = StreamChunk.complete();
    
    print('Chunk 1: ${chunk1.content}');
    print('Chunk 2: ${chunk2.content}');
    print('Chunk 3: ${chunk3.content}');
    print('Chunk 4: ${chunk4.type}');
    
    print('=== Streaming Response Demo Complete ===');
  }
}

/// Example of chat state management
class ChatStateExample {
  static void demonstrateStateManagement() {
    print('=== Chat State Management Demo ===');
    
    // Initial state
    final initialState = ChatState.initial();
    print('Initial state: ${initialState.messages.length} messages');
    
    // Add user message
    final userMessage = StreamingChatMessage.user('Hello!');
    final stateWithUser = initialState.addMessage(userMessage);
    print('After user message: ${stateWithUser.messages.length} messages');
    
    // Add AI message
    final aiMessage = StreamingChatMessage.ai('Hi! How can I help you?');
    final stateWithAI = stateWithUser.addMessage(aiMessage);
    print('After AI message: ${stateWithAI.messages.length} messages');
    
    // Start streaming
    final streamingState = stateWithAI.startStreaming('stream-123');
    print('Streaming: ${streamingState.isStreaming}');
    
    // Stop streaming
    final finalState = streamingState.stopStreaming();
    print('Final state: ${finalState.isStreaming}');
    
    print('=== Chat State Management Demo Complete ===');
  }
}


