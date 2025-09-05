import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/trip_local_datasource.dart';
import '../../data/repositories/trip_repository_impl.dart';
import '../../domain/repositories/trip_repository.dart';
import '../../domain/usecases/get_all_trips.dart';
import '../../domain/usecases/save_trip.dart';
import '../../domain/entities/trip.dart';

final tripLocalDataSourceProvider = Provider<TripLocalDataSource>((ref) {
  return TripLocalDataSourceImpl();
});

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final localDataSource = ref.watch(tripLocalDataSourceProvider);
  return TripRepositoryImpl(localDataSource: localDataSource);
});
final getAllTripsProvider = Provider<GetAllTrips>((ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return GetAllTrips(repository);
});

final saveTripProvider = Provider<SaveTrip>((ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return SaveTrip(repository);
});

final tripsProvider = FutureProvider<List<Trip>>((ref) async {
  final getAllTrips = ref.watch(getAllTripsProvider);
  return await getAllTrips();
});

final tripListStateProvider = StateNotifierProvider<TripListNotifier, AsyncValue<List<Trip>>>((ref) {
  final getAllTrips = ref.watch(getAllTripsProvider);
  final saveTrip = ref.watch(saveTripProvider);
  return TripListNotifier(getAllTrips, saveTrip);
});

class TripListNotifier extends StateNotifier<AsyncValue<List<Trip>>> {
  final GetAllTrips _getAllTrips;
  final SaveTrip _saveTrip;

  TripListNotifier(this._getAllTrips, this._saveTrip) : super(const AsyncValue.loading()) {
    loadTrips();
  }

  Future<void> loadTrips() async {
    state = const AsyncValue.loading();
    try {
      final trips = await _getAllTrips();
      state = AsyncValue.data(trips);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addTrip(Trip trip) async {
    try {
      await _saveTrip(trip);
      await loadTrips();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}













