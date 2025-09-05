# Smart Trip Planner - Setup Instructions

## Current Status
The app is currently set up with temporary storage to avoid compilation errors. To enable full Isar database functionality, follow these steps:

## Step 1: Generate Isar Schema Files

Run the build runner to generate the required `.g.dart` files:

```bash
# Option 1: Use the batch file (Windows)
build_runner.bat

# Option 2: Manual commands
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Step 2: Uncomment Isar Code

After running the build runner, uncomment the following lines in these files:

### lib/data/models/itinerary.dart
```dart
// Change this:
// part 'itinerary.g.dart';

// To this:
part 'itinerary.g.dart';
```

### lib/data/models/day_plan.dart
```dart
// Change this:
// part 'day_plan.g.dart';

// To this:
part 'day_plan.g.dart';
```

### lib/data/models/day_item.dart
```dart
// Change this:
// part 'day_item.g.dart';

// To this:
part 'day_item.g.dart';
```

### lib/data/repositories/itinerary_repository_impl.dart
```dart
// Uncomment these imports:
import '../models/itinerary.dart' as data_model;
import '../models/day_plan.dart' as data_model;
import '../models/day_item.dart' as data_model;
import '../../core/database/isar_database.dart';

// Then replace the temporary storage methods with the commented Isar code
```

## Step 3: Test the App

After completing the above steps:

```bash
flutter run
```

## Current Features (Working)

✅ **Navigation**: Bottom navigation between screens
✅ **Chat Interface**: AI chat with streaming responses
✅ **Token Usage Tracking**: Debug overlay for API usage
✅ **Itinerary Generation**: AI-powered trip planning
✅ **Map Integration**: View locations on maps
✅ **Temporary Storage**: Basic CRUD operations (until Isar is enabled)

## Troubleshooting

If you encounter issues:

1. **Red errors in VS Code**: Make sure to run `flutter pub get` first
2. **Build errors**: Run `dart run build_runner build --delete-conflicting-outputs`
3. **Import errors**: Check that all `.g.dart` files are generated
4. **Database errors**: The app will work with temporary storage until Isar is properly set up

## Next Steps

Once Isar is working:
- Persistent storage will be enabled
- Data will survive app restarts
- Full database functionality will be available

The app is fully functional with temporary storage for testing and development!









