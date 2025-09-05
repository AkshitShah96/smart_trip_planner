import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/itinerary.dart';
import '../../domain/repositories/itinerary_repository.dart';
import '../../data/repositories/itinerary_repository_impl.dart';

// Repository provider
final itineraryRepositoryProvider = Provider<ItineraryRepository>((ref) {
  return ItineraryRepositoryImpl();
});

// State for saved itineraries
class SavedItinerariesState {
  final List<Itinerary> itineraries;
  final bool isLoading;
  final String? error;

  const SavedItinerariesState({
    this.itineraries = const [],
    this.isLoading = false,
    this.error,
  });

  SavedItinerariesState copyWith({
    List<Itinerary>? itineraries,
    bool? isLoading,
    String? error,
  }) {
    return SavedItinerariesState(
      itineraries: itineraries ?? this.itineraries,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Notifier for saved itineraries
class SavedItinerariesNotifier extends StateNotifier<SavedItinerariesState> {
  final ItineraryRepository _repository;

  SavedItinerariesNotifier(this._repository) : super(const SavedItinerariesState()) {
    loadItineraries();
  }

  Future<void> loadItineraries() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final itineraries = await _repository.getAllItineraries();
      state = state.copyWith(
        itineraries: itineraries,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load itineraries: ${e.toString()}',
      );
    }
  }

  Future<void> saveItinerary(Itinerary itinerary) async {
    try {
      await _repository.saveItinerary(itinerary);
      await loadItineraries(); // Reload the list
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to save itinerary: ${e.toString()}',
      );
    }
  }

  Future<void> deleteItinerary(int id) async {
    try {
      await _repository.deleteItinerary(id);
      await loadItineraries(); // Reload the list
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to delete itinerary: ${e.toString()}',
      );
    }
  }

  Future<Itinerary?> getItineraryById(int id) async {
    try {
      return await _repository.getItineraryById(id);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to get itinerary: ${e.toString()}',
      );
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider for saved itineraries
final savedItinerariesProvider = StateNotifierProvider<SavedItinerariesNotifier, SavedItinerariesState>((ref) {
  final repository = ref.watch(itineraryRepositoryProvider);
  return SavedItinerariesNotifier(repository);
});

// Convenience providers
final itinerariesListProvider = Provider<List<Itinerary>>((ref) {
  return ref.watch(savedItinerariesProvider).itineraries;
});

final isLoadingItinerariesProvider = Provider<bool>((ref) {
  return ref.watch(savedItinerariesProvider).isLoading;
});

final itinerariesErrorProvider = Provider<String?>((ref) {
  return ref.watch(savedItinerariesProvider).error;
});













