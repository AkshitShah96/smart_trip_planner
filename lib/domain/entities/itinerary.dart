import 'day_plan.dart';

class Itinerary {
  final int? id;
  final String title;
  final String startDate;
  final String endDate;
  final List<DayPlan> days;

  const Itinerary({
    this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.days,
  });

  Itinerary copyWith({
    int? id,
    String? title,
    String? startDate,
    String? endDate,
    List<DayPlan>? days,
  }) {
    return Itinerary(
      id: id ?? this.id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      days: days ?? this.days,
    );
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
        other.endDate == endDate &&
        other.days == days;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        startDate.hashCode ^
        endDate.hashCode ^
        days.hashCode;
  }
}

















