import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/agent_service.dart';
import '../../data/models/itinerary.dart';
import '../../presentation/widgets/itinerary_diff_widget.dart';
import '../models/itinerary_change.dart';

/// Example demonstrating AgentService with diff tracking
class AgentServiceDiffExample extends ConsumerStatefulWidget {
  const AgentServiceDiffExample({super.key});

  @override
  ConsumerState<AgentServiceDiffExample> createState() => _AgentServiceDiffExampleState();
}

class _AgentServiceDiffExampleState extends ConsumerState<AgentServiceDiffExample> {
  final TextEditingController _inputController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  ItineraryDiffResult? _diffResult;
  Itinerary? _currentItinerary;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Trip Planner with Diff Tracking'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          if (_diffResult != null && _diffResult!.hasChanges)
            IconButton(
              onPressed: _showChangeDetails,
              icon: const Icon(Icons.compare_arrows),
              tooltip: 'Show Change Details',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Section
            const Text(
              'Describe your trip changes:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                hintText: 'e.g., "Add a visit to Tokyo Skytree on day 2" or "Change the restaurant for dinner"',
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
                    : const Text('Generate New Itinerary'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _refineItinerary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Refine Current'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loadSampleItinerary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Load Sample'),
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
              child: _diffResult == null
                  ? const Center(
                      child: Text(
                        'Enter your trip details above to generate an itinerary with change tracking',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ItineraryDiffWidget(
                      diffResult: _diffResult!,
                      onAcceptChanges: _acceptChanges,
                      onRejectChanges: _rejectChanges,
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
      // Create AgentService with diff tracking
      final agentService = AgentServiceFactory.createWithWebSearch(
        openaiApiKey: 'your-openai-api-key', // Replace with actual key
        useDummyWebSearch: true, // Use dummy data for demo
      );

      final diffResult = await agentService.generateItineraryWithDiff(
        userInput: _inputController.text.trim(),
        previousItinerary: _currentItinerary,
      );

      setState(() {
        _diffResult = diffResult;
        _currentItinerary = diffResult.itinerary;
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

  Future<void> _refineItinerary() async {
    if (_inputController.text.trim().isEmpty || _currentItinerary == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create AgentService with diff tracking
      final agentService = AgentServiceFactory.createWithWebSearch(
        openaiApiKey: 'your-openai-api-key', // Replace with actual key
        useDummyWebSearch: true, // Use dummy data for demo
      );

      final diffResult = await agentService.generateItineraryWithDiff(
        userInput: _inputController.text.trim(),
        previousItinerary: _currentItinerary,
        isRefinement: true,
      );

      setState(() {
        _diffResult = diffResult;
        _currentItinerary = diffResult.itinerary;
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

  void _loadSampleItinerary() {
    _inputController.text = 'Plan a 3-day trip to Tokyo with temples, restaurants, and cultural experiences';
  }

  void _acceptChanges() {
    if (_diffResult != null) {
      setState(() {
        _currentItinerary = _diffResult!.itinerary;
        _diffResult = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Changes accepted!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _rejectChanges() {
    setState(() {
      _diffResult = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Changes rejected!'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showChangeDetails() {
    if (_diffResult == null || !_diffResult!.hasChanges) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Details'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ChangeDetailsWidget(diffResult: _diffResult!),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Example of using diff functionality programmatically
class DiffUsageExample {
  static Future<void> demonstrateDiffTracking() async {
    // Create AgentService
    final agentService = AgentServiceFactory.createWithWebSearch(
      openaiApiKey: 'your-openai-api-key',
      useDummyWebSearch: true,
    );

    // Generate initial itinerary
    final initialResult = await agentService.generateItineraryWithDiff(
      userInput: 'Plan a 2-day trip to Kyoto',
    );

    print('Initial itinerary: ${initialResult.itinerary.title}');
    print('Has changes: ${initialResult.hasChanges}'); // Should be false

    // Refine the itinerary
    final refinedResult = await agentService.generateItineraryWithDiff(
      userInput: 'Add a visit to Fushimi Inari Shrine on day 1',
      previousItinerary: initialResult.itinerary,
      isRefinement: true,
    );

    print('Refined itinerary: ${refinedResult.itinerary.title}');
    print('Has changes: ${refinedResult.hasChanges}'); // Should be true
    print('Changes summary: ${refinedResult.getChangesSummary()}');

    // Analyze changes
    final addedChanges = refinedResult.getChangesByType(ChangeType.added);
    final modifiedChanges = refinedResult.getChangesByType(ChangeType.modified);
    final removedChanges = refinedResult.getChangesByType(ChangeType.removed);

    print('Added items: ${addedChanges.length}');
    print('Modified items: ${modifiedChanges.length}');
    print('Removed items: ${removedChanges.length}');

    // Check specific day changes
    for (int i = 0; i < refinedResult.itinerary.days.length; i++) {
      if (refinedResult.hasChangesInDay(i)) {
        print('Day ${i + 1} has changes');
        final dayChanges = refinedResult.getChangesForDay(i);
        for (final change in dayChanges) {
          print('  - ${change.description}');
        }
      }
    }
  }

  static void demonstrateChangeAnalysis(ItineraryDiffResult diffResult) {
    if (!diffResult.hasChanges) {
      print('No changes detected');
      return;
    }

    print('=== Change Analysis ===');
    print('Total changes: ${diffResult.diff!.changes.length}');
    print('Summary: ${diffResult.getChangesSummary()}');

    // Group changes by type
    final changesByType = <ChangeType, List<ItineraryChange>>{};
    for (final change in diffResult.diff!.changes) {
      changesByType.putIfAbsent(change.type, () => []).add(change);
    }

    for (final entry in changesByType.entries) {
      print('\n${entry.key.name.toUpperCase()} Changes (${entry.value.length}):');
      for (final change in entry.value) {
        print('  - ${change.description}');
        print('    Path: ${change.path}');
        if (change.oldValue != null) print('    Old: ${change.oldValue}');
        if (change.newValue != null) print('    New: ${change.newValue}');
      }
    }

    // Group changes by granularity
    final changesByGranularity = <ChangeGranularity, List<ItineraryChange>>{};
    for (final change in diffResult.diff!.changes) {
      changesByGranularity.putIfAbsent(change.granularity, () => []).add(change);
    }

    print('\n=== Changes by Granularity ===');
    for (final entry in changesByGranularity.entries) {
      print('${entry.key.name}: ${entry.value.length} changes');
    }
  }

  static void demonstrateDayAnalysis(ItineraryDiffResult diffResult) {
    print('\n=== Day-by-Day Analysis ===');
    
    for (int i = 0; i < diffResult.itinerary.days.length; i++) {
      final day = diffResult.itinerary.days[i];
      final hasChanges = diffResult.hasChangesInDay(i);
      
      print('Day ${i + 1} (${day.date}): ${hasChanges ? "HAS CHANGES" : "No changes"}');
      
      if (hasChanges) {
        final dayChanges = diffResult.getChangesForDay(i);
        for (final change in dayChanges) {
          print('  - ${change.description}');
        }
        
        // Check items in this day
        for (int j = 0; j < day.items.length; j++) {
          final item = day.items[j];
          final hasItemChanges = diffResult.hasChangesInItem(i, j);
          
          if (hasItemChanges) {
            print('    Item ${j + 1} (${item.time}): ${item.activity} - HAS CHANGES');
            final itemChanges = diffResult.getChangesForItem(i, j);
            for (final change in itemChanges) {
              print('      - ${change.description}');
            }
          }
        }
      }
    }
  }
}

/// Example of change filtering and querying
class ChangeFilteringExample {
  static void demonstrateChangeFiltering(ItineraryDiffResult diffResult) {
    if (!diffResult.hasChanges) return;

    print('=== Change Filtering Examples ===');

    // Filter by change type
    final addedChanges = diffResult.getChangesByType(ChangeType.added);
    print('Added changes: ${addedChanges.length}');

    final modifiedChanges = diffResult.getChangesByType(ChangeType.modified);
    print('Modified changes: ${modifiedChanges.length}');

    // Filter by granularity
    final itemChanges = diffResult.getChangesByGranularity(ChangeGranularity.item);
    print('Item-level changes: ${itemChanges.length}');

    final fieldChanges = diffResult.getChangesByGranularity(ChangeGranularity.field);
    print('Field-level changes: ${fieldChanges.length}');

    // Filter by specific criteria
    final timeChanges = diffResult.diff!.changes
        .where((change) => change.path.contains('.time'))
        .toList();
    print('Time changes: ${timeChanges.length}');

    final locationChanges = diffResult.diff!.changes
        .where((change) => change.path.contains('.location'))
        .toList();
    print('Location changes: ${locationChanges.length}');

    // Filter by day
    for (int i = 0; i < diffResult.itinerary.days.length; i++) {
      final dayChanges = diffResult.getChangesForDay(i);
      if (dayChanges.isNotEmpty) {
        print('Day ${i + 1} changes: ${dayChanges.length}');
      }
    }
  }
}



