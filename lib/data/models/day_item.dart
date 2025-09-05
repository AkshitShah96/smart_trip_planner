class DayItem {
  int? id;

  late String time;

  late String activity;

  late String location;

  DayItem({
    required this.time,
    required this.activity,
    required this.location,
  });

  DayItem.empty();

  factory DayItem.fromJson(Map<String, dynamic> json) {
    return DayItem(
      time: json['time'] as String,
      activity: json['activity'] as String,
      location: json['location'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time,
      'activity': activity,
      'location': location,
    };
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
    return id.hashCode ^
        time.hashCode ^
        activity.hashCode ^
        location.hashCode;
  }
}

