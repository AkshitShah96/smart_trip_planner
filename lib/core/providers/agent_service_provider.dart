import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/agent_service.dart';
import '../services/ollama_service.dart';
import '../config/api_config.dart';

/// Provider for AgentService instance
final agentServiceProvider = Provider<AgentService?>((ref) {
  try {
    // Try to create service with both APIs if available
    if (ApiConfig.isAnyAIConfigured) {
      return AgentServiceFactory.createFromConfig(
        openaiApiKey: ApiConfig.openaiApiKey,
        geminiApiKey: ApiConfig.geminiApiKey,
        preferOpenAI: ApiConfig.isOpenAIConfigured,
        enableWebSearch: true,
      );
    }
    
    // Return null if no API keys are configured
    return null;
  } catch (e) {
    return null;
  }
});

/// Provider for OllamaService instance
final ollamaServiceProvider = Provider<OllamaService?>((ref) {
  try {
    return OllamaServiceFactory.createService(
      model: 'llama2', // Default model, can be configured
      enableWebSearch: true,
    );
  } catch (e) {
    return null;
  }
});

/// Provider for checking if Ollama is available
final isOllamaAvailableProvider = FutureProvider<bool>((ref) async {
  final ollamaService = ref.watch(ollamaServiceProvider);
  if (ollamaService == null) return false;
  
  return await ollamaService.isServerAvailable();
});

/// Provider for checking if AgentService is available
final isAgentServiceAvailableProvider = Provider<bool>((ref) {
  final agentService = ref.watch(agentServiceProvider);
  return agentService != null;
});

/// Provider for agent service status
final agentServiceStatusProvider = Provider<String>((ref) {
  final isAvailable = ref.watch(isAgentServiceAvailableProvider);
  
  if (isAvailable) {
    return 'AI Agent Service Available';
  } else {
    return 'AI Agent Service Not Configured';
  }
});




