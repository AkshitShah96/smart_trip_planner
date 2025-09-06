import 'package:flutter/material.dart';
import 'package:smart_trip_planner/domain/entities/chat_message.dart';
import 'planet_ai_avatar.dart';

/// Simplified widget for displaying chat messages
class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final bool showTimestamp;
  final VoidCallback? onItineraryTap;

  const ChatMessageWidget({
    super.key,
    required this.message,
    this.showTimestamp = true,
    this.onItineraryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: message.type == MessageType.user 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.type == MessageType.ai) ...[
            _buildAvatar(context),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.type == MessageType.user 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                _buildMessageBubble(context),
                if (showTimestamp) ...[
                  const SizedBox(height: 4),
                  _buildTimestamp(context),
                ],
              ],
            ),
          ),
          if (message.type == MessageType.user) ...[
            const SizedBox(width: 8),
            _buildAvatar(context),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    if (message.type == MessageType.user) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: Colors.blue[600],
        child: const Icon(
          Icons.person,
          size: 16,
          color: Colors.white,
        ),
      );
    } else {
      // Use Planet AI avatar for AI messages
      return const PlanetAiAvatar(
        size: 32,
        showAnimation: false,
      );
    }
  }

  Widget _buildMessageBubble(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: message.type == MessageType.user 
            ? Colors.blue[600] 
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.content,
            style: TextStyle(
              color: message.type == MessageType.user 
                  ? Colors.white 
                  : Colors.black87,
              fontSize: 14,
            ),
          ),
          if (message.isStreaming) ...[
            const SizedBox(height: 4),
            _buildTypingIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(0),
        const SizedBox(width: 4),
        _buildDot(1),
        const SizedBox(width: 4),
        _buildDot(2),
      ],
    );
  }

  Widget _buildDot(int index) {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTimestamp(BuildContext context) {
    final time = message.timestamp;
    final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    
    return Text(
      timeString,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
      ),
    );
  }
}