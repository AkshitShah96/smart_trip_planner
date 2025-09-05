import '../../domain/entities/trip.dart';

class TripModel extends Trip {
  const TripModel({
    required super.id,
    required super.title,
    required super.description,
    required super.startDate,
    required super.endDate,
    required super.destination,
    required super.activities,
    required super.budget,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      destination: json['destination'] as String,
      activities: List<String>.from(json['activities'] as List),
      budget: (json['budget'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'destination': destination,
      'activities': activities,
      'budget': budget,
    };
  }

  factory TripModel.fromEntity(Trip trip) {
    return TripModel(
      id: trip.id,
      title: trip.title,
      description: trip.description,
      startDate: trip.startDate,
      endDate: trip.endDate,
      destination: trip.destination,
      activities: trip.activities,
      budget: trip.budget,
    );
  }
}

















