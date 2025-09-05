import '../entities/itinerary.dart';

abstract class ItineraryRepository {
  Future<void> saveItinerary(Itinerary itinerary);
  Future<List<Itinerary>> getAllItineraries();
  Future<Itinerary?> getItineraryById(int id);
  Future<void> deleteItinerary(int id);
  Future<void> updateItinerary(Itinerary itinerary);
}










