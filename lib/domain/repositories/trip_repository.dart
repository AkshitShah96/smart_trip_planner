import '../entities/trip.dart';

abstract class TripRepository {
  Future<List<Trip>> getAllTrips();
  Future<Trip?> getTripById(String id);
  Future<void> saveTrip(Trip trip);
  Future<void> deleteTrip(String id);
  Future<void> updateTrip(Trip trip);
}


