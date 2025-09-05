import '../../domain/entities/itinerary.dart';
import '../../domain/repositories/itinerary_repository.dart';

class ItineraryRepositoryImpl implements ItineraryRepository {
  static final List<Itinerary> _temporaryStorage = [];

  @override
  Future<void> saveItinerary(Itinerary itinerary) async {
    _temporaryStorage.add(itinerary);
  }

  @override
  Future<List<Itinerary>> getAllItineraries() async {
    return List.from(_temporaryStorage);
  }

  @override
  Future<Itinerary?> getItineraryById(int id) async {
    try {
      return _temporaryStorage.firstWhere((itinerary) => itinerary.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> deleteItinerary(int id) async {
    _temporaryStorage.removeWhere((itinerary) => itinerary.id == id);
  }

  @override
  Future<void> updateItinerary(Itinerary itinerary) async {
    if (itinerary.id == null) {
      throw ArgumentError('Itinerary must have an ID to update');
    }

    final index = _temporaryStorage.indexWhere((item) => item.id == itinerary.id);
    if (index != -1) {
      _temporaryStorage[index] = itinerary;
    }
  }
}

