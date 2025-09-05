import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/itinerary_providers.dart';
import '../../core/errors/itinerary_errors.dart';

/// Example usage of the OpenAI Itinerary Service
class ItineraryServiceExample {
  
  /// Example of how to use the service in a widget
  static void exampleUsage(WidgetRef ref) async {
    // Check if OpenAI is configured
    final isConfigured = ref.read(isOpenAIConfiguredProvider);
    if (!isConfigured) {
      print('OpenAI API key not configured');
      return;
    }

    // Generate itinerary
    final notifier = ref.read(itineraryGenerationProvider.notifier);
    await notifier.generateItinerary(
      'Plan a 3-day trip to Kyoto, Japan. Include Fushimi Inari Shrine, '
      'Gion district, Arashiyama Bamboo Grove, and traditional experiences.'
    );

    // Listen to state changes
    ref.listen(itineraryGenerationProvider, (previous, next) {
      if (next.isLoading) {
        print('Generating itinerary...');
      } else if (next.error != null) {
        print('Error: ${next.error}');
      } else if (next.itinerary != null) {
        print('Itinerary generated: ${next.itinerary!.title}');
        print('Days: ${next.itinerary!.days.length}');
      }
    });
  }

  /// Example of error handling
  static void handleErrors(ItineraryError error) {
    switch (error.runtimeType) {
      case NetworkError:
        print('Network issue: ${error.message}');
        // Show retry option
        break;
      case AuthenticationError:
        print('API key issue: ${error.message}');
        // Show configuration help
        break;
      case RateLimitError:
        print('Rate limit: ${error.message}');
        // Show wait message
        break;
      case InvalidJsonError:
        print('Invalid response: ${error.message}');
        // Show error and retry option
        break;
      case InvalidItineraryError:
        print('Invalid itinerary: ${error.message}');
        // Show error and retry option
        break;
      case ServerError:
        final serverError = error as ServerError;
        print('Server error ${serverError.statusCode}: ${error.message}');
        // Show error and retry option
        break;
      default:
        print('Unknown error: ${error.message}');
        // Show generic error message
        break;
    }
  }

  /// Example prompts for different scenarios
  static const List<String> examplePrompts = [
    'Plan a 5-day solo trip to Tokyo, Japan. Include modern attractions, traditional experiences, and local food.',
    'Create a 7-day family itinerary for Paris, France. Include kid-friendly activities and must-see landmarks.',
    'Design a 4-day romantic getaway to Santorini, Greece. Focus on sunset views, wine tasting, and relaxation.',
    'Plan a 6-day adventure trip to New Zealand. Include hiking, bungee jumping, and natural attractions.',
    'Create a 3-day cultural trip to Rome, Italy. Focus on historical sites, art museums, and Italian cuisine.',
  ];
}




