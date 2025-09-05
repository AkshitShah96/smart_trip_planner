import 'itinerary.dart';
import 'day_plan.dart';
import 'day_item.dart';

class SampleItinerary {
  static Itinerary createSampleItinerary() {
    // Create the main itinerary
    final itinerary = Itinerary(
      title: "Kyoto 5-Day Solo Trip",
      startDate: "2025-04-10",
      endDate: "2025-04-15",
    );

    // Create day 1
    final day1 = DayPlan(
      date: "2025-04-10",
      summary: "Fushimi Inari & Gion",
    );

    // Add items to day 1
    final item1 = DayItem(
      time: "09:00",
      activity: "Climb Fushimi Inari Shrine",
      location: "34.9671,135.7727",
    );

    day1.items.add(item1);
    itinerary.days.add(day1);

    return itinerary;
  }

  static Map<String, dynamic> getSampleJson() {
    return {
      "title": "Kyoto 5-Day Solo Trip",
      "startDate": "2025-04-10",
      "endDate": "2025-04-15",
      "days": [
        {
          "date": "2025-04-10",
          "summary": "Fushimi Inari & Gion",
          "items": [
            {
              "time": "09:00",
              "activity": "Climb Fushimi Inari Shrine",
              "location": "34.9671,135.7727"
            }
          ]
        }
      ]
    };
  }

  static Itinerary fromSampleJson() {
    final json = getSampleJson();
    return Itinerary.fromJson(json);
  }
}













