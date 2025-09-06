import 'package:flutter_riverpod/flutter_riverpod.dart';

class TokenUsageData {
  final int requestTokens;
  final int responseTokens;
  final int totalTokens;

  const TokenUsageData({
    required this.requestTokens,
    required this.responseTokens,
    required this.totalTokens,
  });

  TokenUsageData copyWith({
    int? requestTokens,
    int? responseTokens,
    int? totalTokens,
  }) {
    return TokenUsageData(
      requestTokens: requestTokens ?? this.requestTokens,
      responseTokens: responseTokens ?? this.responseTokens,
      totalTokens: totalTokens ?? this.totalTokens,
    );
  }

  TokenUsageData operator +(TokenUsageData other) {
    return TokenUsageData(
      requestTokens: requestTokens + other.requestTokens,
      responseTokens: responseTokens + other.responseTokens,
      totalTokens: totalTokens + other.totalTokens,
    );
  }

  @override
  String toString() {
    return 'TokenUsageData(request: $requestTokens, response: $responseTokens, total: $totalTokens)';
  }
}

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

class TokenUsageNotifier extends StateNotifier<TokenUsageState> {
  TokenUsageNotifier() : super(const TokenUsageState());

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

  void resetCurrentSession() {
    state = state.copyWith(
      currentSession: const TokenUsageData(requestTokens: 0, responseTokens: 0, totalTokens: 0),
    );
  }

  void resetAllUsage() {
    state = state.copyWith(
      currentSession: const TokenUsageData(requestTokens: 0, responseTokens: 0, totalTokens: 0),
      totalUsage: const TokenUsageData(requestTokens: 0, responseTokens: 0, totalTokens: 0),
    );
  }

  void toggleOverlay() {
    state = state.copyWith(
      isOverlayVisible: !state.isOverlayVisible,
    );
  }

  void setOverlayVisible(bool visible) {
    state = state.copyWith(
      isOverlayVisible: visible,
    );
  }

  void toggleDebugMode() {
    state = state.copyWith(
      isDebugMode: !state.isDebugMode,
      isOverlayVisible: !state.isDebugMode,
    );
  }

  void setDebugMode(bool enabled) {
    state = state.copyWith(
      isDebugMode: enabled,
      isOverlayVisible: enabled,
    );
  }
}

final tokenUsageProvider = StateNotifierProvider<TokenUsageNotifier, TokenUsageState>((ref) {
  return TokenUsageNotifier();
});

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













