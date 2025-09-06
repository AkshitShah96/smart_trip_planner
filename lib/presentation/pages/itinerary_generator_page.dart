import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/itinerary_providers.dart';
import '../providers/saved_itineraries_providers.dart';
import '../../data/services/itinerary_service_example.dart';
import '../../domain/entities/itinerary.dart' as domain;
import '../../domain/entities/day_plan.dart' as domain;
import '../../domain/entities/day_item.dart' as domain;
import '../../data/models/itinerary.dart' as data_model;

class ItineraryGeneratorPage extends ConsumerStatefulWidget {
  const ItineraryGeneratorPage({super.key});

  @override
  ConsumerState<ItineraryGeneratorPage> createState() => _ItineraryGeneratorPageState();
}

class _ItineraryGeneratorPageState extends ConsumerState<ItineraryGeneratorPage> {
  final TextEditingController _promptController = TextEditingController();
  bool _isTextEmpty = true;

  @override
  void initState() {
    super.initState();
    _promptController.text = "7 days in Bali next April, 3 people, mid-range budget, wanted to explore less populated areas, it should be a peaceful trip!";
    _promptController.addListener(() {
      setState(() {
        _isTextEmpty = _promptController.text.trim().isEmpty;
      });
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConfigured = ref.watch(isOpenAIConfiguredProvider);
    final generationState = ref.watch(itineraryGenerationProvider);
    final savedItineraries = ref.watch(savedItinerariesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Header with avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    radius: 20,
                    child: Text(
                      'S',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Main prompt
              Center(
                child: Text(
                  "What's your vision for this trip?",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Large input field
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green.shade200, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _promptController,
                  maxLines: 4,
                  enabled: isConfigured && !generationState.isLoading,
                  style: TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Describe your dream trip...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    suffixIcon: Icon(
                      Icons.mic,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Create My Itinerary button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: !generationState.isLoading && !_isTextEmpty
                      ? () => _generateItinerary()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: generationState.isLoading
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('Creating...', style: TextStyle(fontSize: 16)),
                          ],
                        )
                      : Text(
                          'Create My Itinerary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Demo mode banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Demo Mode: Using sample data for itinerary generation',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Error handling
              if (generationState.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        generationState.error!.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _generateItinerary(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Generated itinerary display
              if (generationState.itinerary != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _saveItinerary(ref, generationState.itinerary!),
                        icon: const Icon(Icons.save),
                        label: const Text('Save Itinerary'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _generateItinerary(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Generate New'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            generationState.itinerary!.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${generationState.itinerary!.startDate} to ${generationState.itinerary!.endDate}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ListView.builder(
                              itemCount: generationState.itinerary!.days.length,
                              itemBuilder: (context, index) {
                                final day = generationState.itinerary!.days.elementAt(index);
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text('Day ${index + 1} - ${day.date}'),
                                    subtitle: Text(day.summary),
                                    trailing: Text('${day.items.length} activities'),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 20),
                
                // Offline Saved Itineraries section
                Text(
                  'Offline Saved Itineraries',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Saved itineraries list
                Expanded(
                  child: savedItineraries.isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                          ),
                        )
                      : savedItineraries.error != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 64,
                                    color: Colors.red.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error loading itineraries',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.red.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    savedItineraries.error!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.red.shade500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : savedItineraries.itineraries.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.travel_explore,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No saved itineraries yet',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Create your first itinerary above!',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: savedItineraries.itineraries.length,
                                  itemBuilder: (context, index) {
                                    final itinerary = savedItineraries.itineraries[index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  itinerary.title,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${itinerary.startDate} to ${itinerary.endDate}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${itinerary.days.length} days planned',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Colors.grey.shade400,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                ),
              ],
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _generateItinerary() {
    final prompt = _promptController.text.trim();
    if (prompt.isNotEmpty) {
      ref.read(itineraryGenerationProvider.notifier).generateItinerary(prompt);
    }
  }

  void _saveItinerary(WidgetRef ref, data_model.Itinerary dataItinerary) {
    final domainItinerary = domain.Itinerary(
      title: dataItinerary.title,
      startDate: dataItinerary.startDate,
      endDate: dataItinerary.endDate,
      days: dataItinerary.days.map((dataDay) {
        return domain.DayPlan(
          date: dataDay.date,
          summary: dataDay.summary,
          items: dataDay.items.map((dataItem) {
            return domain.DayItem(
              time: dataItem.time,
              activity: dataItem.activity,
              location: dataItem.location,
            );
          }).toList(),
        );
      }).toList(),
    );

    ref.read(savedItinerariesProvider.notifier).saveItinerary(domainItinerary);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Itinerary "${domainItinerary.title}" saved successfully!'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
          },
        ),
      ),
    );
  }
}
