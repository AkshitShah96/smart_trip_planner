import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_message_widget.dart';

class ChatTestPage extends ConsumerWidget {
  const ChatTestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planet AI Chat Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                final message = chatState.messages[index];
                return ChatMessageWidget(message: message);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (text) {
                      if (text.trim().isNotEmpty) {
                        ref.read(chatProvider.notifier).sendMessage(text.trim());
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    ref.read(chatProvider.notifier).sendMessage('Test message');
                  },
                  child: const Text('Send'),
                ),
              ],
            ),
          ),
          if (chatState.isLoading)
            const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
