import 'dart:async';

abstract class AIChatService {
  Stream<String> streamResponse(String userMessage);
  Future<String> getResponse(String userMessage);
}

class MockAIChatService implements AIChatService {
  @override
  Stream<String> streamResponse(String userMessage) async* {
    final responses = _getSampleResponses();
    final randomResponse = responses[DateTime.now().millisecondsSinceEpoch % responses.length];
    
    for (int i = 0; i < randomResponse.length; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      yield randomResponse.substring(0, i + 1);
    }
  }

  @override
  Future<String> getResponse(String userMessage) async {
    await Future.delayed(const Duration(seconds: 1));
    final responses = _getSampleResponses();
    return responses[DateTime.now().millisecondsSinceEpoch % responses.length];
  }

  List<String> _getSampleResponses() {
    return [
      "I'd be happy to help you plan your trip! Based on your preferences, I recommend starting with the historical sites in the morning when they're less crowded. The Fushimi Inari Shrine is particularly beautiful during sunrise.",
      "For your Kyoto itinerary, I suggest allocating at least 2-3 hours for the Fushimi Inari Shrine. The hike to the top takes about 2-3 hours round trip, but you can also just visit the lower sections if you're short on time.",
      "Great choice! The Gion district is perfect for experiencing traditional Kyoto. I recommend visiting in the early evening to see the geishas and maikos. Don't forget to try some traditional sweets at the local tea houses.",
      "For transportation in Kyoto, I highly recommend getting a day pass for the city buses. It's very convenient and cost-effective. The subway system is also good, but buses cover more areas of interest.",
      "Weather-wise, April is perfect for visiting Kyoto! The cherry blossoms should be in full bloom, and the temperatures are mild. Just bring a light jacket for the evenings as it can get a bit chilly.",
      "Food recommendations: Try the kaiseki dinner at a traditional ryokan, visit Nishiki Market for street food, and don't miss the matcha desserts. Kyoto is famous for its tofu dishes too!",
      "For accommodation, I recommend staying in the Gion or Higashiyama area for easy access to temples and traditional experiences. The area around Kyoto Station is also convenient for transportation.",
      "Don't miss the Arashiyama Bamboo Grove! It's best visited early in the morning to avoid crowds. You can also visit the nearby Tenryu-ji Temple and the Iwatayama Monkey Park.",
      "If you're interested in traditional crafts, visit the Nishijin Textile Center or take a pottery class in the Gojo-zaka area. These experiences will give you a deeper appreciation of Kyoto's culture.",
      "For a unique experience, consider staying at a traditional ryokan with onsen (hot spring) facilities. Many offer kaiseki dinners and beautiful garden views.",
    ];
  }
}

class OpenAIChatService implements AIChatService {
  @override
  Stream<String> streamResponse(String userMessage) async* {
    throw UnimplementedError('OpenAI integration not implemented yet');
  }

  @override
  Future<String> getResponse(String userMessage) async {
    throw UnimplementedError('OpenAI integration not implemented yet');
  }
}

class GeminiChatService implements AIChatService {
  @override
  Stream<String> streamResponse(String userMessage) async* {
    throw UnimplementedError('Gemini integration not implemented yet');
  }

  @override
  Future<String> getResponse(String userMessage) async {
    throw UnimplementedError('Gemini integration not implemented yet');
  }
}













