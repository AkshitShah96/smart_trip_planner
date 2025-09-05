# JsonValidator Documentation

## Overview

The `JsonValidator` utility class provides comprehensive JSON validation for LLM responses against the Spec A schema. It ensures that generated itineraries conform to the required structure and data types before being parsed into Dart models.

## Features

- **Spec A Schema Validation**: Validates against the complete itinerary schema
- **Detailed Error Reporting**: Provides specific error messages with field locations
- **Regeneration Requests**: Generates helpful prompts for LLM regeneration
- **Retry Logic**: Built-in retry mechanism with regeneration support
- **Type Safety**: Ensures all data types match expected schema
- **Date/Time Validation**: Validates date and time formats
- **Comprehensive Testing**: Extensive test coverage for all scenarios

## Spec A Schema

The validator enforces the following schema:

```json
{
  "title": "string (required, non-empty trip title)",
  "startDate": "string (required, YYYY-MM-DD format)",
  "endDate": "string (required, YYYY-MM-DD format, must be after startDate)",
  "days": [
    {
      "date": "string (required, YYYY-MM-DD format)",
      "summary": "string (required, non-empty day summary)",
      "items": [
        {
          "time": "string (required, HH:MM format)",
          "activity": "string (required, non-empty activity description)",
          "location": "string (required, non-empty location)"
        }
      ]
    }
  ]
}
```

## Usage

### Basic Validation

```dart
import 'package:smart_trip_planner/core/utils/json_validator.dart';

// Validate JSON string
final result = JsonValidator.validateAndParseItinerary(jsonString);

if (result.isValid) {
  final itinerary = result.itinerary!;
  print('Valid itinerary: ${itinerary.title}');
} else {
  print('Validation errors: ${result.errors.join(', ')}');
  if (result.regenerationRequest != null) {
    print('Regeneration request: ${result.regenerationRequest}');
  }
}
```

### Quick Validation

```dart
// Quick validation check without parsing
final isValid = JsonValidator.isValidItineraryJson(jsonString);

// Get validation errors without parsing
final errors = JsonValidator.getValidationErrors(jsonString);
```

### Retry Logic with Regeneration

```dart
// Define regeneration function
Future<String> regenerateItinerary(String request) async {
  // Call your LLM service with the regeneration request
  return await yourLLMService.generateItinerary(request);
}

// Validate with retry logic
final result = await JsonValidator.validateWithRetry(
  jsonString,
  maxRetries: 3,
  regenerateFunction: regenerateItinerary,
);
```

## Validation Rules

### Root Level Fields

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `title` | String | Yes | Non-empty, trimmed |
| `startDate` | String | Yes | YYYY-MM-DD format, valid date |
| `endDate` | String | Yes | YYYY-MM-DD format, valid date, after startDate |
| `days` | Array | Yes | Non-empty array |

### Day Object Fields

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `date` | String | Yes | YYYY-MM-DD format, valid date |
| `summary` | String | Yes | Non-empty, trimmed |
| `items` | Array | Yes | Non-empty array |

### Item Object Fields

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `time` | String | Yes | HH:MM format (24-hour) |
| `activity` | String | Yes | Non-empty, trimmed |
| `location` | String | Yes | Non-empty, trimmed |

## Error Types

The validator categorizes errors into specific types:

### `ValidationErrorType.invalidJson`
- Malformed JSON syntax
- Parsing errors

### `ValidationErrorType.missingRequiredField`
- Required fields not present
- Null values for required fields

### `ValidationErrorType.invalidFieldType`
- Wrong data type (e.g., string instead of array)
- Type mismatches

### `ValidationErrorType.invalidDateFormat`
- Invalid date format (not YYYY-MM-DD)
- Invalid dates (e.g., 2024-13-45)

### `ValidationErrorType.invalidTimeFormat`
- Invalid time format (not HH:MM)
- Invalid times (e.g., 25:00)

### `ValidationErrorType.emptyArray`
- Empty arrays where not allowed
- Empty strings where not allowed

### `ValidationErrorType.invalidStructure`
- Malformed object structure
- Missing nested objects

### `ValidationErrorType.customValidation`
- Business logic validation (e.g., endDate after startDate)
- Custom validation rules

## ValidationResult

The validation result contains:

```dart
class ValidationResult {
  final bool isValid;                    // Whether validation passed
  final Itinerary? itinerary;           // Parsed itinerary (if valid)
  final List<String> errors;            // List of error messages
  final String? regenerationRequest;    // LLM regeneration prompt
}
```

### Factory Methods

```dart
// Success result
ValidationResult.success(itinerary)

// Failure result
ValidationResult.failure(errors, regenerationRequest: request)
```

## Regeneration Requests

When validation fails, the validator generates detailed regeneration requests:

### Example Regeneration Request

```
The generated JSON has validation errors. Please fix the following issues and regenerate:

1. title: Title cannot be empty
2. startDate: Date must be in YYYY-MM-DD format
   Expected: YYYY-MM-DD
   Actual: 15-03-2024
3. days: Days array cannot be empty

Please ensure the JSON follows this exact schema:

{
  "title": "string (required, non-empty trip title)",
  "startDate": "string (required, YYYY-MM-DD format)",
  "endDate": "string (required, YYYY-MM-DD format, must be after startDate)",
  "days": [
    {
      "date": "string (required, YYYY-MM-DD format)",
      "summary": "string (required, non-empty day summary)",
      "items": [
        {
          "time": "string (required, HH:MM format)",
          "activity": "string (required, non-empty activity description)",
          "location": "string (required, non-empty location)"
        }
      ]
    }
  ]
}
```

## Integration with AgentService

The JsonValidator is automatically integrated with AgentService:

```dart
// AgentService now uses JsonValidator internally
final agentService = AgentServiceFactory.createWithWebSearch(
  openaiApiKey: 'your-key',
);

final itinerary = await agentService.generateItinerary(
  userInput: 'Plan a trip to Tokyo',
);
// Validation happens automatically
```

## Error Handling

### Common Error Scenarios

1. **Invalid JSON Format**
   ```dart
   // Input: '{"title": "Test", "invalid": json}'
   // Error: Invalid JSON format: Unexpected character
   ```

2. **Missing Required Fields**
   ```dart
   // Input: '{"title": "Test"}'
   // Error: Required field "startDate" is missing
   ```

3. **Invalid Date Format**
   ```dart
   // Input: '{"startDate": "15-03-2024"}'
   // Error: Date must be in YYYY-MM-DD format
   ```

4. **Empty Arrays**
   ```dart
   // Input: '{"days": []}'
   // Error: Days array cannot be empty
   ```

5. **Invalid Time Format**
   ```dart
   // Input: '{"time": "9:00 AM"}'
   // Error: Time must be in HH:MM format
   ```

## Testing

### Unit Tests

```bash
flutter test test/core/utils/json_validator_test.dart
```

### Test Coverage

- ✅ Valid JSON validation
- ✅ Invalid JSON format handling
- ✅ Missing required fields
- ✅ Invalid field types
- ✅ Invalid date/time formats
- ✅ Empty arrays and strings
- ✅ Date range validation
- ✅ Nested object validation
- ✅ Error categorization
- ✅ Regeneration request generation
- ✅ Utility methods
- ✅ Edge cases

### Example Test

```dart
test('should validate and parse valid itinerary JSON', () {
  const validJson = '''
  {
    "title": "Tokyo Adventure",
    "startDate": "2024-03-15",
    "endDate": "2024-03-17",
    "days": [
      {
        "date": "2024-03-15",
        "summary": "Arrival and exploration",
        "items": [
          {
            "time": "09:00",
            "activity": "Arrive at Narita Airport",
            "location": "Narita International Airport"
          }
        ]
      }
    ]
  }
  ''';

  final result = JsonValidator.validateAndParseItinerary(validJson);

  expect(result.isValid, isTrue);
  expect(result.itinerary, isNotNull);
  expect(result.itinerary!.title, 'Tokyo Adventure');
});
```

## Performance Considerations

- **Validation Speed**: O(n) where n is the number of items
- **Memory Usage**: Minimal overhead for validation
- **Error Collection**: Efficient error aggregation
- **Retry Logic**: Configurable retry limits

## Best Practices

1. **Always Validate**: Never trust LLM output without validation
2. **Handle Errors Gracefully**: Provide meaningful error messages to users
3. **Use Retry Logic**: Implement regeneration for better success rates
4. **Log Validation Errors**: Monitor validation failures for improvements
5. **Test Edge Cases**: Validate with various input scenarios

## Troubleshooting

### Common Issues

1. **"Invalid JSON format"**
   - Check JSON syntax
   - Ensure proper escaping
   - Validate with JSON linter

2. **"Missing required field"**
   - Verify all required fields are present
   - Check for typos in field names
   - Ensure proper nesting

3. **"Invalid date format"**
   - Use YYYY-MM-DD format
   - Validate date ranges
   - Check for valid dates

4. **"Empty array"**
   - Ensure arrays have content
   - Check for null values
   - Validate array structure

### Debug Mode

Enable detailed logging:

```dart
// Add logging to see validation details
final result = JsonValidator.validateAndParseItinerary(jsonString);
if (!result.isValid) {
  print('Validation failed:');
  for (final error in result.errors) {
    print('  - $error');
  }
}
```

## Future Enhancements

- **Custom Validation Rules**: User-defined validation logic
- **Schema Versioning**: Support for different schema versions
- **Performance Optimization**: Faster validation for large datasets
- **Enhanced Error Messages**: More descriptive error descriptions
- **Validation Caching**: Cache validation results for repeated inputs
- **Async Validation**: Non-blocking validation for large JSON
- **Schema Evolution**: Automatic migration between schema versions


