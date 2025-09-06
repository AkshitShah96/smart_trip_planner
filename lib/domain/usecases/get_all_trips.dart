import '../entities/trip.dart';
import '../repositories/trip_repository.dart';

class GetAllTrips {
  final TripRepository repository;

  GetAllTrips(this.repository);

  Future<List<Trip>> call() async {
    return await repository.getAllTrips();
  }
}


