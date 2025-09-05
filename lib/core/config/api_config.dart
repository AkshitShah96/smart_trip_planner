class ApiConfig {
  static const String _openaiApiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  
  static String? get openaiApiKey => _openaiApiKey.isNotEmpty ? _openaiApiKey : null;
  static String? get geminiApiKey => _geminiApiKey.isNotEmpty ? _geminiApiKey : null;
  
  static bool get isOpenAIConfigured => openaiApiKey != null;
  static bool get isGeminiConfigured => geminiApiKey != null;
  static bool get isAnyAIConfigured => isOpenAIConfigured || isGeminiConfigured;
  
  static String get requiredOpenAIKey {
    final key = openaiApiKey;
    if (key == null) {
      throw Exception(
        'OpenAI API key not configured. '
        'Please set OPENAI_API_KEY environment variable or run with --dart-define=OPENAI_API_KEY=your_key'
      );
    }
    return key;
  }
  
  static String get requiredGeminiKey {
    final key = geminiApiKey;
    if (key == null) {
      throw Exception(
        'Gemini API key not configured. '
        'Please set GEMINI_API_KEY environment variable or run with --dart-define=GEMINI_API_KEY=your_key'
      );
    }
    return key;
  }
  
  static String get preferredService {
    if (isOpenAIConfigured) return 'openai';
    if (isGeminiConfigured) return 'gemini';
    return 'none';
  }
}













