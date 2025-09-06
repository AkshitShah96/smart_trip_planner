class Trip {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String destination;
  final List<String> activities;
  final double budget;

  const Trip({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.destination,
    required this.activities,
    required this.budget,
  });

  Trip copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? destination,
    List<String>? activities,
    double? budget,
  }) {
    return Trip(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      destination: destination ?? this.destination,
      activities: activities ?? this.activities,
      budget: budget ?? this.budget,
    );
  }
}


