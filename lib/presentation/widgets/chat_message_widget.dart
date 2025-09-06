import 'package:flutter/material.dart';
import 'package:smart_trip_planner/core/models/chat_streaming_models.dart';
import 'package:smart_trip_planner/domain/entities/chat_message.dart';
import 'itinerary_diff_widget.dart';

/// Widget for displaying chat messages with itinerary support
class ChatMessageWidget extends StatelessWidget {
  final StreamingChatMessage message;
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
                if (message.hasItinerary) ...[
                  const SizedBox(height: 8),
                  _buildItineraryCard(context),
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
    return CircleAvatar(
      radius: 16,
      backgroundColor: message.type == MessageType.user 
          ? Colors.blue[600] 
          : Colors.grey[600],
      child: Icon(
        message.type == MessageType.user 
            ? Icons.person 
            : Icons.smart_toy,
        size: 16,
        color: Colors.white,
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: message.type == MessageType.user 
            ? Colors.blue[600] 
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(18).copyWith(
          bottomLeft: message.type == MessageType.user 
              ? const Radius.circular(18) 
              : const Radius.circular(4),
          bottomRight: message.type == MessageType.user 
              ? const Radius.circular(4) 
              : const Radius.circular(18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isStreaming) ...[
            _buildStreamingContent(context),
          ] else ...[
            _buildStaticContent(context),
          ],
          if (message.isStreaming) ...[
            const SizedBox(height: 4),
            _buildStreamingIndicator(context),
          ],
        ],
      ),
    );
  }

  Widget _buildStreamingContent(BuildContext context) {
    if (message.streamResponse == null) {
      return Text(
        message.content,
        style: TextStyle(
          color: message.type == MessageType.user 
              ? Colors.white 
              : Colors.black87,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text content
        if (message.streamResponse!.fullText.isNotEmpty)
          Text(
            message.streamResponse!.fullText,
            style: TextStyle(
              color: message.type == MessageType.user 
                  ? Colors.white 
                  : Colors.black87,
            ),
          ),
        
        // Show thinking indicator if thinking
        if (message.streamResponse!.chunks.any((c) => c.type == StreamResponseType.thinking))
          _buildThinkingIndicator(context),
      ],
    );
  }

  Widget _buildStaticContent(BuildContext context) {
    return Text(
      message.content,
      style: TextStyle(
        color: message.type == MessageType.user 
            ? Colors.white 
            : Colors.black87,
      ),
    );
  }

  Widget _buildThinkingIndicator(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              message.type == MessageType.user 
                  ? Colors.white70 
                  : Colors.grey[600]!,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Thinking...',
          style: TextStyle(
            color: message.type == MessageType.user 
                ? Colors.white70 
                : Colors.grey[600],
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildStreamingIndicator(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 8,
          height: 8,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              message.type == MessageType.user 
                  ? Colors.white70 
                  : Colors.grey[600]!,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'Streaming...',
          style: TextStyle(
            color: message.type == MessageType.user 
                ? Colors.white70 
                : Colors.grey[600],
            fontSize: 10,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildTimestamp(BuildContext context) {
    final time = message.timestamp;
    final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    
    return Text(
      timeString,
      style: TextStyle(
        color: Colors.grey[500],
        fontSize: 10,
      ),
    );
  }

  Widget _buildItineraryCard(BuildContext context) {
    if (message.itinerary == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: onItineraryTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.travel_explore,
                      size: 16,
                      color: Colors.blue[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message.itinerary!.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (message.hasChanges) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Modified',
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${message.itinerary!.startDate} - ${message.itinerary!.endDate}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${message.itinerary!.days.length} days planned',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (message.hasChanges) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.compare_arrows,
                          size: 14,
                          color: Colors.blue[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            message.diff?.getChangesSummary() ?? 'Changes detected',
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget for displaying streaming text with typewriter effect
class StreamingTextWidget extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration delay;

  const StreamingTextWidget({
    super.key,
    required this.text,
    this.style,
    this.delay = const Duration(milliseconds: 30),
  });

  @override
  State<StreamingTextWidget> createState() => _StreamingTextWidgetState();
}

class _StreamingTextWidgetState extends State<StreamingTextWidget> {
  String _displayedText = '';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startStreaming();
  }

  @override
  void didUpdateWidget(StreamingTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _currentIndex = 0;
      _displayedText = '';
      _startStreaming();
    }
  }

  void _startStreaming() {
    if (_currentIndex < widget.text.length) {
      Future.delayed(widget.delay, () {
        if (mounted) {
          setState(() {
            _displayedText = widget.text.substring(0, _currentIndex + 1);
            _currentIndex++;
          });
          _startStreaming();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: widget.style,
    );
  }
}

/// Widget for displaying itinerary in chat
class ChatItineraryWidget extends StatelessWidget {
  final StreamingChatMessage message;
  final VoidCallback? onTap;
  final bool showDiff;

  const ChatItineraryWidget({
    super.key,
    required this.message,
    this.onTap,
    this.showDiff = true,
  });

  @override
  Widget build(BuildContext context) {
    if (message.itinerary == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        elevation: 3,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.travel_explore,
                      color: Colors.blue[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message.itinerary!.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    if (message.hasChanges && showDiff) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Modified',
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Date range
                Text(
                  '${message.itinerary!.startDate} - ${message.itinerary!.endDate}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Days preview
                ...message.itinerary!.days.take(3).map((day) {
                  final dayIndex = message.itinerary!.days.indexOf(day);
                  final hasChanges = message.hasChangesInDay(dayIndex);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasChanges ? Colors.yellow[50] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: hasChanges ? Colors.yellow[300]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Day ${dayIndex + 1} - ${day.date}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: hasChanges ? Colors.orange[800] : Colors.grey[800],
                              ),
                            ),
                            if (hasChanges) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.edit,
                                size: 14,
                                color: Colors.orange[600],
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          day.summary,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.items.length} activities',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                
                if (message.itinerary!.days.length > 3) ...[
                  Text(
                    '... and ${message.itinerary!.days.length - 3} more days',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                
                // Changes summary
                if (message.hasChanges && showDiff) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.compare_arrows,
                          size: 16,
                          color: Colors.blue[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message.diff?.getChangesSummary() ?? 'Changes detected',
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
