import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_state.dart';
import 'token_usage_providers.dart';

// Chat state notifier
class ChatNotifier extends StateNotifier<ChatState> {
  final Ref ref;
  
  ChatNotifier(this.ref) : super(const ChatState());

  // Add a user message
  void addUserMessage(String content) {
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.user,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    // Track request tokens (rough estimate: ~1.3 tokens per word)
    final requestTokens = _estimateTokens(content);
    ref.read(tokenUsageProvider.notifier).addTokenUsage(requestTokens, 0);

    // Simulate AI response with streaming
    _simulateStreamingResponse();
  }

  // Simulate streaming AI response
  Future<void> _simulateStreamingResponse() async {
    final aiMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    final responses = _getSampleResponses();
    final randomResponse = responses[Random().nextInt(responses.length)];
    
    // Create initial AI message
    final aiMessage = ChatMessage(
      id: aiMessageId,
      content: '',
      type: MessageType.ai,
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    state = state.copyWith(
      messages: [...state.messages, aiMessage],
    );

    // Simulate streaming by adding characters progressively
    String currentContent = '';
    for (int i = 0; i < randomResponse.length; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      currentContent += randomResponse[i];
      
      final updatedMessage = aiMessage.copyWith(
        content: currentContent,
        isStreaming: i < randomResponse.length - 1,
      );

      final updatedMessages = List<ChatMessage>.from(state.messages);
      updatedMessages[updatedMessages.length - 1] = updatedMessage;

      state = state.copyWith(
        messages: updatedMessages,
        isLoading: i < randomResponse.length - 1,
      );
    }

    // Track response tokens when streaming is complete
    final responseTokens = _estimateTokens(randomResponse);
    ref.read(tokenUsageProvider.notifier).addTokenUsage(0, responseTokens);
  }

  // Sample AI responses for simulation
  List<String> _getSampleResponses() {
    return [
      "I'd be happy to help you plan your trip! Based on your preferences, I recommend starting with the historical sites in the morning when they're less crowded. The Fushimi Inari Shrine is particularly beautiful during sunrise.",
      "For your Kyoto itinerary, I suggest allocating at least 2-3 hours for the Fushimi Inari Shrine. The hike to the top takes about 2-3 hours round trip, but you can also just visit the lower sections if you're short on time.",
      "Great choice! The Gion district is perfect for experiencing traditional Kyoto. I recommend visiting in the early evening to see the geishas and maikos. Don't forget to try some traditional sweets at the local tea houses.",
      "For transportation in Kyoto, I highly recommend getting a day pass for the city buses. It's very convenient and cost-effective. The subway system is also good, but buses cover more areas of interest.",
      "Weather-wise, April is perfect for visiting Kyoto! The cherry blossoms should be in full bloom, and the temperatures are mild. Just bring a light jacket for the evenings as it can get a bit chilly.",
      "Food recommendations: Try the kaiseki dinner at a traditional ryokan, visit Nishiki Market for street food, and don't miss the matcha desserts. Kyoto is famous for its tofu dishes too!",
    ];
  }

  // Clear chat history
  void clearChat() {
    state = const ChatState();
  }

  // Retry last message
  void retryLastMessage() {
    if (state.messages.isNotEmpty) {
      final lastMessage = state.messages.last;
      if (lastMessage.type == MessageType.user) {
        addUserMessage(lastMessage.content);
      }
    }
  }

  // Estimate token count (rough approximation: ~1.3 tokens per word)
  int _estimateTokens(String text) {
    if (text.isEmpty) return 0;
    // Simple word count + some overhead for formatting
    final words = text.split(RegExp(r'\s+')).length;
    return (words * 1.3).round();
  }
}

// Provider for chat state
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});

// Provider for messages list
final messagesProvider = Provider<List<ChatMessage>>((ref) {
  return ref.watch(chatProvider).messages;
});

// Provider for loading state
final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(chatProvider).isLoading;
});

// Provider for error state
final errorProvider = Provider<String?>((ref) {
  return ref.watch(chatProvider).error;
});
