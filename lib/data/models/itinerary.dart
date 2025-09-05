import 'day_plan.dart';

class Itinerary {
  int? id;

  late String title;

  late String startDate;

  late String endDate;

  final List<DayPlan> days = <DayPlan>[];

  Itinerary({
    required this.title,
    required this.startDate,
    required this.endDate,
  });

  Itinerary.empty();

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    final itinerary = Itinerary(
      title: json['title'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
    );

 Add days if they exist
    if (json['days'] != null) {
      final daysList = json['days'] as List<dynamic>;
      for (final dayJson in daysList) {
        final dayPlan = DayPlan.fromJson(dayJson as Map<String, dynamic>);
        itinerary.days.add(dayPlan);
      }
    }

    return itinerary;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'startDate': startDate,
      'endDate': endDate,
      'days': days.map((day) => day.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'Itinerary(id: $id, title: $title, startDate: $startDate, endDate: $endDate, days: ${days.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Itinerary &&
        other.id == id &&
        other.title == title &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        startDate.hashCode ^
        endDate.hashCode;
  }
}

