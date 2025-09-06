import 'package:smart_trip_planner/data/models/itinerary.dart';
import 'package:smart_trip_planner/data/models/day_plan.dart';
import 'package:smart_trip_planner/data/models/day_item.dart';
import '../utils/itinerary_diff_engine.dart';

/// Types of changes that can occur in an itinerary
enum ChangeType {
  added,
  removed,
  modified,
  moved,
}

/// Granularity of changes
enum ChangeGranularity {
  itinerary,    // Changes to itinerary-level fields
  day,          // Changes to day-level fields
  item,         // Changes to item-level fields
  field,        // Changes to specific fields
}

/// A single change in the itinerary
class ItineraryChange {
  final ChangeType type;
  final ChangeGranularity granularity;
  final String path;           // JSON path to the changed element
  final String description;    // Human-readable description
  final dynamic oldValue;      // Previous value (null for additions)
  final dynamic newValue;      // New value (null for removals)
  final Map<String, dynamic> metadata; // Additional context

  const ItineraryChange({
    required this.type,
    required this.granularity,
    required this.path,
    required this.description,
    this.oldValue,
    this.newValue,
    this.metadata = const {},
  });

  /// Create an addition change
  factory ItineraryChange.added({
    required String path,
    required String description,
    required dynamic newValue,
    ChangeGranularity granularity = ChangeGranularity.field,
    Map<String, dynamic> metadata = const {},
  }) {
    return ItineraryChange(
      type: ChangeType.added,
      granularity: granularity,
      path: path,
      description: description,
      newValue: newValue,
      metadata: metadata,
    );
  }

  /// Create a removal change
  factory ItineraryChange.removed({
    required String path,
    required String description,
    required dynamic oldValue,
    ChangeGranularity granularity = ChangeGranularity.field,
    Map<String, dynamic> metadata = const {},
  }) {
    return ItineraryChange(
      type: ChangeType.removed,
      granularity: granularity,
      path: path,
      description: description,
      oldValue: oldValue,
      metadata: metadata,
    );
  }

  /// Create a modification change
  factory ItineraryChange.modified({
    required String path,
    required String description,
    required dynamic oldValue,
    required dynamic newValue,
    ChangeGranularity granularity = ChangeGranularity.field,
    Map<String, dynamic> metadata = const {},
  }) {
    return ItineraryChange(
      type: ChangeType.modified,
      granularity: granularity,
      path: path,
      description: description,
      oldValue: oldValue,
      newValue: newValue,
      metadata: metadata,
    );
  }

  /// Create a move change
  factory ItineraryChange.moved({
    required String path,
    required String description,
    required dynamic oldValue,
    required dynamic newValue,
    required int oldIndex,
    required int newIndex,
    Map<String, dynamic> metadata = const {},
  }) {
    return ItineraryChange(
      type: ChangeType.moved,
      granularity: ChangeGranularity.item,
      path: path,
      description: description,
      oldValue: oldValue,
      newValue: newValue,
      metadata: {
        ...metadata,
        'oldIndex': oldIndex,
        'newIndex': newIndex,
      },
    );
  }

  @override
  String toString() {
    return 'ItineraryChange(type: $type, granularity: $granularity, path: $path, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItineraryChange &&
        other.type == type &&
        other.granularity == granularity &&
        other.path == path &&
        other.description == description &&
        other.oldValue == oldValue &&
        other.newValue == newValue;
  }

  @override
  int get hashCode {
    return type.hashCode ^
        granularity.hashCode ^
        path.hashCode ^
        description.hashCode ^
        oldValue.hashCode ^
        newValue.hashCode;
  }
}

/// Result of comparing two itineraries
class ItineraryDiff {
  final Itinerary oldItinerary;
  final Itinerary newItinerary;
  final List<ItineraryChange> changes;
  final bool hasChanges;
  final Map<String, dynamic> summary;

  const ItineraryDiff({
    required this.oldItinerary,
    required this.newItinerary,
    required this.changes,
    required this.hasChanges,
    required this.summary,
  });

  /// Get changes by type
  List<ItineraryChange> getChangesByType(ChangeType type) {
    return changes.where((change) => change.type == type).toList();
  }

  /// Get changes by granularity
  List<ItineraryChange> getChangesByGranularity(ChangeGranularity granularity) {
    return changes.where((change) => change.granularity == granularity).toList();
  }

  /// Get changes for a specific day
  List<ItineraryChange> getChangesForDay(int dayIndex) {
    return changes.where((change) => 
      change.path.startsWith('days[$dayIndex]') ||
      change.metadata['dayIndex'] == dayIndex
    ).toList();
  }

  /// Get changes for a specific item
  List<ItineraryChange> getChangesForItem(int dayIndex, int itemIndex) {
    return changes.where((change) => 
      change.path.startsWith('days[$dayIndex].items[$itemIndex]') ||
      (change.metadata['dayIndex'] == dayIndex && 
       change.metadata['itemIndex'] == itemIndex)
    ).toList();
  }

  /// Check if a specific day has changes
  bool hasChangesInDay(int dayIndex) {
    return getChangesForDay(dayIndex).isNotEmpty;
  }

  /// Check if a specific item has changes
  bool hasChangesInItem(int dayIndex, int itemIndex) {
    return getChangesForItem(dayIndex, itemIndex).isNotEmpty;
  }

  /// Get a summary of changes
  String getChangesSummary() {
    if (!hasChanges) return 'No changes detected';
    
    final added = getChangesByType(ChangeType.added).length;
    final removed = getChangesByType(ChangeType.removed).length;
    final modified = getChangesByType(ChangeType.modified).length;
    final moved = getChangesByType(ChangeType.moved).length;
    
    final parts = <String>[];
    if (added > 0) parts.add('$added added');
    if (removed > 0) parts.add('$removed removed');
    if (modified > 0) parts.add('$modified modified');
    if (moved > 0) parts.add('$moved moved');
    
    return 'Changes: ${parts.join(', ')}';
  }

  @override
  String toString() {
    return 'ItineraryDiff(hasChanges: $hasChanges, changes: ${changes.length})';
  }
}

/// Day-level change information
class DayChange {
  final int dayIndex;
  final DayPlan? oldDay;
  final DayPlan? newDay;
  final List<ItineraryChange> changes;
  final bool hasChanges;

  const DayChange({
    required this.dayIndex,
    this.oldDay,
    this.newDay,
    required this.changes,
    required this.hasChanges,
  });

  /// Get changes for items in this day
  List<ItineraryChange> getItemChanges() {
    return changes.where((change) => 
      change.granularity == ChangeGranularity.item ||
      change.path.contains('.items[')
    ).toList();
  }

  /// Get changes for day-level fields
  List<ItineraryChange> getDayFieldChanges() {
    return changes.where((change) => 
      change.granularity == ChangeGranularity.day ||
      (change.path.startsWith('days[$dayIndex]') && 
       !change.path.contains('.items['))
    ).toList();
  }
}

/// Item-level change information
class ItemChange {
  final int dayIndex;
  final int itemIndex;
  final DayItem? oldItem;
  final DayItem? newItem;
  final List<ItineraryChange> changes;
  final bool hasChanges;

  const ItemChange({
    required this.dayIndex,
    required this.itemIndex,
    this.oldItem,
    this.newItem,
    required this.changes,
    required this.hasChanges,
  });

  /// Get changes for specific fields
  List<ItineraryChange> getFieldChanges() {
    return changes.where((change) => 
      change.granularity == ChangeGranularity.field
    ).toList();
  }
}

/// Result of generating an itinerary with diff tracking
class ItineraryDiffResult {
  final Itinerary itinerary;
  final ItineraryDiff? diff;
  final bool hasChanges;

  const ItineraryDiffResult({
    required this.itinerary,
    this.diff,
    required this.hasChanges,
  });

  /// Get changes summary
  String getChangesSummary() {
    if (diff == null) return 'No previous itinerary to compare';
    return diff!.getChangesSummary();
  }

  /// Get changes by type
  List<ItineraryChange> getChangesByType(ChangeType type) {
    if (diff == null) return [];
    return diff!.getChangesByType(type);
  }

  /// Get changes by granularity
  List<ItineraryChange> getChangesByGranularity(ChangeGranularity granularity) {
    if (diff == null) return [];
    return diff!.getChangesByGranularity(granularity);
  }

  /// Get changes for a specific day
  List<ItineraryChange> getChangesForDay(int dayIndex) {
    if (diff == null) return [];
    return diff!.getChangesForDay(dayIndex);
  }

  /// Get changes for a specific item
  List<ItineraryChange> getChangesForItem(int dayIndex, int itemIndex) {
    if (diff == null) return [];
    return diff!.getChangesForItem(dayIndex, itemIndex);
  }

  /// Check if a specific day has changes
  bool hasChangesInDay(int dayIndex) {
    if (diff == null) return false;
    return diff!.hasChangesInDay(dayIndex);
  }

  /// Check if a specific item has changes
  bool hasChangesInItem(int dayIndex, int itemIndex) {
    if (diff == null) return false;
    return diff!.hasChangesInItem(dayIndex, itemIndex);
  }

  /// Get simplified diff for UI
  Map<String, dynamic> getSimplifiedDiff() {
    if (diff == null) return {'hasChanges': false, 'changes': []};
    return ItineraryDiffEngine.createSimplifiedDiff(diff!);
  }

  @override
  String toString() {
    return 'ItineraryDiffResult(hasChanges: $hasChanges, changes: ${diff?.changes.length ?? 0})';
  }
}
