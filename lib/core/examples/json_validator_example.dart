import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/json_validator.dart';
import '../../data/models/itinerary.dart';

/// Example demonstrating JsonValidator usage
class JsonValidatorExample extends ConsumerStatefulWidget {
  const JsonValidatorExample({super.key});

  @override
  ConsumerState<JsonValidatorExample> createState() => _JsonValidatorExampleState();
}

class _JsonValidatorExampleState extends ConsumerState<JsonValidatorExample> {
  final TextEditingController _jsonController = TextEditingController();
  String _validationResult = '';
  bool _isValidating = false;

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JSON Validator Example'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // JSON Input
            const Text(
              'Enter JSON to validate:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _jsonController,
                decoration: InputDecoration(
                  hintText: 'Paste your JSON here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: null,
                expands: true,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isValidating ? null : _validateJson,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                  child: _isValidating 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Validate JSON'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loadValidExample,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Load Valid Example'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loadInvalidExample,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Load Invalid Example'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Validation Result
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _validationResult.contains('✅') 
                      ? Colors.green[50] 
                      : _validationResult.contains('❌')
                          ? Colors.red[50]
                          : Colors.grey[50],
                  border: Border.all(
                    color: _validationResult.contains('✅') 
                        ? Colors.green[200]! 
                        : _validationResult.contains('❌')
                            ? Colors.red[200]!
                            : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _validationResult.isEmpty 
                        ? 'Validation results will appear here...'
                        : _validationResult,
                    style: TextStyle(
                      fontSize: 14,
                      color: _validationResult.contains('✅') 
                          ? Colors.green[800] 
                          : _validationResult.contains('❌')
                              ? Colors.red[800]
                              : Colors.grey[800],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _validateJson() async {
    if (_jsonController.text.trim().isEmpty) return;

    setState(() {
      _isValidating = true;
    });

    try {
      final result = JsonValidator.validateAndParseItinerary(_jsonController.text.trim());
      
      setState(() {
        if (result.isValid) {
          _validationResult = _formatSuccessResult(result.itinerary!);
        } else {
          _validationResult = _formatErrorResult(result.errors, result.regenerationRequest);
        }
      });
    } catch (e) {
      setState(() {
        _validationResult = '❌ Validation Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }

  void _loadValidExample() {
    _jsonController.text = '''
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
        },
        {
          "time": "12:00",
          "activity": "Lunch at Tsukiji Market",
          "location": "Tsukiji Outer Market"
        },
        {
          "time": "15:00",
          "activity": "Visit Senso-ji Temple",
          "location": "Asakusa, Tokyo"
        }
      ]
    },
    {
      "date": "2024-03-16",
      "summary": "Cultural experiences",
      "items": [
        {
          "time": "08:00",
          "activity": "Visit Meiji Shrine",
          "location": "Shibuya, Tokyo"
        },
        {
          "time": "14:00",
          "activity": "Explore Harajuku district",
          "location": "Harajuku, Tokyo"
        }
      ]
    }
  ]
}
''';
  }

  void _loadInvalidExample() {
    _jsonController.text = '''
{
  "title": "",
  "startDate": "invalid-date",
  "endDate": "2024-03-17",
  "days": []
}
''';
  }

  String _formatSuccessResult(Itinerary itinerary) {
    final buffer = StringBuffer();
    buffer.writeln('✅ JSON is valid!');
    buffer.writeln('');
    buffer.writeln('📋 Parsed Itinerary:');
    buffer.writeln('Title: ${itinerary.title}');
    buffer.writeln('Start Date: ${itinerary.startDate}');
    buffer.writeln('End Date: ${itinerary.endDate}');
    buffer.writeln('Number of Days: ${itinerary.days.length}');
    buffer.writeln('');
    
    for (int i = 0; i < itinerary.days.length; i++) {
      final day = itinerary.days[i];
      buffer.writeln('📅 Day ${i + 1} - ${day.date}');
      buffer.writeln('Summary: ${day.summary}');
      buffer.writeln('Items: ${day.items.length}');
      
      for (int j = 0; j < day.items.length; j++) {
        final item = day.items[j];
        buffer.writeln('  ${j + 1}. ${item.time} - ${item.activity}');
        buffer.writeln('     Location: ${item.location}');
      }
      buffer.writeln('');
    }
    
    return buffer.toString();
  }

  String _formatErrorResult(List<String> errors, String? regenerationRequest) {
    final buffer = StringBuffer();
    buffer.writeln('❌ JSON validation failed!');
    buffer.writeln('');
    buffer.writeln('🚨 Errors found:');
    for (int i = 0; i < errors.length; i++) {
      buffer.writeln('${i + 1}. ${errors[i]}');
    }
    
    if (regenerationRequest != null) {
      buffer.writeln('');
      buffer.writeln('💡 Regeneration Request:');
      buffer.writeln(regenerationRequest);
    }
    
    return buffer.toString();
  }
}

/// Example of using JsonValidator programmatically
class JsonValidatorUsageExample {
  static void demonstrateBasicValidation() {
    const validJson = '''
    {
      "title": "Paris Trip",
      "startDate": "2024-06-01",
      "endDate": "2024-06-03",
      "days": [
        {
          "date": "2024-06-01",
          "summary": "Arrival day",
          "items": [
            {
              "time": "10:00",
              "activity": "Check into hotel",
              "location": "Hotel in Paris"
            }
          ]
        }
      ]
    }
    ''';

    // Basic validation
    final result = JsonValidator.validateAndParseItinerary(validJson);
    
    if (result.isValid) {
      print('✅ Valid itinerary: ${result.itinerary!.title}');
    } else {
      print('❌ Validation errors: ${result.errors.join(', ')}');
    }
  }

  static void demonstrateQuickValidation() {
    const invalidJson = '{"title": "Test", "invalid": "json"}';
    
    // Quick validation check
    final isValid = JsonValidator.isValidItineraryJson(invalidJson);
    print('Is valid: $isValid');
    
    // Get validation errors
    final errors = JsonValidator.getValidationErrors(invalidJson);
    print('Errors: $errors');
  }

  static Future<void> demonstrateRetryLogic() async {
    const invalidJson = '''
    {
      "title": "Test Trip",
      "startDate": "invalid-date",
      "endDate": "2024-03-17",
      "days": []
    }
    ''';

    // Simulate regeneration function
    Future<String> mockRegenerate(String request) async {
      await Future.delayed(const Duration(milliseconds: 500));
      return '''
      {
        "title": "Test Trip",
        "startDate": "2024-03-15",
        "endDate": "2024-03-17",
        "days": [
          {
            "date": "2024-03-15",
            "summary": "Test day",
            "items": [
              {
                "time": "09:00",
                "activity": "Test activity",
                "location": "Test location"
              }
            ]
          }
        ]
      }
      ''';
    }

    final result = await JsonValidator.validateWithRetry(
      invalidJson,
      maxRetries: 3,
      regenerateFunction: mockRegenerate,
    );

    if (result.isValid) {
      print('✅ Successfully validated after regeneration: ${result.itinerary!.title}');
    } else {
      print('❌ Failed to validate after retries: ${result.errors.join(', ')}');
    }
  }
}

/// Example of validation error types
class ValidationErrorExample {
  static void demonstrateErrorTypes() {
    final testCases = [
      {
        'name': 'Missing required field',
        'json': '{"title": "Test", "startDate": "2024-03-15"}',
      },
      {
        'name': 'Invalid date format',
        'json': '{"title": "Test", "startDate": "15-03-2024", "endDate": "2024-03-17", "days": []}',
      },
      {
        'name': 'Invalid time format',
        'json': '''
        {
          "title": "Test",
          "startDate": "2024-03-15",
          "endDate": "2024-03-17",
          "days": [
            {
              "date": "2024-03-15",
              "summary": "Test day",
              "items": [
                {
                  "time": "9:00 AM",
                  "activity": "Test",
                  "location": "Test"
                }
              ]
            }
          ]
        }
        ''',
      },
      {
        'name': 'Empty arrays',
        'json': '{"title": "", "startDate": "2024-03-15", "endDate": "2024-03-17", "days": []}',
      },
    ];

    for (final testCase in testCases) {
      print('\n🧪 Testing: ${testCase['name']}');
      final result = JsonValidator.validateAndParseItinerary(testCase['json']!);
      
      if (result.isValid) {
        print('✅ Unexpectedly valid');
      } else {
        print('❌ Validation failed as expected');
        print('Errors: ${result.errors.take(3).join(', ')}');
      }
    }
  }
}



