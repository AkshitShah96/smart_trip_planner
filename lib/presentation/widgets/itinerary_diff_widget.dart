import 'package:flutter/material.dart';
import 'package:smart_trip_planner/data/models/itinerary.dart';
import 'package:smart_trip_planner/data/models/day_plan.dart';
import 'package:smart_trip_planner/data/models/day_item.dart';
import 'package:smart_trip_planner/core/models/itinerary_change.dart';

/// Widget for displaying itinerary with change highlighting
class ItineraryDiffWidget extends StatelessWidget {
  final ItineraryDiffResult diffResult;
  final bool showChangeDetails;
  final VoidCallback? onAcceptChanges;
  final VoidCallback? onRejectChanges;

  const ItineraryDiffWidget({
    super.key,
    required this.diffResult,
    this.showChangeDetails = true,
    this.onAcceptChanges,
    this.onRejectChanges,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Changes summary header
        if (diffResult.hasChanges) ...[
          _buildChangesSummary(context),
          const SizedBox(height: 16),
        ],
        
        // Itinerary content with highlighting
        _buildItineraryContent(context),
        
        // Action buttons
        if (diffResult.hasChanges && showChangeDetails) ...[
          const SizedBox(height: 16),
          _buildActionButtons(context),
        ],
      ],
    );
  }

  Widget _buildChangesSummary(BuildContext context) {
    final summary = diffResult.getChangesSummary();
    final added = diffResult.getChangesByType(ChangeType.added).length;
    final removed = diffResult.getChangesByType(ChangeType.removed).length;
    final modified = diffResult.getChangesByType(ChangeType.modified).length;
    final moved = diffResult.getChangesByType(ChangeType.moved).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Changes Detected',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: TextStyle(color: Colors.blue[700]),
          ),
          if (added > 0 || removed > 0 || modified > 0 || moved > 0) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (added > 0) _buildChangeChip('Added', added, Colors.green),
                if (removed > 0) _buildChangeChip('Removed', removed, Colors.red),
                if (modified > 0) _buildChangeChip('Modified', modified, Colors.orange),
                if (moved > 0) _buildChangeChip('Moved', moved, Colors.purple),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChangeChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color.withOpacity(0.8),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildItineraryContent(BuildContext context) {
    final itinerary = diffResult.itinerary;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          _buildTitle(context, itinerary.title),
          const SizedBox(height: 8),
          
          // Date range
          _buildDateRange(context, itinerary.startDate, itinerary.endDate),
          const SizedBox(height: 16),
          
          // Days
          ...itinerary.days.asMap().entries.map((entry) {
            final dayIndex = entry.key;
            final day = entry.value;
            return _buildDay(context, day, dayIndex);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context, String title) {
    final hasTitleChanges = diffResult.getChangesByGranularity(ChangeGranularity.itinerary)
        .any((change) => change.path == 'title');
    
    return _buildHighlightedText(
      context,
      title,
      'Trip Title',
      hasTitleChanges,
      ChangeType.modified,
    );
  }

  Widget _buildDateRange(BuildContext context, String startDate, String endDate) {
    final hasStartDateChanges = diffResult.getChangesByGranularity(ChangeGranularity.itinerary)
        .any((change) => change.path == 'startDate');
    final hasEndDateChanges = diffResult.getChangesByGranularity(ChangeGranularity.itinerary)
        .any((change) => change.path == 'endDate');
    
    return Row(
      children: [
        _buildHighlightedText(
          context,
          startDate,
          'Start Date',
          hasStartDateChanges,
          ChangeType.modified,
        ),
        const Text(' - '),
        _buildHighlightedText(
          context,
          endDate,
          'End Date',
          hasEndDateChanges,
          ChangeType.modified,
        ),
      ],
    );
  }

  Widget _buildDay(BuildContext context, DayPlan day, int dayIndex) {
    final hasDayChanges = diffResult.hasChangesInDay(dayIndex);
    final dayChanges = diffResult.getChangesForDay(dayIndex);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasDayChanges ? Colors.yellow[50] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasDayChanges ? Colors.yellow[300]! : Colors.grey[300]!,
          width: hasDayChanges ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: hasDayChanges ? Colors.orange[600] : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Day ${dayIndex + 1} - ${day.date}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: hasDayChanges ? Colors.orange[800] : Colors.grey[800],
                ),
              ),
              if (hasDayChanges) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.edit,
                  size: 14,
                  color: Colors.orange[600],
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          
          // Day summary
          _buildDaySummary(context, day.summary, dayIndex),
          const SizedBox(height: 12),
          
          // Items
          ...day.items.asMap().entries.map((entry) {
            final itemIndex = entry.key;
            final item = entry.value;
            return _buildItem(context, item, dayIndex, itemIndex);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDaySummary(BuildContext context, String summary, int dayIndex) {
    final hasSummaryChanges = diffResult.getChangesForDay(dayIndex)
        .any((change) => change.path == 'days[$dayIndex].summary');
    
    return _buildHighlightedText(
      context,
      summary,
      'Day Summary',
      hasSummaryChanges,
      ChangeType.modified,
    );
  }

  Widget _buildItem(BuildContext context, DayItem item, int dayIndex, int itemIndex) {
    final hasItemChanges = diffResult.hasChangesInItem(dayIndex, itemIndex);
    final itemChanges = diffResult.getChangesForItem(dayIndex, itemIndex);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: hasItemChanges ? Colors.blue[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: hasItemChanges ? Colors.blue[200]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time and activity
          Row(
            children: [
              _buildItemTime(context, item.time, dayIndex, itemIndex),
              const SizedBox(width: 12),
              Expanded(
                child: _buildItemActivity(context, item.activity, dayIndex, itemIndex),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // Location
          _buildItemLocation(context, item.location, dayIndex, itemIndex),
          
          // Additional info
          if (item.additionalInfo != null && item.additionalInfo!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildItemAdditionalInfo(context, item.additionalInfo!, dayIndex, itemIndex),
          ],
        ],
      ),
    );
  }

  Widget _buildItemTime(BuildContext context, String time, int dayIndex, int itemIndex) {
    final hasTimeChanges = diffResult.getChangesForItem(dayIndex, itemIndex)
        .any((change) => change.path == 'days[$dayIndex].items[$itemIndex].time');
    
    return _buildHighlightedText(
      context,
      time,
      'Time',
      hasTimeChanges,
      ChangeType.modified,
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildItemActivity(BuildContext context, String activity, int dayIndex, int itemIndex) {
    final hasActivityChanges = diffResult.getChangesForItem(dayIndex, itemIndex)
        .any((change) => change.path == 'days[$dayIndex].items[$itemIndex].activity');
    
    return _buildHighlightedText(
      context,
      activity,
      'Activity',
      hasActivityChanges,
      ChangeType.modified,
    );
  }

  Widget _buildItemLocation(BuildContext context, String location, int dayIndex, int itemIndex) {
    final hasLocationChanges = diffResult.getChangesForItem(dayIndex, itemIndex)
        .any((change) => change.path == 'days[$dayIndex].items[$itemIndex].location');
    
    return Row(
      children: [
        Icon(
          Icons.location_on,
          size: 14,
          color: hasLocationChanges ? Colors.orange[600] : Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _buildHighlightedText(
            context,
            location,
            'Location',
            hasLocationChanges,
            ChangeType.modified,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemAdditionalInfo(BuildContext context, Map<String, dynamic> additionalInfo, int dayIndex, int itemIndex) {
    final hasAdditionalInfoChanges = diffResult.getChangesForItem(dayIndex, itemIndex)
        .any((change) => change.path == 'days[$dayIndex].items[$itemIndex].additionalInfo');
    
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: hasAdditionalInfoChanges ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: hasAdditionalInfoChanges ? Colors.green[200]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: additionalInfo.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '${entry.key}: ${entry.value}',
              style: TextStyle(
                fontSize: 11,
                color: hasAdditionalInfoChanges ? Colors.green[800] : Colors.grey[600],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHighlightedText(
    BuildContext context,
    String text,
    String fieldName,
    bool hasChanges,
    ChangeType changeType, {
    TextStyle? style,
  }) {
    if (!hasChanges) {
      return Text(text, style: style);
    }

    Color highlightColor;
    IconData icon;
    
    switch (changeType) {
      case ChangeType.added:
        highlightColor = Colors.green;
        icon = Icons.add;
        break;
      case ChangeType.removed:
        highlightColor = Colors.red;
        icon = Icons.remove;
        break;
      case ChangeType.modified:
        highlightColor = Colors.orange;
        icon = Icons.edit;
        break;
      case ChangeType.moved:
        highlightColor = Colors.purple;
        icon = Icons.swap_vert;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: highlightColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: highlightColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: highlightColor.withOpacity(0.7)),
          const SizedBox(width: 4),
          Text(
            text,
            style: style?.copyWith(color: highlightColor.withOpacity(0.8)) ?? 
                   TextStyle(color: highlightColor.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onAcceptChanges,
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Accept Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onRejectChanges,
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Reject Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget for displaying change details
class ChangeDetailsWidget extends StatelessWidget {
  final ItineraryDiffResult diffResult;

  const ChangeDetailsWidget({
    super.key,
    required this.diffResult,
  });

  @override
  Widget build(BuildContext context) {
    if (!diffResult.hasChanges) {
      return const Center(
        child: Text('No changes detected'),
      );
    }

    return ListView.builder(
      itemCount: diffResult.diff!.changes.length,
      itemBuilder: (context, index) {
        final change = diffResult.diff!.changes[index];
        return _buildChangeItem(context, change);
      },
    );
  }

  Widget _buildChangeItem(BuildContext context, ItineraryChange change) {
    Color color;
    IconData icon;
    
    switch (change.type) {
      case ChangeType.added:
        color = Colors.green;
        icon = Icons.add_circle;
        break;
      case ChangeType.removed:
        color = Colors.red;
        icon = Icons.remove_circle;
        break;
      case ChangeType.modified:
        color = Colors.orange;
        icon = Icons.edit;
        break;
      case ChangeType.moved:
        color = Colors.purple;
        icon = Icons.swap_vert;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          change.description,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Path: ${change.path}'),
            if (change.oldValue != null)
              Text('Old: ${change.oldValue}'),
            if (change.newValue != null)
              Text('New: ${change.newValue}'),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
