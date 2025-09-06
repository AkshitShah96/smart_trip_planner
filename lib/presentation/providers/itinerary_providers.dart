import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/api_config.dart';
import '../../core/errors/itinerary_errors.dart';
import '../../data/services/openai_itinerary_service.dart';
import '../../data/models/itinerary.dart';
import '../../core/services/agent_service.dart';

final openaiServiceProvider = Provider<OpenAIItineraryService?>((ref) {
  try {
    final apiKey = ApiConfig.requiredOpenAIKey;
    return OpenAIItineraryService(apiKey: apiKey);
  } catch (e) {
    return null;
  }
});

final isOpenAIConfiguredProvider = Provider<bool>((ref) {
  // Always return true to enable demo mode
  return true;
});

class ItineraryGenerationState {
  final Itinerary? itinerary;
  final bool isLoading;
  final ItineraryError? error;

  const ItineraryGenerationState({
    this.itinerary,
    this.isLoading = false,
    this.error,
  });

  ItineraryGenerationState copyWith({
    Itinerary? itinerary,
    bool? isLoading,
    ItineraryError? error,
  }) {
    return ItineraryGenerationState(
      itinerary: itinerary ?? this.itinerary,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ItineraryGenerationNotifier extends StateNotifier<ItineraryGenerationState> {
  final OpenAIItineraryService? _openaiService;

  ItineraryGenerationNotifier(this._openaiService) : super(const ItineraryGenerationState());

  Future<void> generateItinerary(String prompt) async {
    print('Starting itinerary generation with prompt: $prompt');
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      Itinerary itinerary;
      
      if (_openaiService != null) {
        print('Using OpenAI service');
        // Use real OpenAI service if available
        itinerary = await _openaiService!.generateItinerary(prompt);
      } else {
        print('Using mock service for demo mode');
        // Use mock service for demo mode
        final mockService = AgentServiceFactory.createMockService();
        itinerary = await mockService.generateItinerary(
          userInput: prompt,
          chatHistory: const [],
        );
        print('Mock service generated itinerary: ${itinerary.title}');
      }
      
      state = state.copyWith(
        itinerary: itinerary,
        isLoading: false,
        error: null,
      );
      print('Itinerary generation completed successfully');
    } on ItineraryError catch (e) {
      print('ItineraryError: ${e.toString()}');
      state = state.copyWith(
        error: e,
        isLoading: false,
      );
    } catch (e) {
      print('Unexpected error: ${e.toString()}');
      state = state.copyWith(
        error: UnknownError('Unexpected error: ${e.toString()}'),
        isLoading: false,
      );
    }
  }

  void clearState() {
    state = const ItineraryGenerationState();
  }
}

final itineraryGenerationProvider = StateNotifierProvider<ItineraryGenerationNotifier, ItineraryGenerationState>((ref) {
  final openaiService = ref.watch(openaiServiceProvider);
  return ItineraryGenerationNotifier(openaiService);
});

final currentItineraryProvider = Provider<Itinerary?>((ref) {
  return ref.watch(itineraryGenerationProvider).itinerary;
});

final isGeneratingItineraryProvider = Provider<bool>((ref) {
  return ref.watch(itineraryGenerationProvider).isLoading;
});

final itineraryErrorProvider = Provider<ItineraryError?>((ref) {
  return ref.watch(itineraryGenerationProvider).error;
});




