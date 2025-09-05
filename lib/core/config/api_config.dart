class ApiConfig {
  static const String _openaiApiKey = String.fromEnvironment('OPENAI_API_KEY');
  
  /// Gets the OpenAI API key from environment variables
  /// 
  /// To set the API key, run the app with:
  /// flutter run --dart-define=OPENAI_API_KEY=your_api_key_here
  static String? get openaiApiKey => _openaiApiKey.isNotEmpty ? _openaiApiKey : null;
  
  /// Checks if the OpenAI API key is configured
  static bool get isOpenAIConfigured => openaiApiKey != null;
  
  /// Gets the API key or throws an exception if not configured
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













