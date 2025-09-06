import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/agent_service.dart';
import '../config/api_config.dart';

/// Provider for AgentService instance
final agentServiceProvider = Provider<AgentService?>((ref) {
  try {
    // Try to create OpenAI service first
    if (ApiConfig.isOpenAIConfigured) {
      return AgentServiceFactory.createOpenAIService(
        apiKey: ApiConfig.requiredOpenAIKey,
      );
    }
    
    // Fallback to Gemini if available
    // Note: You'll need to add Gemini API key configuration
    return null;
  } catch (e) {
    return null;
  }
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




