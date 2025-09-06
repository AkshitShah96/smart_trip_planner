import 'package:smart_trip_planner/data/models/itinerary.dart';
import 'package:smart_trip_planner/data/models/day_plan.dart';
import 'package:smart_trip_planner/data/models/day_item.dart';
import '../models/itinerary_change.dart';

/// Engine for comparing itineraries and generating diffs
class ItineraryDiffEngine {
  /// Compare two itineraries and generate a diff
  static ItineraryDiff compareItineraries(Itinerary oldItinerary, Itinerary newItinerary) {
    final changes = <ItineraryChange>[];
    
    // Compare itinerary-level fields
    changes.addAll(_compareItineraryFields(oldItinerary, newItinerary));
    
    // Compare days
    changes.addAll(_compareDays(oldItinerary.days, newItinerary.days));
    
    // Generate summary
    final summary = _generateSummary(changes);
    
    return ItineraryDiff(
      oldItinerary: oldItinerary,
      newItinerary: newItinerary,
      changes: changes,
      hasChanges: changes.isNotEmpty,
      summary: summary,
    );
  }

  /// Compare itinerary-level fields
  static List<ItineraryChange> _compareItineraryFields(Itinerary oldItinerary, Itinerary newItinerary) {
    final changes = <ItineraryChange>[];
    
    // Compare title
    if (oldItinerary.title != newItinerary.title) {
      changes.add(ItineraryChange.modified(
        path: 'title',
        description: 'Trip title changed',
        oldValue: oldItinerary.title,
        newValue: newItinerary.title,
        granularity: ChangeGranularity.itinerary,
      ));
    }
    
    // Compare start date
    if (oldItinerary.startDate != newItinerary.startDate) {
      changes.add(ItineraryChange.modified(
        path: 'startDate',
        description: 'Start date changed',
        oldValue: oldItinerary.startDate,
        newValue: newItinerary.startDate,
        granularity: ChangeGranularity.itinerary,
      ));
    }
    
    // Compare end date
    if (oldItinerary.endDate != newItinerary.endDate) {
      changes.add(ItineraryChange.modified(
        path: 'endDate',
        description: 'End date changed',
        oldValue: oldItinerary.endDate,
        newValue: newItinerary.endDate,
        granularity: ChangeGranularity.itinerary,
      ));
    }
    
    return changes;
  }

  /// Compare days between two itineraries
  static List<ItineraryChange> _compareDays(List<DayPlan> oldDays, List<DayPlan> newDays) {
    final changes = <ItineraryChange>[];
    
    // Find common days by date
    final oldDaysByDate = <String, DayPlan>{};
    final newDaysByDate = <String, DayPlan>{};
    
    for (final day in oldDays) {
      oldDaysByDate[day.date] = day;
    }
    
    for (final day in newDays) {
      newDaysByDate[day.date] = day;
    }
    
    // Find added days
    for (final entry in newDaysByDate.entries) {
      if (!oldDaysByDate.containsKey(entry.key)) {
        final dayIndex = newDays.indexWhere((d) => d.date == entry.key);
        changes.add(ItineraryChange.added(
          path: 'days[$dayIndex]',
          description: 'New day added: ${entry.key}',
          newValue: entry.value,
          granularity: ChangeGranularity.day,
          metadata: {'dayIndex': dayIndex, 'date': entry.key},
        ));
      }
    }
    
    // Find removed days
    for (final entry in oldDaysByDate.entries) {
      if (!newDaysByDate.containsKey(entry.key)) {
        final dayIndex = oldDays.indexWhere((d) => d.date == entry.key);
        changes.add(ItineraryChange.removed(
          path: 'days[$dayIndex]',
          description: 'Day removed: ${entry.key}',
          oldValue: entry.value,
          granularity: ChangeGranularity.day,
          metadata: {'dayIndex': dayIndex, 'date': entry.key},
        ));
      }
    }
    
    // Compare common days
    for (final entry in newDaysByDate.entries) {
      if (oldDaysByDate.containsKey(entry.key)) {
        final oldDay = oldDaysByDate[entry.key]!;
        final newDay = entry.value;
        final dayIndex = newDays.indexWhere((d) => d.date == entry.key);
        
        changes.addAll(_compareDayFields(oldDay, newDay, dayIndex));
        changes.addAll(_compareDayItems(oldDay, newDay, dayIndex));
      }
    }
    
    return changes;
  }

  /// Compare day-level fields
  static List<ItineraryChange> _compareDayFields(DayPlan oldDay, DayPlan newDay, int dayIndex) {
    final changes = <ItineraryChange>[];
    
    // Compare summary
    if (oldDay.summary != newDay.summary) {
      changes.add(ItineraryChange.modified(
        path: 'days[$dayIndex].summary',
        description: 'Day summary changed',
        oldValue: oldDay.summary,
        newValue: newDay.summary,
        granularity: ChangeGranularity.day,
        metadata: {'dayIndex': dayIndex, 'date': newDay.date},
      ));
    }
    
    return changes;
  }

  /// Compare items within a day
  static List<ItineraryChange> _compareDayItems(DayPlan oldDay, DayPlan newDay, int dayIndex) {
    final changes = <ItineraryChange>[];
    
    // Create item signatures for comparison
    final oldItemSignatures = <String, DayItem>{};
    final newItemSignatures = <String, DayItem>{};
    
    for (int i = 0; i < oldDay.items.length; i++) {
      final item = oldDay.items[i];
      final signature = _createItemSignature(item);
      oldItemSignatures[signature] = item;
    }
    
    for (int i = 0; i < newDay.items.length; i++) {
      final item = newDay.items[i];
      final signature = _createItemSignature(item);
      newItemSignatures[signature] = item;
    }
    
    // Find added items
    for (int i = 0; i < newDay.items.length; i++) {
      final item = newDay.items[i];
      final signature = _createItemSignature(item);
      
      if (!oldItemSignatures.containsKey(signature)) {
        changes.add(ItineraryChange.added(
          path: 'days[$dayIndex].items[$i]',
          description: 'New item added: ${item.activity}',
          newValue: item,
          granularity: ChangeGranularity.item,
          metadata: {'dayIndex': dayIndex, 'itemIndex': i, 'date': newDay.date},
        ));
      }
    }
    
    // Find removed items
    for (int i = 0; i < oldDay.items.length; i++) {
      final item = oldDay.items[i];
      final signature = _createItemSignature(item);
      
      if (!newItemSignatures.containsKey(signature)) {
        changes.add(ItineraryChange.removed(
          path: 'days[$dayIndex].items[$i]',
          description: 'Item removed: ${item.activity}',
          oldValue: item,
          granularity: ChangeGranularity.item,
          metadata: {'dayIndex': dayIndex, 'itemIndex': i, 'date': oldDay.date},
        ));
      }
    }
    
    // Compare common items (by signature)
    for (final entry in newItemSignatures.entries) {
      if (oldItemSignatures.containsKey(entry.key)) {
        final oldItem = oldItemSignatures[entry.key]!;
        final newItem = entry.value;
        
        // Find the actual indices
        final oldIndex = oldDay.items.indexOf(oldItem);
        final newIndex = newDay.items.indexOf(newItem);
        
        changes.addAll(_compareItemFields(oldItem, newItem, dayIndex, newIndex));
        
        // Check if item was moved
        if (oldIndex != newIndex) {
          changes.add(ItineraryChange.moved(
            path: 'days[$dayIndex].items[$newIndex]',
            description: 'Item moved: ${newItem.activity}',
            oldValue: oldItem,
            newValue: newItem,
            oldIndex: oldIndex,
            newIndex: newIndex,
            metadata: {'dayIndex': dayIndex, 'date': newDay.date},
          ));
        }
      }
    }
    
    return changes;
  }

  /// Compare item-level fields
  static List<ItineraryChange> _compareItemFields(DayItem oldItem, DayItem newItem, int dayIndex, int itemIndex) {
    final changes = <ItineraryChange>[];
    
    // Compare time
    if (oldItem.time != newItem.time) {
      changes.add(ItineraryChange.modified(
        path: 'days[$dayIndex].items[$itemIndex].time',
        description: 'Time changed',
        oldValue: oldItem.time,
        newValue: newItem.time,
        granularity: ChangeGranularity.field,
        metadata: {'dayIndex': dayIndex, 'itemIndex': itemIndex},
      ));
    }
    
    // Compare activity
    if (oldItem.activity != newItem.activity) {
      changes.add(ItineraryChange.modified(
        path: 'days[$dayIndex].items[$itemIndex].activity',
        description: 'Activity changed',
        oldValue: oldItem.activity,
        newValue: newItem.activity,
        granularity: ChangeGranularity.field,
        metadata: {'dayIndex': dayIndex, 'itemIndex': itemIndex},
      ));
    }
    
    // Compare location
    if (oldItem.location != newItem.location) {
      changes.add(ItineraryChange.modified(
        path: 'days[$dayIndex].items[$itemIndex].location',
        description: 'Location changed',
        oldValue: oldItem.location,
        newValue: newItem.location,
        granularity: ChangeGranularity.field,
        metadata: {'dayIndex': dayIndex, 'itemIndex': itemIndex},
      ));
    }
    
    // Compare additional info
    if (oldItem.additionalInfo != newItem.additionalInfo) {
      changes.add(ItineraryChange.modified(
        path: 'days[$dayIndex].items[$itemIndex].additionalInfo',
        description: 'Additional info changed',
        oldValue: oldItem.additionalInfo,
        newValue: newItem.additionalInfo,
        granularity: ChangeGranularity.field,
        metadata: {'dayIndex': dayIndex, 'itemIndex': itemIndex},
      ));
    }
    
    return changes;
  }

  /// Create a signature for an item to identify it uniquely
  static String _createItemSignature(DayItem item) {
    return '${item.time}|${item.activity}|${item.location}';
  }

  /// Generate a summary of changes
  static Map<String, dynamic> _generateSummary(List<ItineraryChange> changes) {
    final added = changes.where((c) => c.type == ChangeType.added).length;
    final removed = changes.where((c) => c.type == ChangeType.removed).length;
    final modified = changes.where((c) => c.type == ChangeType.modified).length;
    final moved = changes.where((c) => c.type == ChangeType.moved).length;
    
    final itineraryChanges = changes.where((c) => c.granularity == ChangeGranularity.itinerary).length;
    final dayChanges = changes.where((c) => c.granularity == ChangeGranularity.day).length;
    final itemChanges = changes.where((c) => c.granularity == ChangeGranularity.item).length;
    final fieldChanges = changes.where((c) => c.granularity == ChangeGranularity.field).length;
    
    return {
      'totalChanges': changes.length,
      'added': added,
      'removed': removed,
      'modified': modified,
      'moved': moved,
      'itineraryChanges': itineraryChanges,
      'dayChanges': dayChanges,
      'itemChanges': itemChanges,
      'fieldChanges': fieldChanges,
      'hasChanges': changes.isNotEmpty,
    };
  }

  /// Get day changes for a specific day
  static DayChange getDayChanges(ItineraryDiff diff, int dayIndex) {
    final dayChanges = diff.getChangesForDay(dayIndex);
    
    final oldDay = dayIndex < diff.oldItinerary.days.length 
        ? diff.oldItinerary.days[dayIndex] 
        : null;
    final newDay = dayIndex < diff.newItinerary.days.length 
        ? diff.newItinerary.days[dayIndex] 
        : null;
    
    return DayChange(
      dayIndex: dayIndex,
      oldDay: oldDay,
      newDay: newDay,
      changes: dayChanges,
      hasChanges: dayChanges.isNotEmpty,
    );
  }

  /// Get item changes for a specific item
  static ItemChange getItemChanges(ItineraryDiff diff, int dayIndex, int itemIndex) {
    final itemChanges = diff.getChangesForItem(dayIndex, itemIndex);
    
    final oldItem = dayIndex < diff.oldItinerary.days.length && 
                   itemIndex < diff.oldItinerary.days[dayIndex].items.length
        ? diff.oldItinerary.days[dayIndex].items[itemIndex] 
        : null;
    final newItem = dayIndex < diff.newItinerary.days.length && 
                   itemIndex < diff.newItinerary.days[dayIndex].items.length
        ? diff.newItinerary.days[dayIndex].items[itemIndex] 
        : null;
    
    return ItemChange(
      dayIndex: dayIndex,
      itemIndex: itemIndex,
      oldItem: oldItem,
      newItem: newItem,
      changes: itemChanges,
      hasChanges: itemChanges.isNotEmpty,
    );
  }

  /// Create a simplified diff for UI display
  static Map<String, dynamic> createSimplifiedDiff(ItineraryDiff diff) {
    final simplifiedChanges = <Map<String, dynamic>>[];
    
    for (final change in diff.changes) {
      simplifiedChanges.add({
        'type': change.type.name,
        'granularity': change.granularity.name,
        'path': change.path,
        'description': change.description,
        'oldValue': change.oldValue,
        'newValue': change.newValue,
        'metadata': change.metadata,
      });
    }
    
    return {
      'hasChanges': diff.hasChanges,
      'summary': diff.summary,
      'changes': simplifiedChanges,
      'oldItinerary': diff.oldItinerary.toJson(),
      'newItinerary': diff.newItinerary.toJson(),
    };
  }
}



