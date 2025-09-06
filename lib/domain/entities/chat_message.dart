enum MessageType {
  user,
  ai,
}

class ChatMessage {
  final String id;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isStreaming;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isStreaming = false,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isStreaming,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, content: $content, type: $type, timestamp: $timestamp, isStreaming: $isStreaming)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.id == id &&
        other.content == content &&
        other.type == type &&
        other.timestamp == timestamp &&
        other.isStreaming == isStreaming;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        content.hashCode ^
        type.hashCode ^
        timestamp.hashCode ^
        isStreaming.hashCode;
  }
}


















