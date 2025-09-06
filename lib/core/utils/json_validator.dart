import 'dart:convert';
import 'package:smart_trip_planner/data/models/itinerary.dart';
import 'package:smart_trip_planner/data/models/day_plan.dart';
import 'package:smart_trip_planner/data/models/day_item.dart';
import '../errors/itinerary_errors.dart';

/// Validation result for JSON validation
class ValidationResult {
  final bool isValid;
  final Itinerary? itinerary;
  final List<String> errors;
  final String? regenerationRequest;

  const ValidationResult({
    required this.isValid,
    this.itinerary,
    this.errors = const [],
    this.regenerationRequest,
  });

  factory ValidationResult.success(Itinerary itinerary) {
    return ValidationResult(
      isValid: true,
      itinerary: itinerary,
    );
  }

  factory ValidationResult.failure(List<String> errors, {String? regenerationRequest}) {
    return ValidationResult(
      isValid: false,
      errors: errors,
      regenerationRequest: regenerationRequest,
    );
  }
}

/// JSON validation error types
enum ValidationErrorType {
  invalidJson,
  missingRequiredField,
  invalidFieldType,
  invalidDateFormat,
  invalidTimeFormat,
  emptyArray,
  invalidStructure,
  customValidation,
}

/// Detailed validation error
class ValidationError {
  final ValidationErrorType type;
  final String field;
  final String message;
  final dynamic expected;
  final dynamic actual;

  const ValidationError({
    required this.type,
    required this.field,
    required this.message,
    this.expected,
    this.actual,
  });

  @override
  String toString() {
    return 'ValidationError(type: $type, field: $field, message: $message)';
  }
}

/// JSON validator for LLM responses against Spec A schema
class JsonValidator {
  static const String _datePattern = r'^\d{4}-\d{2}-\d{2}$';
  static const String _timePattern = r'^\d{2}:\d{2}$';
  static final RegExp _dateRegex = RegExp(_datePattern);
  static final RegExp _timeRegex = RegExp(_timePattern);

  /// Validates JSON string against Spec A schema and returns Itinerary if valid
  static ValidationResult validateAndParseItinerary(String jsonString) {
    try {
      // Step 1: Parse JSON
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      // Step 2: Validate against Spec A schema
      final validationErrors = _validateSpecASchema(jsonData);
      
      if (validationErrors.isNotEmpty) {
        return ValidationResult.failure(
          validationErrors.map((e) => e.message).toList(),
          regenerationRequest: _generateRegenerationRequest(validationErrors),
        );
      }

      // Step 3: Parse into Itinerary model
      final itinerary = _parseItineraryFromJson(jsonData);
      
      return ValidationResult.success(itinerary);
    } catch (e) {
      return ValidationResult.failure(
        ['Invalid JSON format: ${e.toString()}'],
        regenerationRequest: _generateGenericRegenerationRequest(),
      );
    }
  }

  /// Validates JSON data against Spec A schema
  static List<ValidationError> _validateSpecASchema(Map<String, dynamic> jsonData) {
    final errors = <ValidationError>[];

    // Validate root level required fields
    errors.addAll(_validateRequiredFields(jsonData, {
      'title': String,
      'startDate': String,
      'endDate': String,
      'days': List,
    }));

    // Validate title
    if (jsonData['title'] != null) {
      final title = jsonData['title'] as String;
      if (title.trim().isEmpty) {
        errors.add(ValidationError(
          type: ValidationErrorType.emptyArray,
          field: 'title',
          message: 'Title cannot be empty',
        ));
      }
    }

    // Validate dates
    errors.addAll(_validateDateField(jsonData, 'startDate'));
    errors.addAll(_validateDateField(jsonData, 'endDate'));

    // Validate date range
    if (jsonData['startDate'] != null && jsonData['endDate'] != null) {
      try {
        final startDate = DateTime.parse(jsonData['startDate'] as String);
        final endDate = DateTime.parse(jsonData['endDate'] as String);
        
        if (endDate.isBefore(startDate)) {
          errors.add(ValidationError(
            type: ValidationErrorType.customValidation,
            field: 'endDate',
            message: 'End date must be after start date',
            expected: 'After start date',
            actual: jsonData['endDate'],
          ));
        }
      } catch (e) {
        // Date parsing errors are already handled by _validateDateField
      }
    }

    // Validate days array
    if (jsonData['days'] != null) {
      final days = jsonData['days'] as List;
      
      if (days.isEmpty) {
        errors.add(ValidationError(
          type: ValidationErrorType.emptyArray,
          field: 'days',
          message: 'Days array cannot be empty',
        ));
      } else {
        for (int i = 0; i < days.length; i++) {
          final day = days[i];
          if (day is! Map<String, dynamic>) {
            errors.add(ValidationError(
              type: ValidationErrorType.invalidFieldType,
              field: 'days[$i]',
              message: 'Day must be an object',
              expected: 'Map<String, dynamic>',
              actual: day.runtimeType,
            ));
          } else {
            errors.addAll(_validateDaySchema(day, i));
          }
        }
      }
    }

    return errors;
  }

  /// Validates a single day schema
  static List<ValidationError> _validateDaySchema(Map<String, dynamic> day, int dayIndex) {
    final errors = <ValidationError>[];

    // Validate day required fields
    errors.addAll(_validateRequiredFields(day, {
      'date': String,
      'summary': String,
      'items': List,
    }, prefix: 'days[$dayIndex]'));

    // Validate day date
    errors.addAll(_validateDateField(day, 'date', prefix: 'days[$dayIndex]'));

    // Validate summary
    if (day['summary'] != null) {
      final summary = day['summary'] as String;
      if (summary.trim().isEmpty) {
        errors.add(ValidationError(
          type: ValidationErrorType.emptyArray,
          field: 'days[$dayIndex].summary',
          message: 'Day summary cannot be empty',
        ));
      }
    }

    // Validate items array
    if (day['items'] != null) {
      final items = day['items'] as List;
      
      if (items.isEmpty) {
        errors.add(ValidationError(
          type: ValidationErrorType.emptyArray,
          field: 'days[$dayIndex].items',
          message: 'Items array cannot be empty',
        ));
      } else {
        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          if (item is! Map<String, dynamic>) {
            errors.add(ValidationError(
              type: ValidationErrorType.invalidFieldType,
              field: 'days[$dayIndex].items[$i]',
              message: 'Item must be an object',
              expected: 'Map<String, dynamic>',
              actual: item.runtimeType,
            ));
          } else {
            errors.addAll(_validateItemSchema(item, dayIndex, i));
          }
        }
      }
    }

    return errors;
  }

  /// Validates a single item schema
  static List<ValidationError> _validateItemSchema(Map<String, dynamic> item, int dayIndex, int itemIndex) {
    final errors = <ValidationError>[];

    // Validate item required fields
    errors.addAll(_validateRequiredFields(item, {
      'time': String,
      'activity': String,
      'location': String,
    }, prefix: 'days[$dayIndex].items[$itemIndex]'));

    // Validate time format
    if (item['time'] != null) {
      final time = item['time'] as String;
      if (!_timeRegex.hasMatch(time)) {
        errors.add(ValidationError(
          type: ValidationErrorType.invalidTimeFormat,
          field: 'days[$dayIndex].items[$itemIndex].time',
          message: 'Time must be in HH:MM format',
          expected: 'HH:MM',
          actual: time,
        ));
      }
    }

    // Validate activity
    if (item['activity'] != null) {
      final activity = item['activity'] as String;
      if (activity.trim().isEmpty) {
        errors.add(ValidationError(
          type: ValidationErrorType.emptyArray,
          field: 'days[$dayIndex].items[$itemIndex].activity',
          message: 'Activity cannot be empty',
        ));
      }
    }

    // Validate location
    if (item['location'] != null) {
      final location = item['location'] as String;
      if (location.trim().isEmpty) {
        errors.add(ValidationError(
          type: ValidationErrorType.emptyArray,
          field: 'days[$dayIndex].items[$itemIndex].location',
          message: 'Location cannot be empty',
        ));
      }
    }

    return errors;
  }

  /// Validates required fields exist and have correct types
  static List<ValidationError> _validateRequiredFields(
    Map<String, dynamic> data,
    Map<String, Type> requiredFields, {
    String prefix = '',
  }) {
    final errors = <ValidationError>[];

    for (final entry in requiredFields.entries) {
      final fieldName = entry.key;
      final expectedType = entry.value;
      final fullFieldName = prefix.isEmpty ? fieldName : '$prefix.$fieldName';

      if (!data.containsKey(fieldName)) {
        errors.add(ValidationError(
          type: ValidationErrorType.missingRequiredField,
          field: fullFieldName,
          message: 'Required field "$fieldName" is missing',
          expected: expectedType.toString(),
        ));
      } else {
        final value = data[fieldName];
        if (value == null) {
          errors.add(ValidationError(
            type: ValidationErrorType.missingRequiredField,
            field: fullFieldName,
            message: 'Required field "$fieldName" cannot be null',
            expected: expectedType.toString(),
            actual: 'null',
          ));
        } else if (expectedType == List && value is! List) {
          errors.add(ValidationError(
            type: ValidationErrorType.invalidFieldType,
            field: fullFieldName,
            message: 'Field "$fieldName" must be an array',
            expected: 'List',
            actual: value.runtimeType,
          ));
        } else if (expectedType == String && value is! String) {
          errors.add(ValidationError(
            type: ValidationErrorType.invalidFieldType,
            field: fullFieldName,
            message: 'Field "$fieldName" must be a string',
            expected: 'String',
            actual: value.runtimeType,
          ));
        }
      }
    }

    return errors;
  }

  /// Validates date field format
  static List<ValidationError> _validateDateField(
    Map<String, dynamic> data,
    String fieldName, {
    String prefix = '',
  }) {
    final errors = <ValidationError>[];
    final fullFieldName = prefix.isEmpty ? fieldName : '$prefix.$fieldName';

    if (data[fieldName] != null) {
      final dateString = data[fieldName] as String;
      
      if (!_dateRegex.hasMatch(dateString)) {
        errors.add(ValidationError(
          type: ValidationErrorType.invalidDateFormat,
          field: fullFieldName,
          message: 'Date must be in YYYY-MM-DD format',
          expected: 'YYYY-MM-DD',
          actual: dateString,
        ));
      } else {
        // Validate that it's a real date
        try {
          DateTime.parse(dateString);
        } catch (e) {
          errors.add(ValidationError(
            type: ValidationErrorType.invalidDateFormat,
            field: fullFieldName,
            message: 'Invalid date: $dateString',
            expected: 'Valid date in YYYY-MM-DD format',
            actual: dateString,
          ));
        }
      }
    }

    return errors;
  }

  /// Parses validated JSON into Itinerary model
  static Itinerary _parseItineraryFromJson(Map<String, dynamic> jsonData) {
    final days = (jsonData['days'] as List).map((dayJson) {
      final day = dayJson as Map<String, dynamic>;
      
      final items = (day['items'] as List).map((itemJson) {
        final item = itemJson as Map<String, dynamic>;
        return DayItem(
          time: item['time'] as String,
          activity: item['activity'] as String,
          location: item['location'] as String,
        );
      }).toList();

      final dayPlan = DayPlan(
        date: day['date'] as String,
        summary: day['summary'] as String,
      );
      
      if (day['items'] != null) {
        final itemsList = day['items'] as List<dynamic>;
        for (final itemJson in itemsList) {
          final dayItem = DayItem.fromJson(itemJson as Map<String, dynamic>);
          dayPlan.items.add(dayItem);
        }
      }
      
      return dayPlan;
    }).toList();

    final itinerary = Itinerary(
      title: jsonData['title'] as String,
      startDate: jsonData['startDate'] as String,
      endDate: jsonData['endDate'] as String,
    );
    
    itinerary.days.addAll(days);
    
    return itinerary;
  }

  /// Generates regeneration request based on validation errors
  static String _generateRegenerationRequest(List<ValidationError> errors) {
    final buffer = StringBuffer();
    
    buffer.writeln('The generated JSON has validation errors. Please fix the following issues and regenerate:');
    buffer.writeln('');
    
    for (int i = 0; i < errors.length; i++) {
      final error = errors[i];
      buffer.writeln('${i + 1}. ${error.field}: ${error.message}');
      
      if (error.expected != null && error.actual != null) {
        buffer.writeln('   Expected: ${error.expected}');
        buffer.writeln('   Actual: ${error.actual}');
      }
      buffer.writeln('');
    }
    
    buffer.writeln('Please ensure the JSON follows this exact schema:');
    buffer.writeln(_getSpecASchema());
    
    return buffer.toString();
  }

  /// Generates generic regeneration request
  static String _generateGenericRegenerationRequest() {
    return '''
The generated JSON is invalid. Please ensure it follows this exact schema:

${_getSpecASchema()}

Make sure all required fields are present and have the correct data types.
''';
  }

  /// Returns the Spec A schema specification
  static String _getSpecASchema() {
    return '''
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
''';
  }

  /// Validates JSON with retry logic for regeneration
  static Future<ValidationResult> validateWithRetry(
    String jsonString, {
    int maxRetries = 3,
    Future<String> Function(String regenerationRequest)? regenerateFunction,
  }) async {
    ValidationResult result = validateAndParseItinerary(jsonString);
    
    if (result.isValid || regenerateFunction == null) {
      return result;
    }

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final newJsonString = await regenerateFunction(result.regenerationRequest!);
        result = validateAndParseItinerary(newJsonString);
        
        if (result.isValid) {
          return result;
        }
      } catch (e) {
        // Continue to next attempt
        continue;
      }
    }

    return result; // Return last validation result
  }

  /// Quick validation check without full parsing
  static bool isValidItineraryJson(String jsonString) {
    try {
      final result = validateAndParseItinerary(jsonString);
      return result.isValid;
    } catch (e) {
      return false;
    }
  }

  /// Get validation errors without parsing
  static List<String> getValidationErrors(String jsonString) {
    try {
      final result = validateAndParseItinerary(jsonString);
      return result.errors;
    } catch (e) {
      return ['Invalid JSON: ${e.toString()}'];
    }
  }
}
