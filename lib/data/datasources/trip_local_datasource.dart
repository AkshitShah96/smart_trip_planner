import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/trip_model.dart';

abstract class TripLocalDataSource {
  Future<List<TripModel>> getAllTrips();
  Future<TripModel?> getTripById(String id);
  Future<void> saveTrip(TripModel trip);
  Future<void> deleteTrip(String id);
  Future<void> updateTrip(TripModel trip);
}

class TripLocalDataSourceImpl implements TripLocalDataSource {
  static const String _fileName = 'trips.json';

  Future<File> get _file async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  @override
  Future<List<TripModel>> getAllTrips() async {
    try {
      final file = await _file;
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      final List<dynamic> jsonList = json.decode(contents);
      return jsonList.map((json) => TripModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<TripModel?> getTripById(String id) async {
    final trips = await getAllTrips();
    try {
      return trips.firstWhere((trip) => trip.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveTrip(TripModel trip) async {
    final trips = await getAllTrips();
    trips.add(trip);
    await _saveTripsToFile(trips);
  }

  @override
  Future<void> deleteTrip(String id) async {
    final trips = await getAllTrips();
    trips.removeWhere((trip) => trip.id == id);
    await _saveTripsToFile(trips);
  }

  @override
  Future<void> updateTrip(TripModel trip) async {
    final trips = await getAllTrips();
    final index = trips.indexWhere((t) => t.id == trip.id);
    if (index != -1) {
      trips[index] = trip;
      await _saveTripsToFile(trips);
    }
  }

  Future<void> _saveTripsToFile(List<TripModel> trips) async {
    final file = await _file;
    final jsonList = trips.map((trip) => trip.toJson()).toList();
    await file.writeAsString(json.encode(jsonList));
  }
}

















