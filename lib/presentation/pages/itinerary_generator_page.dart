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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Itinerary Generator'),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            const SizedBox(height: 16),
            
            Text(
              'Describe your ideal trip:',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            TextField(
              controller: _promptController,
              maxLines: 4,
              enabled: isConfigured && !generationState.isLoading,
              decoration: InputDecoration(
                hintText: 'e.g., Plan a 5-day trip to Kyoto, Japan...',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: !generationState.isLoading && !_isTextEmpty
                  ? () => _generateItinerary()
                  : null,
              child: generationState.isLoading
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Generating...'),
                      ],
                    )
                  : const Text('Generate Itinerary'),
            ),
            
            const SizedBox(height: 16),
            
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
            ],
            
            if (isConfigured && generationState.itinerary == null && generationState.error == null) ...[
              const SizedBox(height: 16),
              Text(
                'Example prompts:',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...ItineraryServiceExample.examplePrompts.map((prompt) => 
                Card(
                  child: ListTile(
                    title: Text(prompt),
                    onTap: () {
                      _promptController.text = prompt;
                    },
                  ),
                ),
              ),
            ],
          ],
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
