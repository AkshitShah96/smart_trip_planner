import '../../domain/entities/itinerary.dart';
import '../../domain/entities/day_plan.dart';
import '../../domain/entities/day_item.dart';

class DemoItinerary {
  static Itinerary get kyotoItinerary => Itinerary(
    title: 'Kyoto 5-Day Solo Trip',
    startDate: '2025-04-10',
    endDate: '2025-04-15',
    days: [
      DayPlan(
        date: '2025-04-10',
        summary: 'Arrival and exploration',
        items: [
          DayItem(
            time: '09:00',
            activity: 'Climb Fushimi Inari Shrine',
            location: '34.9671,135.7727', // Coordinates for maps
          ),
          DayItem(
            time: '14:00',
            activity: 'Lunch at Nishiki Market',
            location: '35.0047,135.7630', // Coordinates for maps
          ),
          DayItem(
            time: '18:30',
            activity: 'Evening walk in Gion',
            location: '35.0037,135.7788', // Coordinates for maps
          ),
        ],
      ),
      DayPlan(
        date: '2025-04-11',
        summary: 'Temples and gardens',
        items: [
          DayItem(
            time: '08:00',
            activity: 'Visit Kinkaku-ji Temple',
            location: '35.0394,135.7299', // Coordinates for maps
          ),
          DayItem(
            time: '12:00',
            activity: 'Explore Arashiyama Bamboo Grove',
            location: '35.0172,135.6779', // Coordinates for maps
          ),
          DayItem(
            time: '16:00',
            activity: 'Tea ceremony experience',
            location: '35.0116,135.7681', // Coordinates for maps
          ),
        ],
      ),
      DayPlan(
        date: '2025-04-12',
        summary: 'Cultural experiences',
        items: [
          DayItem(
            time: '09:00',
            activity: 'Visit Nijo Castle',
            location: '35.0142,135.7481', // Coordinates for maps
          ),
          DayItem(
            time: '13:00',
            activity: 'Traditional kaiseki lunch',
            location: '35.0047,135.7630', // Coordinates for maps
          ),
          DayItem(
            time: '15:00',
            activity: 'Explore Philosopher\'s Path',
            location: '35.0269,135.7944', // Coordinates for maps
          ),
        ],
      ),
    ],
  );

  static Itinerary get tokyoItinerary => Itinerary(
    title: 'Tokyo 3-Day Adventure',
    startDate: '2025-05-01',
    endDate: '2025-05-04',
    days: [
      DayPlan(
        date: '2025-05-01',
        summary: 'Modern Tokyo exploration',
        items: [
          DayItem(
            time: '10:00',
            activity: 'Visit Tokyo Skytree',
            location: '35.7101,139.8107', // Coordinates for maps
          ),
          DayItem(
            time: '14:00',
            activity: 'Explore Asakusa Temple',
            location: '35.7148,139.7967', // Coordinates for maps
          ),
          DayItem(
            time: '18:00',
            activity: 'Dinner in Shibuya',
            location: '35.6598,139.7006', // Coordinates for maps
          ),
        ],
      ),
      DayPlan(
        date: '2025-05-02',
        summary: 'Traditional and modern mix',
        items: [
          DayItem(
            time: '09:00',
            activity: 'Visit Meiji Shrine',
            location: '35.6762,139.6993', // Coordinates for maps
          ),
          DayItem(
            time: '12:00',
            activity: 'Harajuku shopping',
            location: '35.6702,139.7026', // Coordinates for maps
          ),
          DayItem(
            time: '16:00',
            activity: 'Shibuya Crossing experience',
            location: '35.6598,139.7006', // Coordinates for maps
          ),
        ],
      ),
    ],
  );

  static Itinerary get parisItinerary => Itinerary(
    title: 'Paris 4-Day Romantic Getaway',
    startDate: '2025-06-15',
    endDate: '2025-06-19',
    days: [
      DayPlan(
        date: '2025-06-15',
        summary: 'Iconic landmarks',
        items: [
          DayItem(
            time: '09:00',
            activity: 'Visit Eiffel Tower',
            location: '48.8584,2.2945', // Coordinates for maps
          ),
          DayItem(
            time: '14:00',
            activity: 'Louvre Museum tour',
            location: '48.8606,2.3376', // Coordinates for maps
          ),
          DayItem(
            time: '18:00',
            activity: 'Seine River cruise',
            location: '48.8566,2.3522', // Coordinates for maps
          ),
        ],
      ),
      DayPlan(
        date: '2025-06-16',
        summary: 'Art and culture',
        items: [
          DayItem(
            time: '10:00',
            activity: 'Notre-Dame Cathedral',
            location: '48.8530,2.3499', // Coordinates for maps
          ),
          DayItem(
            time: '14:00',
            activity: 'Montmartre exploration',
            location: '48.8867,2.3431', // Coordinates for maps
          ),
          DayItem(
            time: '19:00',
            activity: 'Dinner in Latin Quarter',
            location: '48.8503,2.3469', // Coordinates for maps
          ),
        ],
      ),
    ],
  );

  static Itinerary get baliItinerary => Itinerary(
    title: '7 Days in Bali - Peaceful Exploration',
    startDate: '2025-04-15',
    endDate: '2025-04-22',
    days: [
      DayPlan(
        date: '2025-04-15',
        summary: 'Arrival in Bali and settle in Ubud',
        items: [
          DayItem(
            time: 'Morning',
            activity: 'Arrive in Bali, Denpasar Airport',
            location: '-8.7481,115.1672', // Denpasar Airport coordinates
          ),
          DayItem(
            time: 'Transfer',
            activity: 'Private driver to Ubud (around 1.5 hours)',
            location: '-8.5069,115.2625', // Ubud coordinates
          ),
          DayItem(
            time: 'Accommodation',
            activity: 'Check-in at a peaceful boutique hotel or villa in Ubud (e.g., Ubud Aura Retreat)',
            location: '-8.5069,115.2625', // Ubud coordinates
          ),
          DayItem(
            time: 'Afternoon',
            activity: 'Explore Ubud\'s local area, walk around the tranquil rice terraces at Tegallalang',
            location: '-8.4256,115.2764', // Tegallalang Rice Terraces
          ),
          DayItem(
            time: 'Evening',
            activity: 'Dinner at Locavore (known for farm-to-table dishes in peaceful environment)',
            location: '-8.5069,115.2625', // Ubud area
          ),
        ],
      ),
      DayPlan(
        date: '2025-04-16',
        summary: 'Ubud cultural immersion',
        items: [
          DayItem(
            time: 'Morning',
            activity: 'Visit Sacred Monkey Forest Sanctuary',
            location: '-8.5189,115.2592', // Monkey Forest
          ),
          DayItem(
            time: 'Afternoon',
            activity: 'Traditional Balinese cooking class',
            location: '-8.5069,115.2625', // Ubud
          ),
          DayItem(
            time: 'Evening',
            activity: 'Sunset at Campuhan Ridge Walk',
            location: '-8.5069,115.2625', // Ubud
          ),
        ],
      ),
      DayPlan(
        date: '2025-04-17',
        summary: 'Temples and waterfalls',
        items: [
          DayItem(
            time: 'Morning',
            activity: 'Visit Tirta Empul Temple for purification ritual',
            location: '-8.4156,115.3144', // Tirta Empul
          ),
          DayItem(
            time: 'Afternoon',
            activity: 'Explore Tegenungan Waterfall',
            location: '-8.4500,115.2833', // Tegenungan Waterfall
          ),
          DayItem(
            time: 'Evening',
            activity: 'Relax at hotel spa',
            location: '-8.5069,115.2625', // Ubud
          ),
        ],
      ),
    ],
  );
}

