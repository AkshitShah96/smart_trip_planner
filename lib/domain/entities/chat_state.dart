import 'chat_message.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'ChatState(messages: ${messages.length}, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatState &&
        other.messages == messages &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode {
    return messages.hashCode ^ isLoading.hashCode ^ error.hashCode;
  }
}


















