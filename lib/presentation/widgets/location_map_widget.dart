import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/map_service.dart';

class LocationMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? title;
  final String? address;
  final int zoom;
  final bool showControls;
  final bool showDirectionsButton;
  final List<MapLocation>? additionalMarkers;

  const LocationMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.title,
    this.address,
    this.zoom = 15,
    this.showControls = true,
    this.showDirectionsButton = true,
    this.additionalMarkers,
  });

  @override
  State<LocationMapWidget> createState() => _LocationMapWidgetState();
}

class _LocationMapWidgetState extends State<LocationMapWidget> {
  GoogleMapController? _mapController;
  late Set<Marker> _markers;

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
  }

  void _initializeMarkers() {
    _markers = <Marker>{
      Marker(
        markerId: const MarkerId('main_location'),
        position: LatLng(widget.latitude, widget.longitude),
        infoWindow: InfoWindow(
          title: widget.title ?? 'Location',
          snippet: widget.address ?? '${widget.latitude}, ${widget.longitude}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    if (widget.additionalMarkers != null) {
      for (int i = 0; i < widget.additionalMarkers!.length; i++) {
        final marker = widget.additionalMarkers![i];
        _markers.add(
          Marker(
            markerId: MarkerId('marker_$i'),
            position: LatLng(marker.latitude, marker.longitude),
            infoWindow: InfoWindow(
              title: marker.label ?? 'Waypoint ${i + 1}',
              snippet: marker.address ?? '${marker.latitude}, ${marker.longitude}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title ?? 'Location',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.address != null)
                        Text(
                          widget.address!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.showDirectionsButton)
                  IconButton(
                    icon: const Icon(Icons.directions),
                    onPressed: _openDirections,
                    tooltip: 'Open Directions',
                  ),
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: _openInMaps,
                  tooltip: 'Open in Maps',
                ),
              ],
            ),
          ),
          // Map
          SizedBox(
            height: 200,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: MapService.isApiKeyConfigured
                  ? GoogleMap(
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                      initialCameraPosition: CameraPosition(
                        target: LatLng(widget.latitude, widget.longitude),
                        zoom: widget.zoom.toDouble(),
                      ),
                      markers: _markers,
                      mapType: MapType.normal,
                      myLocationEnabled: widget.showControls,
                      myLocationButtonEnabled: widget.showControls,
                      zoomControlsEnabled: widget.showControls,
                      compassEnabled: widget.showControls,
                      mapToolbarEnabled: widget.showControls,
                      onTap: _onMapTapped,
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              size: 48,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Google Maps API Key Required',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Configure GOOGLE_MAPS_API_KEY',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _onMapTapped(LatLng position) {
    // Show info about the tapped location
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Latitude: ${position.latitude.toStringAsFixed(6)}'),
            Text('Longitude: ${position.longitude.toStringAsFixed(6)}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _openInMaps();
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Maps'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _openDirections();
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Directions'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openInMaps() async {
    final success = await MapService.openGoogleMaps(
      widget.latitude,
      widget.longitude,
      label: widget.title,
    );
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open maps. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _openDirections() async {
    final success = await MapService.openGoogleMapsDirections(
      destinationLat: widget.latitude,
      destinationLng: widget.longitude,
      destinationLabel: widget.title,
    );
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open directions. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

/// Compact map widget for itinerary items
class CompactLocationWidget extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? title;
  final String? address;
  final VoidCallback? onTap;

  const CompactLocationWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.title,
    this.address,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap ?? () => _openInMaps(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? 'Location',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (address != null)
                    Text(
                      address!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  Text(
                    '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new,
              color: theme.colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _openInMaps(BuildContext context) async {
    final success = await MapService.openGoogleMaps(
      latitude,
      longitude,
      label: title,
    );
    
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open maps. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

/// Static map image widget for web compatibility
class StaticMapWidget extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? title;
  final int width;
  final int height;
  final int zoom;

  const StaticMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.title,
    this.width = 400,
    this.height = 200,
    this.zoom = 15,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.map,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              EnhancedMapService.createStaticMapUrl(
                latitude: latitude,
                longitude: longitude,
                label: title,
                width: width,
                height: height,
                zoom: zoom,
              ),
              width: width.toDouble(),
              height: height.toDouble(),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: width.toDouble(),
                  height: height.toDouble(),
                  color: theme.colorScheme.surfaceVariant,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Map unavailable',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
