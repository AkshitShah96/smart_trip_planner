import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/agent_service.dart';
import '../providers/agent_service_provider.dart';
import '../../domain/entities/chat_message.dart';
import '../../data/models/itinerary.dart';

/// Example usage of AgentService in a Flutter widget
class AgentServiceUsageExample extends ConsumerWidget {
  const AgentServiceUsageExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentService = ref.watch(agentServiceProvider);
    final isAvailable = ref.watch(isAgentServiceAvailableProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Service Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agent Service Status: ${isAvailable ? "Available" : "Not Available"}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            if (agentService != null) ...[
              ElevatedButton(
                onPressed: () => _generateNewItinerary(agentService),
                child: const Text('Generate New Itinerary'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _refineItinerary(agentService),
                child: const Text('Refine Existing Itinerary'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _generateWithChatHistory(agentService),
                child: const Text('Generate with Chat History'),
              ),
            ] else ...[
              const Text('Agent Service not configured. Please add API keys.'),
            ],
          ],
        ),
      ),
    );
  }

  /// Example: Generate a new itinerary
  Future<void> _generateNewItinerary(AgentService agentService) async {
    try {
      final itinerary = await agentService.generateItinerary(
        userInput: 'Plan a 3-day trip to Tokyo with visits to temples, restaurants, and shopping areas',
      );

      print('Generated Itinerary:');
      print('Title: ${itinerary.title}');
      print('Dates: ${itinerary.startDate} to ${itinerary.endDate}');
      print('Days: ${itinerary.days.length}');
      
      for (final day in itinerary.days) {
        print('\nDay ${day.date}:');
        print('Summary: ${day.summary}');
        for (final item in day.items) {
          print('  ${item.time}: ${item.activity} at ${item.location}');
        }
      }
    } catch (e) {
      print('Error generating itinerary: $e');
    }
  }

  /// Example: Refine an existing itinerary
  Future<void> _refineItinerary(AgentService agentService) async {
    try {
      // Create a sample previous itinerary
      final previousItinerary = Itinerary(
        title: 'Tokyo Trip',
        startDate: '2024-03-15',
        endDate: '2024-03-17',
        days: [
          DayPlan(
            date: '2024-03-15',
            summary: 'Arrival and exploration',
            items: [
              DayItem(
                time: '10:00',
                activity: 'Check into hotel',
                location: 'Shibuya, Tokyo',
              ),
            ],
          ),
        ],
      );

      final refinedItinerary = await agentService.generateItinerary(
        userInput: 'Add more activities to the first day and include dinner reservations',
        previousItinerary: previousItinerary,
        isRefinement: true,
      );

      print('Refined Itinerary:');
      print('Title: ${refinedItinerary.title}');
      print('First day activities: ${refinedItinerary.days.first.items.length}');
    } catch (e) {
      print('Error refining itinerary: $e');
    }
  }

  /// Example: Generate with chat history
  Future<void> _generateWithChatHistory(AgentService agentService) async {
    try {
      final chatHistory = [
        ChatMessage(
          id: '1',
          content: 'I want to visit Japan',
          type: MessageType.user,
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
        ChatMessage(
          id: '2',
          content: 'Great! What cities are you interested in?',
          type: MessageType.ai,
          timestamp: DateTime.now().subtract(const Duration(minutes: 9)),
        ),
        ChatMessage(
          id: '3',
          content: 'Tokyo and Kyoto',
          type: MessageType.user,
          timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
        ),
      ];

      final itinerary = await agentService.generateItinerary(
        userInput: 'Create a detailed itinerary for both cities',
        chatHistory: chatHistory,
      );

      print('Generated Itinerary with Chat History:');
      print('Title: ${itinerary.title}');
      print('Days: ${itinerary.days.length}');
    } catch (e) {
      print('Error generating itinerary with chat history: $e');
    }
  }
}

/// Example of using AgentService in a Riverpod provider
final itineraryGenerationProvider = StateNotifierProvider<ItineraryGenerationNotifier, AsyncValue<Itinerary?>>((ref) {
  final agentService = ref.watch(agentServiceProvider);
  return ItineraryGenerationNotifier(agentService);
});

class ItineraryGenerationNotifier extends StateNotifier<AsyncValue<Itinerary?>> {
  final AgentService? _agentService;

  ItineraryGenerationNotifier(this._agentService) : super(const AsyncValue.data(null));

  Future<void> generateItinerary({
    required String userInput,
    Itinerary? previousItinerary,
    List<ChatMessage> chatHistory = const [],
    bool isRefinement = false,
  }) async {
    if (_agentService == null) {
      state = AsyncValue.error('Agent Service not available', StackTrace.current);
      return;
    }

    state = const AsyncValue.loading();

    try {
      final itinerary = await _agentService!.generateItinerary(
        userInput: userInput,
        previousItinerary: previousItinerary,
        chatHistory: chatHistory,
        isRefinement: isRefinement,
      );

      state = AsyncValue.data(itinerary);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void clearItinerary() {
    state = const AsyncValue.data(null);
  }
}

/// Example of error handling
class AgentServiceErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is AuthenticationError) {
      return 'Authentication failed. Please check your API key.';
    } else if (error is RateLimitError) {
      return 'Rate limit exceeded. Please try again later.';
    } else if (error is NetworkError) {
      return 'Network error. Please check your connection.';
    } else if (error is InvalidItineraryError) {
      return 'Invalid itinerary data. Please try again.';
    } else if (error is InvalidJsonError) {
      return 'Invalid response format. Please try again.';
    } else {
      return 'An unexpected error occurred: ${error.toString()}';
    }
  }

  static bool isRetryableError(dynamic error) {
    return error is NetworkError || error is RateLimitError;
  }

  static Duration getRetryDelay(dynamic error) {
    if (error is RateLimitError) {
      return const Duration(minutes: 1);
    } else if (error is NetworkError) {
      return const Duration(seconds: 5);
    } else {
      return const Duration(seconds: 1);
    }
  }
}



