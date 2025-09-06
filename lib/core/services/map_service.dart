import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapService {
  // Google Maps API Key - should be set via environment variables
  static const String _googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');
  
  /// Get Google Maps API Key
  static String get googleMapsApiKey => _googleMapsApiKey;
  
  /// Check if Google Maps API Key is configured
  static bool get isApiKeyConfigured => _googleMapsApiKey.isNotEmpty;

  static Future<bool> openLocation(String location) async {
    try {
      if (_isCoordinateFormat(location)) {
        final coords = _parseCoordinates(location);
        if (coords != null) {
          return await _openWithCoordinates(coords.latitude, coords.longitude);
        }
      }
      
      return await _openWithAddress(location);
    } catch (e) {
      print('Error opening map: $e');
      return false;
    }
  }

  static Future<bool> openGoogleMaps(double latitude, double longitude, {String? label}) async {
    final String encodedLabel = label != null ? '&query=' + Uri.encodeComponent(label) : '';
    final String url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude$encodedLabel';
    
    return await _launchUrl(url);
  }

  /// Open Google Maps with directions to a location
  static Future<bool> openGoogleMapsDirections({
    required double destinationLat,
    required double destinationLng,
    double? originLat,
    double? originLng,
    String? destinationLabel,
    String? originLabel,
  }) async {
    String url = 'https://www.google.com/maps/dir/';
    
    if (originLat != null && originLng != null) {
      final originLabelParam = originLabel != null ? '/$originLabel' : '';
      url += '$originLat,$originLng$originLabelParam/';
    }
    
    final destinationLabelParam = destinationLabel != null ? '/$destinationLabel' : '';
    url += '$destinationLat,$destinationLng$destinationLabelParam';
    
    return await _launchUrl(url);
  }

  /// Open Google Maps with multiple waypoints
  static Future<bool> openGoogleMapsWithWaypoints({
    required List<MapLocation> waypoints,
    String? label,
  }) async {
    if (waypoints.isEmpty) return false;
    
    String url = 'https://www.google.com/maps/dir/';
    
    for (int i = 0; i < waypoints.length; i++) {
      final waypoint = waypoints[i];
      final labelParam = waypoint.label != null ? '/${Uri.encodeComponent(waypoint.label!)}' : '';
      url += '${waypoint.latitude},${waypoint.longitude}$labelParam';
      
      if (i < waypoints.length - 1) {
        url += '/';
      }
    }
    
    return await _launchUrl(url);
  }

  static Future<bool> openAppleMaps(double latitude, double longitude, {String? label}) async {
    final String encodedLabel = label != null ? Uri.encodeComponent(label) : '';
    final String url = 'http://maps.apple.com/?q=$encodedLabel&ll=$latitude,$longitude';
    
    return await _launchUrl(url);
  }

  static Future<bool> _openWithCoordinates(double latitude, double longitude) async {
    if (Platform.isIOS) {
      if (await openAppleMaps(latitude, longitude)) {
        return true;
      }
      return await openGoogleMaps(latitude, longitude);
    } else {
      if (await openGoogleMaps(latitude, longitude)) {
        return true;
      }
      return await _launchUrl('geo:$latitude,$longitude');
    }
  }

  static Future<bool> _openWithAddress(String address) async {
    final String encodedAddress = Uri.encodeComponent(address);
    
    if (Platform.isIOS) {
      final String appleMapsUrl = 'http://maps.apple.com/?q=$encodedAddress';
      if (await _launchUrl(appleMapsUrl)) {
        return true;
      }
    }
    
    final String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
    return await _launchUrl(googleMapsUrl);
  }

  static Future<bool> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      print('Error launching URL: $e');
      return false;
    }
  }

  static bool _isCoordinateFormat(String location) {
    final RegExp coordPattern = RegExp(r'^-?\d+\.?\d*,\s*-?\d+\.?\d*$');
    return coordPattern.hasMatch(location.trim());
  }

  static Coordinates? _parseCoordinates(String location) {
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
}

class Coordinates {
  final double latitude;
  final double longitude;

  const Coordinates(this.latitude, this.longitude);

  @override
  String toString() => '$latitude,$longitude';
}

class MapLocation {
  final double latitude;
  final double longitude;
  final String? label;
  final String? address;

  const MapLocation({
    required this.latitude,
    required this.longitude,
    this.label,
    this.address,
  });

  @override
  String toString() => label ?? address ?? '$latitude,$longitude';
}

/// Enhanced map functionality for itinerary locations
class EnhancedMapService {
  /// Create a Google Maps URL with embedded map for web
  static String createEmbeddedMapUrl({
    required double latitude,
    required double longitude,
    String? label,
    int zoom = 15,
    String mapType = 'roadmap',
  }) {
    final encodedLabel = label != null ? Uri.encodeComponent(label) : '';
    final query = encodedLabel.isNotEmpty ? '&q=$encodedLabel' : '';
    
    return 'https://www.google.com/maps/embed/v1/view?key=${MapService.googleMapsApiKey}&center=$latitude,$longitude&zoom=$zoom&maptype=$mapType$query';
  }

  /// Create a static map image URL
  static String createStaticMapUrl({
    required double latitude,
    required double longitude,
    String? label,
    int width = 400,
    int height = 300,
    int zoom = 15,
    String mapType = 'roadmap',
  }) {
    final encodedLabel = label != null ? Uri.encodeComponent(label) : '';
    final markers = encodedLabel.isNotEmpty 
        ? '&markers=color:red%7Clabel:$encodedLabel%7C$latitude,$longitude'
        : '&markers=color:red%7C$latitude,$longitude';
    
    return 'https://maps.googleapis.com/maps/api/staticmap?center=$latitude,$longitude&zoom=$zoom&size=${width}x$height&maptype=$mapType$markers&key=${MapService.googleMapsApiKey}';
  }

  /// Generate directions URL between multiple points
  static String createDirectionsUrl({
    required List<MapLocation> waypoints,
    String? originLabel,
    String? destinationLabel,
  }) {
    if (waypoints.isEmpty) return '';
    
    String url = 'https://www.google.com/maps/dir/';
    
    // Add origin
    if (waypoints.isNotEmpty) {
      final origin = waypoints.first;
      final originLabelParam = originLabel != null ? '/${Uri.encodeComponent(originLabel)}' : '';
      url += '${origin.latitude},${origin.longitude}$originLabelParam';
    }
    
    // Add waypoints
    for (int i = 1; i < waypoints.length - 1; i++) {
      final waypoint = waypoints[i];
      url += '/${waypoint.latitude},${waypoint.longitude}';
    }
    
    // Add destination
    if (waypoints.length > 1) {
      final destination = waypoints.last;
      final destLabelParam = destinationLabel != null ? '/${Uri.encodeComponent(destinationLabel)}' : '';
      url += '/${destination.latitude},${destination.longitude}$destLabelParam';
    }
    
    return url;
  }

  /// Create a map widget configuration for Flutter
  static MapConfiguration createMapConfiguration({
    required double latitude,
    required double longitude,
    String? title,
    int zoom = 15,
    List<MapLocation>? additionalMarkers,
  }) {
    final markers = <Marker>{
      Marker(
        markerId: MarkerId('main_location'),
        position: LatLng(latitude, longitude),
        infoWindow: InfoWindow(
          title: title ?? 'Location',
          snippet: '$latitude, $longitude',
        ),
      ),
    };

    if (additionalMarkers != null) {
      for (int i = 0; i < additionalMarkers.length; i++) {
        final marker = additionalMarkers[i];
        markers.add(
          Marker(
            markerId: MarkerId('marker_$i'),
            position: LatLng(marker.latitude, marker.longitude),
            infoWindow: InfoWindow(
              title: marker.label ?? 'Waypoint ${i + 1}',
              snippet: marker.address ?? '${marker.latitude}, ${marker.longitude}',
            ),
          ),
        );
      }
    }

    return MapConfiguration(
      initialCameraPosition: CameraPosition(
        target: LatLng(latitude, longitude),
        zoom: zoom.toDouble(),
      ),
      markers: markers,
    );
  }

  /// Validate coordinates
  static bool isValidCoordinate(double latitude, double longitude) {
    return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;
  }

  /// Calculate distance between two coordinates (in kilometers)
  static double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = (dLat / 2).sin() * (dLat / 2).sin() +
        lat1.cos() * lat2.cos() * (dLon / 2).sin() * (dLon / 2).sin();
    final double c = 2 * (a.sqrt()).asin();
    
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }
}

/// Configuration for map widget
class MapConfiguration {
  final CameraPosition initialCameraPosition;
  final Set<Marker> markers;
  final MapType mapType;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool zoomControlsEnabled;
  final bool compassEnabled;
  final bool mapToolbarEnabled;

  const MapConfiguration({
    required this.initialCameraPosition,
    required this.markers,
    this.mapType = MapType.normal,
    this.myLocationEnabled = true,
    this.myLocationButtonEnabled = true,
    this.zoomControlsEnabled = true,
    this.compassEnabled = true,
    this.mapToolbarEnabled = true,
  });
}













