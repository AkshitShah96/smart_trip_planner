# AgentService Documentation

## Overview

The `AgentService` class is the core AI agent for the Smart Trip Planner app. It handles communication with OpenAI and Gemini APIs to generate and refine travel itineraries based on user input.

## Features

- **Dual API Support**: Works with both OpenAI GPT-4 and Google Gemini Pro
- **Function Calling**: Uses OpenAI's function calling for structured responses
- **JSON Schema Validation**: Ensures responses match the required itinerary format
- **Refinement Support**: Can modify existing itineraries based on user feedback
- **Chat History Integration**: Considers previous conversation context
- **Web Search Integration**: Real-time information retrieval for enhanced itineraries
- **Error Handling**: Comprehensive error handling for API failures
- **Input Validation**: Validates user input and API responses

## Usage

### Basic Setup

```dart
import 'package:smart_trip_planner/core/services/agent_service.dart';

// Create OpenAI service
final agentService = AgentServiceFactory.createOpenAIService(
  apiKey: 'your-openai-api-key',
);

// Create Gemini service
final agentService = AgentServiceFactory.createGeminiService(
  apiKey: 'your-gemini-api-key',
);

// Create from configuration
final agentService = AgentServiceFactory.createFromConfig(
  openaiApiKey: 'your-openai-key',
  geminiApiKey: 'your-gemini-key',
  preferOpenAI: true,
);
```

### Generate New Itinerary

```dart
final itinerary = await agentService.generateItinerary(
  userInput: 'Plan a 3-day trip to Tokyo with temples and restaurants',
);
```

### Refine Existing Itinerary

```dart
final refinedItinerary = await agentService.generateItinerary(
  userInput: 'Add more activities to the first day',
  previousItinerary: existingItinerary,
  isRefinement: true,
);
```

### With Chat History

```dart
final itinerary = await agentService.generateItinerary(
  userInput: 'Create a detailed itinerary',
  chatHistory: previousMessages,
);
```

### With Web Search (Real-time Information)

```dart
// Create AgentService with web search enabled
final agentService = AgentServiceFactory.createWithWebSearch(
  openaiApiKey: 'your-openai-api-key',
  useDummyWebSearch: true, // Use dummy data for demo
);

final itinerary = await agentService.generateItinerary(
  userInput: 'Plan a 3-day trip to Tokyo with restaurants and temples',
);
// The itinerary will include real-time information from web search
```

## API Integration

### OpenAI Integration

The service uses OpenAI's GPT-4 model with function calling to ensure structured JSON responses. The function schema defines the exact format for itinerary data.

**Function Schema:**
```json
{
  "name": "generate_itinerary",
  "parameters": {
    "type": "object",
    "properties": {
      "title": {"type": "string"},
      "startDate": {"type": "string"},
      "endDate": {"type": "string"},
      "days": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "date": {"type": "string"},
            "summary": {"type": "string"},
            "items": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "time": {"type": "string"},
                  "activity": {"type": "string"},
                  "location": {"type": "string"}
                }
              }
            }
          }
        }
      }
    }
  }
}
```

### Gemini Integration

The service uses Google's Gemini Pro model with JSON extraction from natural language responses.

## Error Handling

The service handles various error scenarios:

- **401 Unauthorized**: Invalid API key
- **429 Rate Limit**: Too many requests
- **500 Server Error**: API server issues
- **Network Errors**: Connection timeouts and failures
- **JSON Validation**: Invalid response format
- **Schema Validation**: Missing required fields

## Response Format

All responses follow the Spec A format:

```json
{
  "title": "Trip Title",
  "startDate": "YYYY-MM-DD",
  "endDate": "YYYY-MM-DD",
  "days": [
    {
      "date": "YYYY-MM-DD",
      "summary": "Day summary",
      "items": [
        {
          "time": "HH:MM",
          "activity": "Activity description",
          "location": "Location coordinates or address"
        }
      ]
    }
  ]
}
```

## Validation

The service performs comprehensive validation:

1. **Input Validation**: Checks user input length and content
2. **JSON Schema Validation**: Ensures all required fields are present
3. **Data Validation**: Validates date formats and logical consistency
4. **Response Validation**: Verifies the structure matches the expected format

## Configuration

### Environment Variables

Set API keys using environment variables:

```bash
# For OpenAI
export OPENAI_API_KEY="your-openai-api-key"

# For Gemini
export GEMINI_API_KEY="your-gemini-api-key"
```

### Flutter Run Configuration

```bash
# Run with OpenAI API key
flutter run --dart-define=OPENAI_API_KEY=your-key

# Run with Gemini API key
flutter run --dart-define=GEMINI_API_KEY=your-key

# Run with both
flutter run --dart-define=OPENAI_API_KEY=your-key --dart-define=GEMINI_API_KEY=your-key
```

## Testing

The service includes comprehensive unit tests covering:

- Input validation
- API integration (mocked)
- Error handling
- JSON schema validation
- Refinement functionality

Run tests with:
```bash
flutter test test/core/services/agent_service_test.dart
```

## Performance Considerations

- **Timeout Settings**: 30s connection, 60s receive timeout
- **Rate Limiting**: Built-in handling for API rate limits
- **Caching**: Consider implementing response caching for repeated requests
- **Batch Processing**: For multiple requests, consider batching

## Security

- **API Key Protection**: Never commit API keys to version control
- **Input Sanitization**: All user input is validated and sanitized
- **Error Information**: Sensitive information is not exposed in error messages

## Troubleshooting

### Common Issues

1. **"Agent Service not configured"**
   - Check API key configuration
   - Verify environment variables

2. **"Authentication failed"**
   - Verify API key is correct
   - Check API key permissions

3. **"Rate limit exceeded"**
   - Wait before retrying
   - Consider implementing exponential backoff

4. **"Invalid JSON response"**
   - Check API service status
   - Verify prompt format

### Debug Mode

Enable verbose logging:
```dart
final agentService = AgentService(
  openaiApiKey: 'your-key',
  useOpenAI: true,
  dio: Dio()..interceptors.add(LogInterceptor()),
);
```

## Future Enhancements

- **Streaming Responses**: Support for real-time response streaming
- **Caching Layer**: Implement response caching
- **Fallback Services**: Automatic fallback between OpenAI and Gemini
- **Custom Models**: Support for fine-tuned models
- **Analytics**: Usage tracking and performance metrics
