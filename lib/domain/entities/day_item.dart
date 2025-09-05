class DayItem {
  final int? id;
  final String time;
  final String activity;
  final String location;

  const DayItem({
    this.id,
    required this.time,
    required this.activity,
    required this.location,
  });

  DayItem copyWith({
    int? id,
    String? time,
    String? activity,
    String? location,
  }) {
    return DayItem(
      id: id ?? this.id,
      time: time ?? this.time,
      activity: activity ?? this.activity,
      location: location ?? this.location,
    );
  }

  @override
  String toString() {
    return 'DayItem(id: $id, time: $time, activity: $activity, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DayItem &&
        other.id == id &&
        other.time == time &&
        other.activity == activity &&
        other.location == location;
  }

  @override
  int get hashCode {
    return id.hashCode ^ time.hashCode ^ activity.hashCode ^ location.hashCode;
  }
}










