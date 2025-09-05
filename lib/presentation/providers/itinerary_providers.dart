import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/api_config.dart';
import '../../core/errors/itinerary_errors.dart';
import '../../data/services/openai_itinerary_service.dart';
import '../../data/models/itinerary.dart';

// Provider for OpenAI service
final openaiServiceProvider = Provider<OpenAIItineraryService?>((ref) {
  try {
    final apiKey = ApiConfig.requiredOpenAIKey;
    return OpenAIItineraryService(apiKey: apiKey);
  } catch (e) {
    // Return null if API key is not configured
    return null;
  }
});

// Provider for checking if OpenAI is configured
final isOpenAIConfiguredProvider = Provider<bool>((ref) {
  return ApiConfig.isOpenAIConfigured;
});

// State for itinerary generation
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

// Notifier for itinerary generation
class ItineraryGenerationNotifier extends StateNotifier<ItineraryGenerationState> {
  final OpenAIItineraryService? _openaiService;

  ItineraryGenerationNotifier(this._openaiService) : super(const ItineraryGenerationState());

  /// Generates an itinerary from a user prompt
  Future<void> generateItinerary(String prompt) async {
    final service = _openaiService;
    if (service == null) {
      state = state.copyWith(
        error: const AuthenticationError('OpenAI API key not configured'),
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final itinerary = await service.generateItinerary(prompt);
      state = state.copyWith(
        itinerary: itinerary,
        isLoading: false,
        error: null,
      );
    } on ItineraryError catch (e) {
      state = state.copyWith(
        error: e,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: UnknownError('Unexpected error: ${e.toString()}'),
        isLoading: false,
      );
    }
  }

  /// Clears the current state
  void clearState() {
    state = const ItineraryGenerationState();
  }
}

// Provider for itinerary generation
final itineraryGenerationProvider = StateNotifierProvider<ItineraryGenerationNotifier, ItineraryGenerationState>((ref) {
  final openaiService = ref.watch(openaiServiceProvider);
  return ItineraryGenerationNotifier(openaiService);
});

// Convenience providers
final currentItineraryProvider = Provider<Itinerary?>((ref) {
  return ref.watch(itineraryGenerationProvider).itinerary;
});

final isGeneratingItineraryProvider = Provider<bool>((ref) {
  return ref.watch(itineraryGenerationProvider).isLoading;
});

final itineraryErrorProvider = Provider<ItineraryError?>((ref) {
  return ref.watch(itineraryGenerationProvider).error;
});




