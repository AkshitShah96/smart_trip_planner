class ApiConfig {
  static const String _openaiApiKey = String.fromEnvironment('OPENAI_API_KEY');
  
  static String? get openaiApiKey => _openaiApiKey.isNotEmpty ? _openaiApiKey : null;
  
  static bool get isOpenAIConfigured => openaiApiKey != null;
  
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
}













