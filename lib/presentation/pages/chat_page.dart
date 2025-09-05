import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_providers.dart';
import '../providers/token_usage_providers.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/token_usage_overlay.dart';
import '../../core/theme/app_theme.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref, tokenUsageState) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppTheme.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text('Trip Assistant'),
        ],
      ),
      backgroundColor: AppTheme.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
            tokenUsageState.isDebugMode 
                ? Icons.bug_report_rounded 
                : Icons.bug_report_outlined,
            color: tokenUsageState.isDebugMode 
                ? AppTheme.primaryBlue 
                : AppTheme.textSecondary,
          ),
          onPressed: () {
            ref.read(tokenUsageProvider.notifier).toggleDebugMode();
          },
          tooltip: tokenUsageState.isDebugMode ? 'Disable Debug Mode' : 'Enable Debug Mode',
        ),
        IconButton(
          icon: const Icon(Icons.clear_all_rounded),
          onPressed: () {
            ref.read(chatProvider.notifier).clearChat();
            ref.read(tokenUsageProvider.notifier).resetCurrentSession();
          },
          tooltip: 'Clear Chat',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final tokenUsageState = ref.watch(tokenUsageProvider);
    final messages = chatState.messages;
    final isLoading = chatState.isLoading;

    ref.listen(chatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: _buildAppBar(context, ref, tokenUsageState),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(top: 16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return ChatBubble(message: message);
                        },
                      ),
              ),
              ChatInputField(
                onSendMessage: (message) {
                  ref.read(chatProvider.notifier).addUserMessage(message);
                },
                isLoading: isLoading,
              ),
            ],
          ),
          TokenUsageOverlay(
            requestTokens: tokenUsageState.currentSession.requestTokens,
            responseTokens: tokenUsageState.currentSession.responseTokens,
            totalTokens: tokenUsageState.currentSession.totalTokens,
            isVisible: tokenUsageState.isOverlayVisible,
            onToggle: () {
              ref.read(tokenUsageProvider.notifier).toggleOverlay();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: AppTheme.elevatedShadow,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 64,
                color: AppTheme.white,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Welcome to Trip Assistant!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'I\'m here to help you plan your perfect trip. Ask me about:',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  _buildSuggestionItem('Best places to visit', Icons.location_on_rounded),
                  _buildSuggestionItem('Local recommendations', Icons.star_rounded),
                  _buildSuggestionItem('Weather and timing', Icons.wb_sunny_rounded),
                  _buildSuggestionItem('Transportation options', Icons.directions_bus_rounded),
                  _buildSuggestionItem('Food and dining suggestions', Icons.restaurant_rounded),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.lightBlue,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Try asking: "What should I see in Kyoto?"',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
