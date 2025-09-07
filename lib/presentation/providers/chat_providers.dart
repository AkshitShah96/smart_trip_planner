import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_state.dart';
import '../../core/providers/token_usage_providers.dart';

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref ref;
  
  ChatNotifier(this.ref) : super(const ChatState());

  void sendMessage(String content) {
    addUserMessage(content);
  }

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
    final userMessage = state.messages.last.content.toLowerCase();
    final response = _getContextualResponse(userMessage);
    
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
    for (int i = 0; i < response.length; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      currentContent += response[i];
      
      final updatedMessage = aiMessage.copyWith(
        content: currentContent,
        isStreaming: i < response.length - 1,
      );

      final updatedMessages = List<ChatMessage>.from(state.messages);
      updatedMessages[updatedMessages.length - 1] = updatedMessage;

      state = state.copyWith(
        messages: updatedMessages,
        isLoading: i < response.length - 1,
      );
    }

    final responseTokens = _estimateTokens(response);
    ref.read(tokenUsageProvider.notifier).addTokenUsage(0, responseTokens);
  }

  String _getContextualResponse(String userMessage) {
    // Weather-related queries
    if (userMessage.contains('weather') || userMessage.contains('temperature') || 
        userMessage.contains('rain') || userMessage.contains('sunny') || 
        userMessage.contains('climate') || userMessage.contains('forecast')) {
      return "🌤️ **Weather Information** - Planet AI\n\nFor your destination, I recommend checking the current weather conditions. Generally, the best time to visit is during the dry season when temperatures are comfortable for sightseeing. Don't forget to pack appropriate clothing - layers are always a good idea for travel!";
    }
    
    // Location-related queries
    if (userMessage.contains('location') || userMessage.contains('where') || 
        userMessage.contains('place') || userMessage.contains('address') || 
        userMessage.contains('coordinates') || userMessage.contains('map')) {
      return "📍 **Location Details** - Planet AI\n\nI can help you find the exact location and provide directions! The coordinates are available in your itinerary, and you can tap 'Open in maps' to get turn-by-turn navigation. For the best experience, I recommend visiting during off-peak hours to avoid crowds.";
    }
    
    // Food-related queries
    if (userMessage.contains('food') || userMessage.contains('restaurant') || 
        userMessage.contains('eat') || userMessage.contains('dining') || 
        userMessage.contains('meal') || userMessage.contains('cuisine') ||
        userMessage.contains('lunch') || userMessage.contains('dinner') ||
        userMessage.contains('breakfast')) {
      return "🍽️ **Food Recommendations** - Planet AI\n\nI've included some amazing dining options in your itinerary! Try the local specialties and traditional dishes. For the best experience, I recommend making reservations at popular restaurants and trying street food for authentic local flavors. Don't miss the signature dishes of the region!";
    }
    
    // Transportation queries
    if (userMessage.contains('transport') || userMessage.contains('bus') || 
        userMessage.contains('train') || userMessage.contains('taxi') || 
        userMessage.contains('flight') || userMessage.contains('drive') ||
        userMessage.contains('walk') || userMessage.contains('distance')) {
      return "🚌 **Transportation Guide** - Planet AI\n\nI've planned the most efficient routes for your trip! The itinerary includes transfer times and transportation options. For local travel, I recommend using public transport for cost-effectiveness, or private transfers for comfort. All travel times are estimated and may vary based on traffic conditions.";
    }
    
    // Accommodation queries
    if (userMessage.contains('hotel') || userMessage.contains('accommodation') || 
        userMessage.contains('stay') || userMessage.contains('room') || 
        userMessage.contains('booking') || userMessage.contains('check-in')) {
      return "🏨 **Accommodation Details** - Planet AI\n\nI've selected comfortable and well-located accommodations for your stay! The hotels are strategically placed near major attractions and transportation hubs. Check-in times are typically in the afternoon, and I recommend confirming your reservation a day before arrival.";
    }
    
    // Activity/attraction queries
    if (userMessage.contains('activity') || userMessage.contains('attraction') || 
        userMessage.contains('visit') || userMessage.contains('see') || 
        userMessage.contains('explore') || userMessage.contains('tour') ||
        userMessage.contains('temple') || userMessage.contains('museum') ||
        userMessage.contains('shrine') || userMessage.contains('park')) {
      return "🎯 **Activity Information** - Planet AI\n\nYour itinerary includes carefully selected activities and attractions! Each location has been chosen for its cultural significance and visitor experience. I recommend arriving early to popular sites to avoid crowds and get the best photos. Don't forget to check opening hours and any special requirements.";
    }
    
    // Budget/cost queries
    if (userMessage.contains('cost') || userMessage.contains('price') || 
        userMessage.contains('budget') || userMessage.contains('expensive') || 
        userMessage.contains('cheap') || userMessage.contains('money') ||
        userMessage.contains('dollar') || userMessage.contains('currency')) {
      return "💰 **Budget Information** - Planet AI\n\nI've planned your trip with your budget in mind! The itinerary includes a mix of free and paid attractions, with cost-effective dining options. For the best value, I recommend booking activities in advance and taking advantage of combo tickets where available.";
    }
    
    // Time/duration queries
    if (userMessage.contains('time') || userMessage.contains('duration') || 
        userMessage.contains('hours') || userMessage.contains('days') || 
        userMessage.contains('schedule') || userMessage.contains('timing') ||
        userMessage.contains('morning') || userMessage.contains('evening') ||
        userMessage.contains('afternoon')) {
      return "⏰ **Timing & Schedule** - Planet AI\n\nI've optimized your schedule for the best experience! Each activity has been timed to avoid crowds and make the most of your day. The itinerary includes travel time between locations and allows for breaks. Feel free to adjust the timing based on your preferences.";
    }
    
    // General travel planning queries
    if (userMessage.contains('plan') || userMessage.contains('itinerary') || 
        userMessage.contains('trip') || userMessage.contains('travel') || 
        userMessage.contains('vacation') || userMessage.contains('holiday')) {
      return "🗺️ **Travel Planning** - Planet AI\n\nI'm here to help you create the perfect travel experience! Your personalized itinerary includes all the must-see attractions, local experiences, and practical information you need. I can help you refine any part of your trip or answer specific questions about your destinations.";
    }
    
    // Default response for other queries
    return "🤖 **Planet AI Assistant**\n\nHello! I'm your intelligent travel companion. I can help you with weather information, location details, food recommendations, transportation, accommodations, activities, budget planning, and timing. What specific aspect of your trip would you like to know more about?";
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
