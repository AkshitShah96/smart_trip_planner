import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_state.dart';
import '../../core/providers/token_usage_providers.dart';

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref ref;
  
  ChatNotifier(this.ref) : super(const ChatState());

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

    final requestTokens = _estimateTokens(content);
    ref.read(tokenUsageProvider.notifier).addTokenUsage(requestTokens, 0);

    _simulateStreamingResponse();
  }

  Future<void> _simulateStreamingResponse() async {
    final aiMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    final responses = _getSampleResponses();
    final randomResponse = responses[Random().nextInt(responses.length)];
    
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

    final responseTokens = _estimateTokens(randomResponse);
    ref.read(tokenUsageProvider.notifier).addTokenUsage(0, responseTokens);
  }

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

  void clearChat() {
    state = const ChatState();
  }

  void retryLastMessage() {
    if (state.messages.isNotEmpty) {
      final lastMessage = state.messages.last;
      if (lastMessage.type == MessageType.user) {
        addUserMessage(lastMessage.content);
      }
    }
  }

  int _estimateTokens(String text) {
    if (text.isEmpty) return 0;
    final words = text.split(RegExp(r'\s+')).length;
    return (words * 1.3).round();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});

final messagesProvider = Provider<List<ChatMessage>>((ref) {
  return ref.watch(chatProvider).messages;
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(chatProvider).isLoading;
});

final errorProvider = Provider<String?>((ref) {
  return ref.watch(chatProvider).error;
});
