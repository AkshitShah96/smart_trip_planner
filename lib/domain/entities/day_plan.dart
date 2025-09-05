import 'day_item.dart';

class DayPlan {
  final int? id;
  final String date;
  final String summary;
  final List<DayItem> items;

  const DayPlan({
    this.id,
    required this.date,
    required this.summary,
    required this.items,
  });

  DayPlan copyWith({
    int? id,
    String? date,
    String? summary,
    List<DayItem>? items,
  }) {
    return DayPlan(
      id: id ?? this.id,
      date: date ?? this.date,
      summary: summary ?? this.summary,
      items: items ?? this.items,
    );
  }

  @override
  String toString() {
    return 'DayPlan(id: $id, date: $date, summary: $summary, items: ${items.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DayPlan &&
        other.id == id &&
        other.date == date &&
        other.summary == summary &&
        other.items == items;
  }

  @override
  int get hashCode {
    return id.hashCode ^ date.hashCode ^ summary.hashCode ^ items.hashCode;
  }
}

















