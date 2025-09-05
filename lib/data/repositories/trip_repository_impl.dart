import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import '../datasources/trip_local_datasource.dart';
import '../models/trip_model.dart';

class TripRepositoryImpl implements TripRepository {
  final TripLocalDataSource localDataSource;

  TripRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Trip>> getAllTrips() async {
    final tripModels = await localDataSource.getAllTrips();
    return tripModels;
  }

  @override
  Future<Trip?> getTripById(String id) async {
    return await localDataSource.getTripById(id);
  }

  @override
  Future<void> saveTrip(Trip trip) async {
    final tripModel = TripModel.fromEntity(trip);
    await localDataSource.saveTrip(tripModel);
  }

  @override
  Future<void> deleteTrip(String id) async {
    await localDataSource.deleteTrip(id);
  }

  @override
  Future<void> updateTrip(Trip trip) async {
    final tripModel = TripModel.fromEntity(trip);
    await localDataSource.updateTrip(tripModel);
  }
}










