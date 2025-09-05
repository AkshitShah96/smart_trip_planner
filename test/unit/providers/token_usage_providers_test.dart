import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_trip_planner/presentation/providers/token_usage_providers.dart';
import 'package:smart_trip_planner/presentation/widgets/token_usage_overlay.dart';

void main() {
  group('TokenUsageProviders Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with default state', () {
      // Act
      final state = container.read(tokenUsageProvider);

      // Assert
      expect(state.currentSession.requestTokens, equals(0));
      expect(state.currentSession.responseTokens, equals(0));
      expect(state.currentSession.totalTokens, equals(0));
      expect(state.totalUsage.requestTokens, equals(0));
      expect(state.totalUsage.responseTokens, equals(0));
      expect(state.totalUsage.totalTokens, equals(0));
      expect(state.isOverlayVisible, equals(false));
      expect(state.isDebugMode, equals(false));
    });

    test('should add token usage correctly', () {
      // Arrange
      final notifier = container.read(tokenUsageProvider.notifier);

      // Act
      notifier.addTokenUsage(100, 200);

      // Assert
      final state = container.read(tokenUsageProvider);
      expect(state.currentSession.requestTokens, equals(100));
      expect(state.currentSession.responseTokens, equals(200));
      expect(state.currentSession.totalTokens, equals(300));
      expect(state.totalUsage.requestTokens, equals(100));
      expect(state.totalUsage.responseTokens, equals(200));
      expect(state.totalUsage.totalTokens, equals(300));
    });

    test('should accumulate token usage across multiple calls', () {
      // Arrange
      final notifier = container.read(tokenUsageProvider.notifier);

      // Act
      notifier.addTokenUsage(50, 75);
      notifier.addTokenUsage(25, 50);
      notifier.addTokenUsage(100, 150);

      // Assert
      final state = container.read(tokenUsageProvider);
      expect(state.currentSession.requestTokens, equals(175));
      expect(state.currentSession.responseTokens, equals(275));
      expect(state.currentSession.totalTokens, equals(450));
      expect(state.totalUsage.requestTokens, equals(175));
      expect(state.totalUsage.responseTokens, equals(275));
      expect(state.totalUsage.totalTokens, equals(450));
    });

    test('should reset current session correctly', () {
      // Arrange
      final notifier = container.read(tokenUsageProvider.notifier);
      notifier.addTokenUsage(100, 200);

      // Act
      notifier.resetCurrentSession();

      // Assert
      final state = container.read(tokenUsageProvider);
      expect(state.currentSession.requestTokens, equals(0));
      expect(state.currentSession.responseTokens, equals(0));
      expect(state.currentSession.totalTokens, equals(0));
      // Total usage should remain unchanged
      expect(state.totalUsage.requestTokens, equals(100));
      expect(state.totalUsage.responseTokens, equals(200));
      expect(state.totalUsage.totalTokens, equals(300));
    });

    test('should reset all usage correctly', () {
      // Arrange
      final notifier = container.read(tokenUsageProvider.notifier);
      notifier.addTokenUsage(100, 200);

      // Act
      notifier.resetAllUsage();

      // Assert
      final state = container.read(tokenUsageProvider);
      expect(state.currentSession.requestTokens, equals(0));
      expect(state.currentSession.responseTokens, equals(0));
      expect(state.currentSession.totalTokens, equals(0));
      expect(state.totalUsage.requestTokens, equals(0));
      expect(state.totalUsage.responseTokens, equals(0));
      expect(state.totalUsage.totalTokens, equals(0));
    });

    test('should toggle overlay visibility', () {
      // Arrange
      final notifier = container.read(tokenUsageProvider.notifier);

      // Act
      notifier.toggleOverlay();

      // Assert
      final state = container.read(tokenUsageProvider);
      expect(state.isOverlayVisible, equals(true));

      // Act again
      notifier.toggleOverlay();

      // Assert
      final newState = container.read(tokenUsageProvider);
      expect(newState.isOverlayVisible, equals(false));
    });

    test('should set overlay visibility', () {
      // Arrange
      final notifier = container.read(tokenUsageProvider.notifier);

      // Act
      notifier.setOverlayVisible(true);

      // Assert
      final state = container.read(tokenUsageProvider);
      expect(state.isOverlayVisible, equals(true));

      // Act
      notifier.setOverlayVisible(false);

      // Assert
      final newState = container.read(tokenUsageProvider);
      expect(newState.isOverlayVisible, equals(false));
    });

    test('should toggle debug mode', () {
      // Arrange
      final notifier = container.read(tokenUsageProvider.notifier);

      // Act
      notifier.toggleDebugMode();

      // Assert
      final state = container.read(tokenUsageProvider);
      expect(state.isDebugMode, equals(true));
      expect(state.isOverlayVisible, equals(true)); // Should show overlay when debug mode is on

      // Act again
      notifier.toggleDebugMode();

      // Assert
      final newState = container.read(tokenUsageProvider);
      expect(newState.isDebugMode, equals(false));
      expect(newState.isOverlayVisible, equals(false)); // Should hide overlay when debug mode is off
    });

    test('should set debug mode', () {
      // Arrange
      final notifier = container.read(tokenUsageProvider.notifier);

      // Act
      notifier.setDebugMode(true);

      // Assert
      final state = container.read(tokenUsageProvider);
      expect(state.isDebugMode, equals(true));
      expect(state.isOverlayVisible, equals(true));

      // Act
      notifier.setDebugMode(false);

      // Assert
      final newState = container.read(tokenUsageProvider);
      expect(newState.isDebugMode, equals(false));
      expect(newState.isOverlayVisible, equals(false));
    });

    test('should provide convenience providers correctly', () {
      // Arrange
      final notifier = container.read(tokenUsageProvider.notifier);
      notifier.addTokenUsage(100, 200);

      // Act & Assert
      final currentSession = container.read(currentSessionTokensProvider);
      expect(currentSession.requestTokens, equals(100));
      expect(currentSession.responseTokens, equals(200));
      expect(currentSession.totalTokens, equals(300));

      final totalTokens = container.read(totalTokensProvider);
      expect(totalTokens.requestTokens, equals(100));
      expect(totalTokens.responseTokens, equals(200));
      expect(totalTokens.totalTokens, equals(300));

      final isOverlayVisible = container.read(isOverlayVisibleProvider);
      expect(isOverlayVisible, equals(false));

      final isDebugMode = container.read(isDebugModeProvider);
      expect(isDebugMode, equals(false));
    });

    test('should handle complex token usage scenarios', () {
      // Arrange
      final notifier = container.read(tokenUsageProvider.notifier);

      // Act - Simulate multiple chat interactions
      notifier.addTokenUsage(50, 100);  // First message
      notifier.addTokenUsage(75, 150);  // Second message
      notifier.addTokenUsage(25, 50);   // Third message
      notifier.resetCurrentSession();   // Clear current session
      notifier.addTokenUsage(100, 200); // New session

      // Assert
      final state = container.read(tokenUsageProvider);
      expect(state.currentSession.requestTokens, equals(100));
      expect(state.currentSession.responseTokens, equals(200));
      expect(state.currentSession.totalTokens, equals(300));
      
      // Total should include all previous usage
      expect(state.totalUsage.requestTokens, equals(250));
      expect(state.totalUsage.responseTokens, equals(500));
      expect(state.totalUsage.totalTokens, equals(750));
    });
  });

  group('TokenUsageData Tests', () {
    test('should create TokenUsageData correctly', () {
      // Act
      const data = TokenUsageData(
        requestTokens: 100,
        responseTokens: 200,
        totalTokens: 300,
      );

      // Assert
      expect(data.requestTokens, equals(100));
      expect(data.responseTokens, equals(200));
      expect(data.totalTokens, equals(300));
    });

    test('should copy TokenUsageData correctly', () {
      // Arrange
      const original = TokenUsageData(
        requestTokens: 100,
        responseTokens: 200,
        totalTokens: 300,
      );

      // Act
      final copied = original.copyWith(
        requestTokens: 150,
        responseTokens: 250,
      );

      // Assert
      expect(copied.requestTokens, equals(150));
      expect(copied.responseTokens, equals(250));
      expect(copied.totalTokens, equals(300)); // Should remain unchanged
    });

    test('should add TokenUsageData correctly', () {
      // Arrange
      const data1 = TokenUsageData(
        requestTokens: 100,
        responseTokens: 200,
        totalTokens: 300,
      );
      const data2 = TokenUsageData(
        requestTokens: 50,
        responseTokens: 75,
        totalTokens: 125,
      );

      // Act
      final result = data1 + data2;

      // Assert
      expect(result.requestTokens, equals(150));
      expect(result.responseTokens, equals(275));
      expect(result.totalTokens, equals(425));
    });

    test('should convert to string correctly', () {
      // Arrange
      const data = TokenUsageData(
        requestTokens: 100,
        responseTokens: 200,
        totalTokens: 300,
      );

      // Act
      final string = data.toString();

      // Assert
      expect(string, equals('TokenUsageData(request: 100, response: 200, total: 300)'));
    });
  });
}










