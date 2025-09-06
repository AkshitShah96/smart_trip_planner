import '../entities/trip.dart';
import '../repositories/trip_repository.dart';

class SaveTrip {
  final TripRepository repository;

  SaveTrip(this.repository);

  Future<void> call(Trip trip) async {
    await repository.saveTrip(trip);
  }
}


