import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/token_usage_overlay.dart';

// State for token usage tracking
class TokenUsageState {
  final TokenUsageData currentSession;
  final TokenUsageData totalUsage;
  final bool isOverlayVisible;
  final bool isDebugMode;

  const TokenUsageState({
    this.currentSession = const TokenUsageData(requestTokens: 0, responseTokens: 0, totalTokens: 0),
    this.totalUsage = const TokenUsageData(requestTokens: 0, responseTokens: 0, totalTokens: 0),
    this.isOverlayVisible = false,
    this.isDebugMode = false,
  });

  TokenUsageState copyWith({
    TokenUsageData? currentSession,
    TokenUsageData? totalUsage,
    bool? isOverlayVisible,
    bool? isDebugMode,
  }) {
    return TokenUsageState(
      currentSession: currentSession ?? this.currentSession,
      totalUsage: totalUsage ?? this.totalUsage,
      isOverlayVisible: isOverlayVisible ?? this.isOverlayVisible,
      isDebugMode: isDebugMode ?? this.isDebugMode,
    );
  }
}

// Notifier for token usage
class TokenUsageNotifier extends StateNotifier<TokenUsageState> {
  TokenUsageNotifier() : super(const TokenUsageState());

  /// Add tokens from a request/response
  void addTokenUsage(int requestTokens, int responseTokens) {
    final newUsage = TokenUsageData(
      requestTokens: requestTokens,
      responseTokens: responseTokens,
      totalTokens: requestTokens + responseTokens,
    );

    state = state.copyWith(
      currentSession: state.currentSession + newUsage,
      totalUsage: state.totalUsage + newUsage,
    );
  }

  /// Reset current session tokens
  void resetCurrentSession() {
    state = state.copyWith(
      currentSession: const TokenUsageData(requestTokens: 0, responseTokens: 0, totalTokens: 0),
    );
  }

  /// Reset all token usage
  void resetAllUsage() {
    state = state.copyWith(
      currentSession: const TokenUsageData(requestTokens: 0, responseTokens: 0, totalTokens: 0),
      totalUsage: const TokenUsageData(requestTokens: 0, responseTokens: 0, totalTokens: 0),
    );
  }

  /// Toggle overlay visibility
  void toggleOverlay() {
    state = state.copyWith(
      isOverlayVisible: !state.isOverlayVisible,
    );
  }

  /// Set overlay visibility
  void setOverlayVisible(bool visible) {
    state = state.copyWith(
      isOverlayVisible: visible,
    );
  }

  /// Toggle debug mode
  void toggleDebugMode() {
    state = state.copyWith(
      isDebugMode: !state.isDebugMode,
      isOverlayVisible: !state.isDebugMode, // Show overlay when debug mode is on
    );
  }

  /// Set debug mode
  void setDebugMode(bool enabled) {
    state = state.copyWith(
      isDebugMode: enabled,
      isOverlayVisible: enabled,
    );
  }
}

// Provider for token usage state
final tokenUsageProvider = StateNotifierProvider<TokenUsageNotifier, TokenUsageState>((ref) {
  return TokenUsageNotifier();
});

// Convenience providers
final currentSessionTokensProvider = Provider<TokenUsageData>((ref) {
  return ref.watch(tokenUsageProvider).currentSession;
});

final totalTokensProvider = Provider<TokenUsageData>((ref) {
  return ref.watch(tokenUsageProvider).totalUsage;
});

final isOverlayVisibleProvider = Provider<bool>((ref) {
  return ref.watch(tokenUsageProvider).isOverlayVisible;
});

final isDebugModeProvider = Provider<bool>((ref) {
  return ref.watch(tokenUsageProvider).isDebugMode;
});













