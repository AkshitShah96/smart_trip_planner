import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/agent_service.dart';
import '../services/web_search_service.dart';
import '../../domain/entities/chat_message.dart';

/// Example demonstrating AgentService with web search capabilities
class AgentServiceWebSearchExample extends ConsumerStatefulWidget {
  const AgentServiceWebSearchExample({super.key});

  @override
  ConsumerState<AgentServiceWebSearchExample> createState() => _AgentServiceWebSearchExampleState();
}

class _AgentServiceWebSearchExampleState extends ConsumerState<AgentServiceWebSearchExample> {
  final TextEditingController _inputController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String _lastGeneratedItinerary = '';

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Trip Planner with Web Search'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Web Search Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.green[600]),
                  const SizedBox(width: 8),
                  const Text(
                    'Web Search Enabled - Real-time information will be included',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Input Section
            const Text(
              'Describe your trip (include location and preferences):',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                hintText: 'e.g., "Plan a 3-day trip to Kyoto with temples, restaurants, and traditional experiences"',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _generateItinerary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Generate with Web Search'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testWebSearchOnly,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Test Web Search Only'),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Error Message
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[800]),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _errorMessage = null),
                      icon: const Icon(Icons.close),
                      color: Colors.red[600],
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Results Section
            Expanded(
              child: _lastGeneratedItinerary.isEmpty
                  ? const Center(
                      child: Text(
                        'Enter your trip details above to generate an itinerary with real-time information',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          _lastGeneratedItinerary,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateItinerary() async {
    if (_inputController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create AgentService with web search enabled
      final agentService = AgentServiceFactory.createWithWebSearch(
        openaiApiKey: 'your-openai-api-key', // Replace with actual key
        useDummyWebSearch: true, // Use dummy data for demo
      );

      final itinerary = await agentService.generateItinerary(
        userInput: _inputController.text.trim(),
      );

      setState(() {
        _lastGeneratedItinerary = _formatItineraryWithWebData(itinerary);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testWebSearchOnly() async {
    if (_inputController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Test web search service directly
      final webSearchService = WebSearchServiceFactory.createWithDummyData();
      
      final results = await webSearchService.performWebSearch(_inputController.text.trim());
      
      setState(() {
        _lastGeneratedItinerary = 'Web Search Results:\n\n${_formatWebSearchResults(results)}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatItineraryWithWebData(dynamic itinerary) {
    final buffer = StringBuffer();
    
    buffer.writeln('🎯 ${itinerary.title}');
    buffer.writeln('📅 ${itinerary.startDate} to ${itinerary.endDate}');
    buffer.writeln('');
    
    for (int i = 0; i < itinerary.days.length; i++) {
      final day = itinerary.days[i];
      buffer.writeln('📅 Day ${i + 1} - ${day.date}');
      buffer.writeln('📝 ${day.summary}');
      buffer.writeln('');
      
      for (final item in day.items) {
        buffer.writeln('⏰ ${item.time}: ${item.activity}');
        buffer.writeln('📍 ${item.location}');
        
        // Show web search data if available
        if (item.additionalInfo != null) {
          final webData = item.additionalInfo!['webSearchData'];
          if (webData != null) {
            buffer.writeln('🔍 Real-time Info:');
            if (webData['rating'] != null) {
              buffer.writeln('   ⭐ Rating: ${webData['rating']}/5');
            }
            if (webData['phone'] != null) {
              buffer.writeln('   📞 Phone: ${webData['phone']}');
            }
            if (webData['priceRange'] != null) {
              buffer.writeln('   💰 Price: ${webData['priceRange']}');
            }
            if (webData['address'] != null) {
              buffer.writeln('   🏠 Address: ${webData['address']}');
            }
          }
        }
        buffer.writeln('');
      }
      buffer.writeln('─' * 50);
      buffer.writeln('');
    }
    
    return buffer.toString();
  }

  String _formatWebSearchResults(List<dynamic> results) {
    final buffer = StringBuffer();
    
    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      buffer.writeln('${i + 1}. ${result.title}');
      buffer.writeln('   ${result.description}');
      buffer.writeln('   🌐 ${result.url}');
      
      if (result.rating != null) {
        buffer.writeln('   ⭐ Rating: ${result.rating}/5');
      }
      if (result.address != null) {
        buffer.writeln('   📍 Address: ${result.address}');
      }
      if (result.phone != null) {
        buffer.writeln('   📞 Phone: ${result.phone}');
      }
      if (result.priceRange != null) {
        buffer.writeln('   💰 Price: ${result.priceRange}');
      }
      buffer.writeln('');
    }
    
    return buffer.toString();
  }
}

/// Example of using web search in a Riverpod provider
final webSearchEnabledAgentProvider = Provider<AgentService?>((ref) {
  try {
    return AgentServiceFactory.createWithWebSearch(
      openaiApiKey: 'your-openai-api-key', // Replace with actual key
      useDummyWebSearch: true, // Use dummy data for demo
    );
  } catch (e) {
    return null;
  }
});

/// Example of web search specific queries
class WebSearchQueryExamples {
  static const List<String> restaurantQueries = [
    'best restaurants in Tokyo',
    'traditional Japanese restaurants in Kyoto',
    'Michelin star restaurants in Osaka',
    'street food in Bangkok',
    'fine dining in Paris',
  ];

  static const List<String> hotelQueries = [
    'best hotels in Tokyo near Shibuya',
    'luxury hotels in Kyoto with traditional gardens',
    'budget hotels in Osaka near train station',
    'boutique hotels in Paris near Eiffel Tower',
    'resort hotels in Bali with beach access',
  ];

  static const List<String> attractionQueries = [
    'top attractions in Kyoto',
    'temples and shrines in Tokyo',
    'museums in Paris',
    'historical sites in Rome',
    'nature spots in New Zealand',
  ];

  static const List<String> transportationQueries = [
    'transportation in Tokyo',
    'how to get around Kyoto',
    'public transport in Paris',
    'train travel in Japan',
    'airport transfers in London',
  ];

  static const List<String> eventQueries = [
    'events in Tokyo this month',
    'festivals in Kyoto in spring',
    'concerts in London this weekend',
    'cultural events in Paris',
    'sports events in New York',
  ];
}

/// Example of web search integration in itinerary generation
class WebSearchIntegrationExample {
  static Future<Map<String, dynamic>> enhanceItineraryWithWebSearch(
    String userInput,
    AgentService agentService,
  ) async {
    try {
      // Generate itinerary with web search
      final itinerary = await agentService.generateItinerary(
        userInput: userInput,
      );

      // Extract web search data from itinerary items
      final webSearchData = <String, dynamic>{};
      
      for (final day in itinerary.days) {
        for (final item in day.items) {
          if (item.additionalInfo != null && 
              item.additionalInfo!['webSearchData'] != null) {
            webSearchData[item.activity] = item.additionalInfo!['webSearchData'];
          }
        }
      }

      return {
        'itinerary': itinerary.toJson(),
        'webSearchData': webSearchData,
        'hasRealTimeData': webSearchData.isNotEmpty,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'hasRealTimeData': false,
      };
    }
  }
}