import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfigService {
  static const String _openaiKeyKey = 'openai_api_key';
  static const String _geminiKeyKey = 'gemini_api_key';
  static const String _preferredProviderKey = 'preferred_ai_provider';
  static const String _configTimestampKey = 'config_timestamp';

  Future<void> saveOpenAIKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_openaiKeyKey, apiKey);
    await _updateTimestamp();
  }

  Future<void> saveGeminiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiKeyKey, apiKey);
    await _updateTimestamp();
  }

  Future<String?> getOpenAIKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_openaiKeyKey);
  }

  Future<String?> getGeminiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiKeyKey);
  }

  Future<void> setPreferredProvider(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferredProviderKey, provider);
  }

  Future<String> getPreferredProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_preferredProviderKey) ?? 'openai';
  }

  Future<bool> hasConfiguredKeys() async {
    final openaiKey = await getOpenAIKey();
    final geminiKey = await getGeminiKey();
    return openaiKey != null || geminiKey != null;
  }

  Future<String?> getBestAvailableKey() async {
    final preferredProvider = await getPreferredProvider();
    
    if (preferredProvider == 'openai') {
      final openaiKey = await getOpenAIKey();
      if (openaiKey != null) return openaiKey;
      
      final geminiKey = await getGeminiKey();
      if (geminiKey != null) return geminiKey;
    } else {
      final geminiKey = await getGeminiKey();
      if (geminiKey != null) return geminiKey;
      
      final openaiKey = await getOpenAIKey();
      if (openaiKey != null) return openaiKey;
    }
    
    return null;
  }

  Future<String> getBestAvailableProvider() async {
    final preferredProvider = await getPreferredProvider();
    
    if (preferredProvider == 'openai') {
      final openaiKey = await getOpenAIKey();
      if (openaiKey != null) return 'openai';
      
      final geminiKey = await getGeminiKey();
      if (geminiKey != null) return 'gemini';
    } else {
      final geminiKey = await getGeminiKey();
      if (geminiKey != null) return 'gemini';
      
      final openaiKey = await getOpenAIKey();
      if (openaiKey != null) return 'openai';
    }
    
    return 'none';
  }

  Future<void> clearAllKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_openaiKeyKey);
    await prefs.remove(_geminiKeyKey);
    await prefs.remove(_preferredProviderKey);
    await prefs.remove(_configTimestampKey);
  }

  Future<DateTime?> getConfigTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_configTimestampKey);
    if (timestamp != null) {
      return DateTime.parse(timestamp);
    }
    return null;
  }

  Future<void> _updateTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configTimestampKey, DateTime.now().toIso8601String());
  }

  Future<ApiConfigSummary> getConfigSummary() async {
    final openaiKey = await getOpenAIKey();
    final geminiKey = await getGeminiKey();
    final preferredProvider = await getPreferredProvider();
    final timestamp = await getConfigTimestamp();

    return ApiConfigSummary(
      hasOpenAIKey: openaiKey != null,
      hasGeminiKey: geminiKey != null,
      preferredProvider: preferredProvider,
      lastUpdated: timestamp,
      totalKeysConfigured: (openaiKey != null ? 1 : 0) + (geminiKey != null ? 1 : 0),
    );
  }

  Future<void> saveApiKeys({
    String? openaiKey,
    String? geminiKey,
    String? preferredProvider,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (openaiKey != null) {
      await prefs.setString(_openaiKeyKey, openaiKey);
    }
    
    if (geminiKey != null) {
      await prefs.setString(_geminiKeyKey, geminiKey);
    }
    
    if (preferredProvider != null) {
      await prefs.setString(_preferredProviderKey, preferredProvider);
    }
    
    await _updateTimestamp();
  }
}

class ApiConfigSummary {
  final bool hasOpenAIKey;
  final bool hasGeminiKey;
  final String preferredProvider;
  final DateTime? lastUpdated;
  final int totalKeysConfigured;

  ApiConfigSummary({
    required this.hasOpenAIKey,
    required this.hasGeminiKey,
    required this.preferredProvider,
    this.lastUpdated,
    required this.totalKeysConfigured,
  });

  bool get hasAnyKeys => hasOpenAIKey || hasGeminiKey;
  
  String get status {
    if (totalKeysConfigured == 0) return 'No API keys configured';
    if (totalKeysConfigured == 1) return '1 API key configured';
    return '$totalKeysConfigured API keys configured';
  }

  @override
  String toString() {
    return 'ApiConfigSummary(hasOpenAIKey: $hasOpenAIKey, hasGeminiKey: $hasGeminiKey, preferredProvider: $preferredProvider, totalKeysConfigured: $totalKeysConfigured)';
  }
}


