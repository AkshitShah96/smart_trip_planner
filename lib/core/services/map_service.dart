import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class MapService {
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













