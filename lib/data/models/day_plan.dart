import 'day_item.dart';

class DayPlan {
  int? id;

  late String date;

  late String summary;

  final List<DayItem> items = <DayItem>[];

  DayPlan({
    required this.date,
    required this.summary,
  });

  DayPlan.empty();

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    final dayPlan = DayPlan(
      date: json['date'] as String,
      summary: json['summary'] as String,
    );

    if (json['items'] != null) {
      final itemsList = json['items'] as List<dynamic>;
      for (final itemJson in itemsList) {
        final dayItem = DayItem.fromJson(itemJson as Map<String, dynamic>);
        dayPlan.items.add(dayItem);
      }
    }

    return dayPlan;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'summary': summary,
      'items': items.map((item) => item.toJson()).toList(),
    };
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
        other.summary == summary;
  }

  @override
  int get hashCode {
    return id.hashCode ^ date.hashCode ^ summary.hashCode;
  }
}