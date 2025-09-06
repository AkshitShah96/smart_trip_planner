import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/agent_service_provider.dart';
import '../services/agent_service.dart';
import '../../domain/entities/chat_message.dart';
import '../../data/models/itinerary.dart';

/// Example of integrating AgentService with existing itinerary generation
class AgentServiceIntegrationExample extends ConsumerStatefulWidget {
  const AgentServiceIntegrationExample({super.key});

  @override
  ConsumerState<AgentServiceIntegrationExample> createState() => _AgentServiceIntegrationExampleState();
}

class _AgentServiceIntegrationExampleState extends ConsumerState<AgentServiceIntegrationExample> {
  final TextEditingController _inputController = TextEditingController();
  Itinerary? _currentItinerary;
  List<ChatMessage> _chatHistory = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agentService = ref.watch(agentServiceProvider);
    final isAvailable = ref.watch(isAgentServiceAvailableProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Trip Planner'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: isAvailable ? Colors.green[100] : Colors.red[100],
            child: Row(
              children: [
                Icon(
                  isAvailable ? Icons.check_circle : Icons.error,
                  color: isAvailable ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  isAvailable 
                    ? 'AI Agent Ready' 
                    : 'AI Agent Not Available - Please configure API keys',
                  style: TextStyle(
                    color: isAvailable ? Colors.green[800] : Colors.red[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Input section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Describe your trip:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _inputController,
                  decoration: InputDecoration(
                    hintText: 'e.g., "Plan a 3-day trip to Paris with museums and restaurants"',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: isAvailable && !_isLoading ? _generateItinerary : null,
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
                        : const Text('Generate Itinerary'),
                    ),
                    const SizedBox(width: 8),
                    if (_currentItinerary != null)
                      ElevatedButton(
                        onPressed: isAvailable && !_isLoading ? _refineItinerary : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Refine'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Error message
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
          
          // Itinerary display
          Expanded(
            child: _currentItinerary != null
                ? _buildItineraryDisplay()
                : const Center(
                    child: Text(
                      'Enter your trip details above to generate an itinerary',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryDisplay() {
    if (_currentItinerary == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentItinerary!.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${_currentItinerary!.startDate} to ${_currentItinerary!.endDate}',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _currentItinerary!.days.length,
              itemBuilder: (context, index) {
                final day = _currentItinerary!.days[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Day ${index + 1} - ${day.date}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          day.summary,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...day.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.time,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.activity,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      item.location,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
      final agentService = ref.read(agentServiceProvider);
      if (agentService == null) {
        throw Exception('Agent service not available');
      }

      final itinerary = await agentService.generateItinerary(
        userInput: _inputController.text.trim(),
        chatHistory: _chatHistory,
      );

      setState(() {
        _currentItinerary = itinerary;
        _chatHistory.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: _inputController.text.trim(),
          type: MessageType.user,
          timestamp: DateTime.now(),
        ));
        _inputController.clear();
      });
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refineItinerary() async {
    if (_inputController.text.trim().isEmpty || _currentItinerary == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final agentService = ref.read(agentServiceProvider);
      if (agentService == null) {
        throw Exception('Agent service not available');
      }

      final refinedItinerary = await agentService.generateItinerary(
        userInput: _inputController.text.trim(),
        previousItinerary: _currentItinerary!,
        chatHistory: _chatHistory,
        isRefinement: true,
      );

      setState(() {
        _currentItinerary = refinedItinerary;
        _chatHistory.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: _inputController.text.trim(),
          type: MessageType.user,
          timestamp: DateTime.now(),
        ));
        _inputController.clear();
      });
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('Authentication')) {
      return 'API key not configured. Please check your API settings.';
    } else if (error.toString().contains('Rate limit')) {
      return 'Rate limit exceeded. Please wait a moment and try again.';
    } else if (error.toString().contains('Network')) {
      return 'Network error. Please check your connection.';
    } else {
      return 'Error: ${error.toString()}';
    }
  }
}




