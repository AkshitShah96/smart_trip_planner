import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/itinerary.dart';
import '../../domain/entities/day_plan.dart';
import '../../domain/entities/day_item.dart';
import '../../core/services/map_service.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/location_map_widget.dart';
import '../widgets/planet_ai_avatar.dart';
import '../providers/chat_providers.dart';

class EnhancedItineraryDetailScreen extends ConsumerStatefulWidget {
  final Itinerary itinerary;

  const EnhancedItineraryDetailScreen({
    super.key,
    required this.itinerary,
  });

  @override
  ConsumerState<EnhancedItineraryDetailScreen> createState() => _EnhancedItineraryDetailScreenState();
}

class _EnhancedItineraryDetailScreenState extends ConsumerState<EnhancedItineraryDetailScreen>
    with TickerProviderStateMixin {
  final Set<int> _expandedDays = {0};
  late AnimationController _successAnimationController;
  late Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();
    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _successAnimation = CurvedAnimation(
      parent: _successAnimationController,
      curve: Curves.elasticOut,
    );
    _successAnimationController.forward();
  }

  @override
  void dispose() {
    _successAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSuccessHeader(context),
                  _buildMainItineraryCard(context),
                  _buildDaysList(context),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
          _buildBottomActionBar(context),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text('Home'),
      backgroundColor: AppTheme.white,
      elevation: 0,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF4CAF50),
            child: Text(
              'S',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: ScaleTransition(
        scale: _successAnimation,
        child: Column(
          children: [
            const Text(
              '🌴',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Itinerary Created',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainItineraryCard(BuildContext context) {
    final firstDay = widget.itinerary.days.isNotEmpty ? widget.itinerary.days.first : null;
    if (firstDay == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const PlanetAiAvatar(size: 40, showAnimation: false),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Day 1: ${_getDayTitle(firstDay)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.itinerary.days.length} days planned',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.white,
                              opacity: 0.9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Activities List
                ...firstDay.items.map((item) => _buildActivityListItem(item)),
                
                const SizedBox(height: 24),
                
                // Map Integration
                _buildMapIntegration(context, firstDay),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityListItem(DayItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 16),
            decoration: const BoxDecoration(
              color: AppTheme.primaryTeal,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.time}: ${item.activity}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
                if (item.location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.location,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapIntegration(BuildContext context, DayPlan day) {
    final firstLocation = day.items.isNotEmpty ? day.items.first.location : '';
    final lastLocation = day.items.length > 1 ? day.items.last.location : firstLocation;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.softGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.mediumGray.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: AppTheme.primaryTeal,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Open in maps',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryTeal,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.open_in_new_rounded,
                color: AppTheme.primaryTeal,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _getRouteDisplay(firstLocation, lastLocation),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getEstimatedTravelTime(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryTeal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDaysList(BuildContext context) {
    if (widget.itinerary.days.length <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Complete Itinerary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.itinerary.days.asMap().entries.skip(1).map((entry) {
            final index = entry.key;
            final day = entry.value;
            return _buildCollapsibleDayCard(context, index, day);
          }),
        ],
      ),
    );
  }

  Widget _buildCollapsibleDayCard(BuildContext context, int dayIndex, DayPlan day) {
    final isExpanded = _expandedDays.contains(dayIndex);
    final dayNumber = dayIndex + 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedDays.remove(dayIndex);
                  } else {
                    _expandedDays.add(dayIndex);
                  }
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$dayNumber',
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Day $dayNumber: ${_getDayTitle(day)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            day.date,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded 
                          ? Icons.keyboard_arrow_up_rounded 
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textSecondary,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: AppTheme.mediumGray),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (day.summary.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTeal,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_rounded,
                            color: AppTheme.primaryTeal,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              day.summary,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.primaryTeal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ...day.items.map((item) => _buildActivityItem(context, item)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, DayItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.softGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.mediumGray.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  item.time,
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.activity,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLocationWidget(item),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationWidget(DayItem item) {
    if (_isCoordinateFormat(item.location)) {
      final coords = _parseCoordinates(item.location);
      if (coords != null) {
        return CompactLocationWidget(
          latitude: coords.latitude,
          longitude: coords.longitude,
          title: item.activity,
          address: item.location,
          onTap: () => _openLocationInMap(context, item.location, item.activity),
        );
      }
    }
    
    return InkWell(
      onTap: () => _openLocationInMap(context, item.location, item.activity),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.mediumGray.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_rounded,
              size: 16,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                item.location,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.open_in_new,
              size: 14,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Follow up button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _followUpToRefine(context),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Follow up to refine'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Save offline button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _saveOffline(context),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Save Offline'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryTeal,
                  side: const BorderSide(color: AppTheme.primaryTeal),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayTitle(DayPlan day) {
    if (day.items.isNotEmpty) {
      final firstActivity = day.items.first.activity;
      if (firstActivity.toLowerCase().contains('arrival')) {
        return 'Arrival & Settle In';
      } else if (firstActivity.toLowerCase().contains('departure')) {
        return 'Departure Day';
      }
    }
    return 'Day Activities';
  }

  String _getRouteDisplay(String firstLocation, String lastLocation) {
    if (firstLocation.isEmpty && lastLocation.isEmpty) {
      return 'Route information not available';
    }
    
    final origin = _getLocationName(firstLocation);
    final destination = _getLocationName(lastLocation);
    
    if (origin == destination) {
      return destination;
    }
    
    return '$origin to $destination';
  }

  String _getLocationName(String location) {
    if (location.isEmpty) return 'Unknown Location';
    
    // Extract city/country from location string
    if (location.contains(',')) {
      final parts = location.split(',');
      if (parts.length >= 2) {
        return '${parts[0].trim()}, ${parts[1].trim()}';
      }
    }
    
    return location;
  }

  String _getEstimatedTravelTime() {
    // Mock travel time calculation
    final dayCount = widget.itinerary.days.length;
    if (dayCount <= 1) return 'Local travel';
    if (dayCount <= 3) return '2-4 hours';
    if (dayCount <= 7) return '4-8 hours';
    return '8+ hours';
  }

  bool _isCoordinateFormat(String location) {
    final RegExp coordPattern = RegExp(r'^-?\d+\.?\d*,\s*-?\d+\.?\d*$');
    return coordPattern.hasMatch(location.trim());
  }

  Coordinates? _parseCoordinates(String location) {
    try {
      final parts = location.split(',');
      if (parts.length == 2) {
        final lat = double.parse(parts[0].trim());
        final lng = double.parse(parts[1].trim());
        return Coordinates(lat, lng);
      }
    } catch (e) {
      print('Error parsing coordinates: $e');
    }
    return null;
  }

  Future<void> _openLocationInMap(BuildContext context, String location, String activityName) async {
    try {
      final success = await MapService.openLocation(location);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open map for $activityName'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening map: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _followUpToRefine(BuildContext context) {
    // Navigate to chat page with pre-filled message
    Navigator.of(context).pushNamed('/chat');
    
    // Send a follow-up message to the chat
    Future.delayed(const Duration(milliseconds: 500), () {
      ref.read(chatProvider.notifier).sendMessage(
        'I\'d like to refine my ${widget.itinerary.title} itinerary. Can you help me make some adjustments?'
      );
    });
  }

  void _saveOffline(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Itinerary saved offline successfully!'),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates(this.latitude, this.longitude);
}

