# Itinerary Diff System Documentation

## Overview

The Itinerary Diff System provides comprehensive change tracking and highlighting capabilities for the Smart Trip Planner app. It compares two itineraries and identifies all changes at various granularities, enabling users to see exactly what was modified, added, or removed.

## Features

- **Comprehensive Change Detection**: Identifies changes at itinerary, day, and item levels
- **Change Categorization**: Categorizes changes as added, removed, modified, or moved
- **Visual Highlighting**: Flutter widgets for highlighting changes in the UI
- **Detailed Change Information**: Provides specific details about what changed
- **Change Filtering**: Filter changes by type, granularity, or specific elements
- **Diff Integration**: Seamlessly integrated with AgentService for automatic diff generation

## Architecture

### Core Components

1. **`ItineraryChange`** - Represents a single change
2. **`ItineraryDiff`** - Contains all changes between two itineraries
3. **`ItineraryDiffEngine`** - Performs the comparison logic
4. **`ItineraryDiffResult`** - Result from AgentService with diff tracking
5. **`ItineraryDiffWidget`** - Flutter widget for displaying diffs

## Change Types

### `ChangeType`

- **`added`** - New elements added to the itinerary
- **`removed`** - Elements removed from the itinerary
- **`modified`** - Existing elements that were changed
- **`moved`** - Elements that were reordered

### `ChangeGranularity`

- **`itinerary`** - Changes to itinerary-level fields (title, dates)
- **`day`** - Changes to day-level fields (summary, date)
- **`item`** - Changes to item-level fields (time, activity, location)
- **`field`** - Changes to specific fields within items

## Usage

### Basic Diff Generation

```dart
import 'package:smart_trip_planner/core/utils/itinerary_diff_engine.dart';

// Compare two itineraries
final diff = ItineraryDiffEngine.compareItineraries(oldItinerary, newItinerary);

// Check if there are changes
if (diff.hasChanges) {
  print('Changes detected: ${diff.changes.length}');
  print('Summary: ${diff.getChangesSummary()}');
}
```

### Using AgentService with Diff Tracking

```dart
import 'package:smart_trip_planner/core/services/agent_service.dart';

// Create AgentService
final agentService = AgentServiceFactory.createWithWebSearch(
  openaiApiKey: 'your-key',
);

// Generate itinerary with diff tracking
final result = await agentService.generateItineraryWithDiff(
  userInput: 'Add a visit to Tokyo Skytree on day 2',
  previousItinerary: currentItinerary,
  isRefinement: true,
);

// Check for changes
if (result.hasChanges) {
  print('Changes: ${result.getChangesSummary()}');
  
  // Get specific change types
  final addedChanges = result.getChangesByType(ChangeType.added);
  final modifiedChanges = result.getChangesByType(ChangeType.modified);
  
  // Check specific days
  for (int i = 0; i < result.itinerary.days.length; i++) {
    if (result.hasChangesInDay(i)) {
      print('Day ${i + 1} has changes');
    }
  }
}
```

### Flutter UI Integration

```dart
import 'package:smart_trip_planner/presentation/widgets/itinerary_diff_widget.dart';

// Display itinerary with change highlighting
ItineraryDiffWidget(
  diffResult: diffResult,
  showChangeDetails: true,
  onAcceptChanges: () {
    // Handle accepting changes
    setState(() {
      currentItinerary = diffResult.itinerary;
    });
  },
  onRejectChanges: () {
    // Handle rejecting changes
    setState(() {
      diffResult = null;
    });
  },
)
```

## Change Detection Logic

### Itinerary-Level Changes

The system compares:
- **Title**: Changes to the trip title
- **Start Date**: Changes to the start date
- **End Date**: Changes to the end date

### Day-Level Changes

The system compares:
- **Day Addition**: New days added to the itinerary
- **Day Removal**: Days removed from the itinerary
- **Day Summary**: Changes to day summaries
- **Day Date**: Changes to day dates

### Item-Level Changes

The system compares:
- **Item Addition**: New items added to days
- **Item Removal**: Items removed from days
- **Item Modification**: Changes to item fields
- **Item Movement**: Items reordered within days

### Field-Level Changes

The system compares:
- **Time**: Changes to item times
- **Activity**: Changes to activity descriptions
- **Location**: Changes to locations
- **Additional Info**: Changes to additional metadata

## Change Information

### `ItineraryChange` Properties

```dart
class ItineraryChange {
  final ChangeType type;           // Type of change
  final ChangeGranularity granularity; // Level of change
  final String path;               // JSON path to changed element
  final String description;        // Human-readable description
  final dynamic oldValue;          // Previous value (null for additions)
  final dynamic newValue;          // New value (null for removals)
  final Map<String, dynamic> metadata; // Additional context
}
```

### Example Change

```dart
ItineraryChange(
  type: ChangeType.modified,
  granularity: ChangeGranularity.field,
  path: 'days[0].items[1].time',
  description: 'Time changed',
  oldValue: '12:00',
  newValue: '13:00',
  metadata: {
    'dayIndex': 0,
    'itemIndex': 1,
    'date': '2024-03-15',
  },
)
```

## Change Filtering

### By Type

```dart
// Get all added changes
final addedChanges = diff.getChangesByType(ChangeType.added);

// Get all modified changes
final modifiedChanges = diff.getChangesByType(ChangeType.modified);

// Get all removed changes
final removedChanges = diff.getChangesByType(ChangeType.removed);

// Get all moved changes
final movedChanges = diff.getChangesByType(ChangeType.moved);
```

### By Granularity

```dart
// Get itinerary-level changes
final itineraryChanges = diff.getChangesByGranularity(ChangeGranularity.itinerary);

// Get day-level changes
final dayChanges = diff.getChangesByGranularity(ChangeGranularity.day);

// Get item-level changes
final itemChanges = diff.getChangesByGranularity(ChangeGranularity.item);

// Get field-level changes
final fieldChanges = diff.getChangesByGranularity(ChangeGranularity.field);
```

### By Specific Elements

```dart
// Get changes for a specific day
final dayChanges = diff.getChangesForDay(0);

// Get changes for a specific item
final itemChanges = diff.getChangesForItem(0, 1);

// Check if specific elements have changes
final hasDayChanges = diff.hasChangesInDay(0);
final hasItemChanges = diff.hasChangesInItem(0, 1);
```

## Visual Highlighting

### Color Coding

- **Green**: Added elements
- **Red**: Removed elements
- **Orange**: Modified elements
- **Purple**: Moved elements

### Highlighting Levels

1. **Itinerary Level**: Title and date changes
2. **Day Level**: Day containers with changes
3. **Item Level**: Individual items with changes
4. **Field Level**: Specific fields within items

### UI Components

#### `ItineraryDiffWidget`

Main widget for displaying itineraries with change highlighting:

```dart
ItineraryDiffWidget(
  diffResult: diffResult,
  showChangeDetails: true,
  onAcceptChanges: () => handleAccept(),
  onRejectChanges: () => handleReject(),
)
```

#### `ChangeDetailsWidget`

Widget for displaying detailed change information:

```dart
ChangeDetailsWidget(
  diffResult: diffResult,
)
```

## Advanced Features

### Change Summaries

```dart
// Get human-readable summary
final summary = diff.getChangesSummary();
// Output: "Changes: 3 added, 2 modified, 1 removed"

// Get detailed summary
final detailedSummary = diff.summary;
// Output: {
//   'totalChanges': 6,
//   'added': 3,
//   'modified': 2,
//   'removed': 1,
//   'moved': 0,
//   'hasChanges': true,
// }
```

### Simplified Diff for UI

```dart
// Get simplified diff for easy UI consumption
final simplified = ItineraryDiffEngine.createSimplifiedDiff(diff);
// Output: {
//   'hasChanges': true,
//   'changes': [...],
//   'oldItinerary': {...},
//   'newItinerary': {...},
// }
```

### Day and Item Analysis

```dart
// Get detailed day analysis
final dayChange = ItineraryDiffEngine.getDayChanges(diff, 0);
print('Day ${dayChange.dayIndex} has ${dayChange.changes.length} changes');

// Get detailed item analysis
final itemChange = ItineraryDiffEngine.getItemChanges(diff, 0, 1);
print('Item ${itemChange.itemIndex} has ${itemChange.changes.length} changes');
```

## Performance Considerations

### Comparison Algorithm

- **Time Complexity**: O(n + m) where n and m are the number of items
- **Space Complexity**: O(k) where k is the number of changes
- **Optimization**: Uses item signatures for efficient comparison

### Memory Usage

- **Change Objects**: Minimal memory overhead per change
- **Diff Objects**: Efficient storage of change information
- **UI Rendering**: Optimized for large itineraries

## Testing

### Unit Tests

```bash
flutter test test/core/utils/itinerary_diff_engine_test.dart
```

### Test Coverage

- ✅ Basic comparison scenarios
- ✅ Change type detection
- ✅ Granularity filtering
- ✅ Edge cases
- ✅ Performance testing
- ✅ UI component testing

### Example Test

```dart
test('should detect title change', () {
  final oldItinerary = Itinerary(title: 'Old Title', ...);
  final newItinerary = Itinerary(title: 'New Title', ...);
  
  final diff = ItineraryDiffEngine.compareItineraries(oldItinerary, newItinerary);
  
  expect(diff.hasChanges, isTrue);
  expect(diff.changes.first.type, ChangeType.modified);
  expect(diff.changes.first.path, 'title');
});
```

## Integration Examples

### With AgentService

```dart
// Generate itinerary with automatic diff tracking
final result = await agentService.generateItineraryWithDiff(
  userInput: 'Plan a trip to Tokyo',
);

// Check for changes
if (result.hasChanges) {
  // Show diff UI
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Changes Detected'),
      content: ItineraryDiffWidget(diffResult: result),
    ),
  );
}
```

### With State Management

```dart
// Using Riverpod
final itineraryProvider = StateNotifierProvider<ItineraryNotifier, ItineraryDiffResult?>((ref) {
  return ItineraryNotifier();
});

class ItineraryNotifier extends StateNotifier<ItineraryDiffResult?> {
  Future<void> generateItinerary(String input) async {
    final agentService = ref.read(agentServiceProvider);
    final result = await agentService.generateItineraryWithDiff(
      userInput: input,
      previousItinerary: state?.itinerary,
    );
    state = result;
  }
}
```

## Best Practices

### Change Handling

1. **Always Check for Changes**: Verify `hasChanges` before processing
2. **Use Appropriate Granularity**: Choose the right level for your use case
3. **Handle Edge Cases**: Consider empty itineraries and null values
4. **Optimize UI Updates**: Only re-render changed elements

### Performance

1. **Batch Changes**: Process multiple changes together
2. **Lazy Loading**: Load change details on demand
3. **Caching**: Cache diff results when appropriate
4. **Debouncing**: Debounce rapid changes

### User Experience

1. **Clear Visual Indicators**: Use consistent colors and icons
2. **Descriptive Messages**: Provide clear change descriptions
3. **Action Buttons**: Offer accept/reject options
4. **Change Details**: Allow users to see detailed change information

## Troubleshooting

### Common Issues

1. **No Changes Detected**
   - Check if itineraries are actually different
   - Verify comparison logic
   - Check for null values

2. **Incorrect Change Detection**
   - Verify item signatures
   - Check comparison algorithm
   - Review change categorization

3. **Performance Issues**
   - Optimize comparison algorithm
   - Implement change batching
   - Use lazy loading

### Debug Mode

```dart
// Enable detailed logging
final diff = ItineraryDiffEngine.compareItineraries(oldItinerary, newItinerary);
print('Diff details: ${diff.changes.map((c) => c.toString()).join('\n')}');
```

## Future Enhancements

- **Change Merging**: Merge multiple changes into single operations
- **Change History**: Track change history over time
- **Undo/Redo**: Implement undo/redo functionality
- **Change Templates**: Predefined change patterns
- **Real-time Sync**: Live change synchronization
- **Conflict Resolution**: Handle conflicting changes
- **Change Analytics**: Analyze change patterns
- **Custom Highlighting**: User-defined highlighting rules



