import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_trip_planner/presentation/pages/chat_page.dart';
import 'package:smart_trip_planner/presentation/providers/chat_providers.dart';
import 'package:smart_trip_planner/presentation/providers/token_usage_providers.dart';
import 'package:smart_trip_planner/domain/entities/chat_message.dart';

void main() {
  group('ChatPage Widget Tests', () {
    testWidgets('should display empty state when no messages', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatPage(),
          ),
        ),
      );

      // Assert
      expect(find.text('Welcome to Trip Assistant!'), findsOneWidget);
      expect(find.text('I\'m here to help you plan your perfect trip.'), findsOneWidget);
      expect(find.text('Try asking: "What should I see in Kyoto?"'), findsOneWidget);
    });

    testWidgets('should display chat input field', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatPage(),
          ),
        ),
      );

      // Assert
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Ask about your trip...'), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('should send message when send button is tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatPage(),
          ),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextField), 'Hello, can you help me plan a trip?');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Assert
      expect(find.text('Hello, can you help me plan a trip?'), findsOneWidget);
    });

    testWidgets('should display user message bubble', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatPage(),
          ),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Assert
      expect(find.text('Test message'), findsOneWidget);
      // User messages should be aligned to the right
      final userMessage = find.text('Test message');
      expect(userMessage, findsOneWidget);
    });

    testWidgets('should show loading state when sending message', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatPage(),
          ),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump(); // Don't wait for completion

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should clear chat when clear button is tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatPage(),
          ),
        ),
      );

      // Send a message first
      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.clear_all));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Welcome to Trip Assistant!'), findsOneWidget);
    });

    testWidgets('should toggle debug mode when bug icon is tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatPage(),
          ),
        ),
      );

      // Act
      await tester.tap(find.byIcon(Icons.bug_report_outlined));
      await tester.pump();

      // Assert
      expect(find.text('Token Usage'), findsOneWidget);
      expect(find.byIcon(Icons.bug_report), findsOneWidget);
    });

    testWidgets('should show token usage overlay in debug mode', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatPage(),
          ),
        ),
      );

      // Act
      await tester.tap(find.byIcon(Icons.bug_report_outlined));
      await tester.pump();

      // Assert
      expect(find.text('Token Usage'), findsOneWidget);
      expect(find.text('Request:'), findsOneWidget);
      expect(find.text('Response:'), findsOneWidget);
      expect(find.text('Total:'), findsOneWidget);
    });

    testWidgets('should update token usage when message is sent', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatPage(),
          ),
        ),
      );

      // Enable debug mode
      await tester.tap(find.byIcon(Icons.bug_report_outlined));
      await tester.pump();

      // Act
      await tester.enterText(find.byType(TextField), 'Hello world');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Request:'), findsOneWidget);
      // Token count should be greater than 0
      expect(find.textContaining(RegExp(r'Request: \d+')), findsOneWidget);
    });

    testWidgets('should disable input field when loading', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatPage(),
          ),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump(); // Don't wait for completion

      // Assert
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('should show send button as loading when processing', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatPage(),
          ),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump(); // Don't wait for completion

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('ChatPage Integration Tests', () {
    testWidgets('should complete full chat flow', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatPage(),
          ),
        ),
      );

      // Act - Send first message
      await tester.enterText(find.byType(TextField), 'Plan a trip to Kyoto');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Assert - Should have user message and AI response
      expect(find.text('Plan a trip to Kyoto'), findsOneWidget);
      // AI response should appear (from our mock responses)
      expect(find.textContaining('Kyoto'), findsAtLeastNWidgets(1));

      // Act - Send second message
      await tester.enterText(find.byType(TextField), 'What about Tokyo?');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Assert - Should have both messages
      expect(find.text('Plan a trip to Kyoto'), findsOneWidget);
      expect(find.text('What about Tokyo?'), findsOneWidget);
    });

    testWidgets('should handle multiple rapid messages', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatPage(),
          ),
        ),
      );

      // Act - Send multiple messages quickly
      await tester.enterText(find.byType(TextField), 'Message 1');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Message 2');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Message 3');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Message 1'), findsOneWidget);
      expect(find.text('Message 2'), findsOneWidget);
      expect(find.text('Message 3'), findsOneWidget);
    });
  });
}


















