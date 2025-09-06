# Web Search Service Documentation

## Overview

The `WebSearchService` provides real-time information retrieval capabilities for the Smart Trip Planner app. It integrates with various search APIs to fetch current data about restaurants, hotels, attractions, transportation, and events to enhance itinerary generation.

## Features

- **Multiple API Support**: SerpAPI and Google Custom Search API
- **Dummy Data Fallback**: Comprehensive dummy data for testing and offline scenarios
- **Specialized Search Methods**: Dedicated methods for different types of travel information
- **Structured Results**: Consistent JSON format for all search results
- **Error Handling**: Graceful fallback to dummy data on API failures
- **Rate Limiting**: Built-in handling for API rate limits

## Supported Search Types

### 1. Restaurants
```dart
final results = await webSearchService.searchRestaurants('Tokyo');
// Returns: List of restaurants with ratings, prices, addresses, phone numbers
```

### 2. Hotels
```dart
final results = await webSearchService.searchHotels('Kyoto', near: 'Fushimi Inari');
// Returns: List of hotels with ratings, addresses, amenities
```

### 3. Attractions
```dart
final results = await webSearchService.searchAttractions('Osaka');
// Returns: List of attractions with ratings, descriptions, entry fees
```

### 4. Transportation
```dart
final results = await webSearchService.searchTransportation('Tokyo', 'Kyoto');
// Returns: List of transportation options with details
```

### 5. Events
```dart
final results = await webSearchService.searchEvents('Tokyo', date: '2024-03-15');
// Returns: List of events with dates, descriptions, venues
```

## API Configuration

### SerpAPI (Recommended)
```bash
export SERP_API_KEY="your-serp-api-key"
```

### Google Custom Search API
```bash
export GOOGLE_SEARCH_API_KEY="your-google-api-key"
export GOOGLE_SEARCH_ENGINE_ID="your-search-engine-id"
```

### Flutter Run Configuration
```bash
# With SerpAPI
flutter run --dart-define=SERP_API_KEY=your-key

# With Google Custom Search
flutter run --dart-define=GOOGLE_SEARCH_API_KEY=your-key --dart-define=GOOGLE_SEARCH_ENGINE_ID=your-id
```

## Usage Examples

### Basic Usage
```dart
import 'package:smart_trip_planner/core/services/web_search_service.dart';

// Create service with API keys
final webSearchService = WebSearchServiceFactory.createWithApiKeys();

// Perform search
final results = await webSearchService.performWebSearch('best restaurants in Tokyo');
```

### With Dummy Data
```dart
// Create service with dummy data (for testing)
final webSearchService = WebSearchServiceFactory.createWithDummyData();

final results = await webSearchService.performWebSearch('restaurants in Kyoto');
// Returns realistic dummy data
```

### Specialized Searches
```dart
// Search for restaurants
final restaurants = await webSearchService.searchRestaurants('Paris');

// Search for hotels near a specific location
final hotels = await webSearchService.searchHotels('London', near: 'Big Ben');

// Search for attractions
final attractions = await webSearchService.searchAttractions('Rome');

// Search for transportation
final transport = await webSearchService.searchTransportation('New York', 'Boston');

// Search for events
final events = await webSearchService.searchEvents('Tokyo', date: '2024-04-01');
```

## WebSearchResult Model

Each search result contains:

```dart
class WebSearchResult {
  final String title;           // Name of the place/event
  final String description;     // Brief description
  final String url;            // Website URL
  final String? imageUrl;      // Image URL
  final double? rating;        // Rating (1-5)
  final String? address;       // Physical address
  final String? phone;         // Phone number
  final String? priceRange;    // Price range (e.g., "$$$")
  final Map<String, dynamic>? additionalData; // Extra information
}
```

### Example Result
```dart
WebSearchResult(
  title: 'Sukiyabashi Jiro',
  description: 'World-famous sushi restaurant with Michelin stars',
  url: 'https://example.com/sukiyabashi-jiro',
  rating: 4.8,
  address: 'Tsukamoto Sogyo Building, 2-15-12 Ginza, Chuo City, Tokyo',
  phone: '+81-3-3535-3600',
  priceRange: '¥¥¥¥',
  additionalData: {
    'cuisine': 'Sushi',
    'reservation_required': true,
  },
)
```

## Integration with AgentService

The WebSearchService is automatically integrated with AgentService:

```dart
// Create AgentService with web search enabled
final agentService = AgentServiceFactory.createWithWebSearch(
  openaiApiKey: 'your-key',
  useDummyWebSearch: true, // Use dummy data for demo
);

// Generate itinerary with real-time information
final itinerary = await agentService.generateItinerary(
  userInput: 'Plan a 3-day trip to Tokyo with restaurants and temples',
);
```

## Dummy Data

When API keys are not available or APIs fail, the service provides comprehensive dummy data:

### Restaurants
- Sukiyabashi Jiro (Tokyo) - Sushi, 4.8★, ¥¥¥¥
- Narisawa (Tokyo) - Japanese Fusion, 4.6★, ¥¥¥¥
- Tsukiji Outer Market (Tokyo) - Seafood, 4.4★, ¥¥

### Hotels
- The Ritz-Carlton Tokyo - 5★, Luxury
- Hotel Okura Tokyo - 5★, Traditional
- Shibuya Sky Hotel - 4★, Modern

### Attractions
- Fushimi Inari Shrine (Kyoto) - 4.6★, Free entry
- Kiyomizu-dera Temple (Kyoto) - 4.5★, ¥400 entry
- Arashiyama Bamboo Grove (Kyoto) - 4.4★, Free entry

### Transportation
- JR Pass - Rail pass for unlimited travel
- Tokyo Metro - Subway system
- Shinkansen - High-speed rail

### Events
- Cherry Blossom Festival - Spring, Free
- Gion Matsuri - Summer, Traditional
- Tokyo International Film Festival - Autumn, Ticketed

## Error Handling

The service handles various error scenarios:

- **API Failures**: Falls back to dummy data
- **Network Errors**: Returns empty results or dummy data
- **Rate Limiting**: Built-in handling with retry logic
- **Invalid Responses**: Skips invalid results, continues processing

## Performance Considerations

- **Timeout Settings**: 15s connection, 30s receive timeout
- **Result Limiting**: Maximum 10 results per query
- **Caching**: Consider implementing response caching
- **Batch Processing**: For multiple queries, consider batching

## Testing

The service includes comprehensive unit tests:

```bash
flutter test test/core/services/web_search_service_test.dart
```

Test coverage includes:
- Dummy data generation
- Specialized search methods
- JSON serialization/deserialization
- Error handling
- Factory methods

## Security

- **API Key Protection**: Never commit API keys to version control
- **Input Sanitization**: All search queries are validated
- **Error Information**: Sensitive information is not exposed in error messages

## Troubleshooting

### Common Issues

1. **"No API key configured"**
   - Check environment variables
   - Verify API key format

2. **"Rate limit exceeded"**
   - Wait before retrying
   - Consider implementing exponential backoff

3. **"No results returned"**
   - Check query format
   - Verify API service status
   - Check if dummy data is being used

### Debug Mode

Enable verbose logging:
```dart
final webSearchService = WebSearchService(
  dio: Dio()..interceptors.add(LogInterceptor()),
);
```

## Future Enhancements

- **More API Providers**: Add support for additional search APIs
- **Caching Layer**: Implement response caching for better performance
- **Image Search**: Add image search capabilities
- **Reviews Integration**: Include user reviews and ratings
- **Real-time Updates**: WebSocket support for live updates
- **Geolocation**: Location-based search with coordinates
- **Language Support**: Multi-language search capabilities

## API Limits

### SerpAPI
- Free tier: 100 searches/month
- Paid plans: Up to 10,000 searches/month

### Google Custom Search API
- Free tier: 100 searches/day
- Paid plans: Up to 10,000 searches/day

### Recommendations
- Use SerpAPI for production (more reliable)
- Use Google Custom Search for development
- Implement caching to reduce API calls
- Monitor usage and implement rate limiting




