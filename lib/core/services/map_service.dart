import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class MapService {
  /// Opens the location in the default map app (Google Maps on Android, Apple Maps on iOS)
  static Future<bool> openLocation(String location) async {
    try {
      // Check if location contains coordinates
      if (_isCoordinateFormat(location)) {
        final coords = _parseCoordinates(location);
        if (coords != null) {
          return await _openWithCoordinates(coords.latitude, coords.longitude);
        }
      }
      
      // If not coordinates, try to open as address
      return await _openWithAddress(location);
    } catch (e) {
      print('Error opening map: $e');
      return false;
    }
  }

  /// Opens Google Maps with coordinates
  static Future<bool> openGoogleMaps(double latitude, double longitude, {String? label}) async {
    final String encodedLabel = label != null ? Uri.encodeComponent(label) : '';
    final String url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude$encodedLabel';
    
    return await _launchUrl(url);
  }

  /// Opens Apple Maps with coordinates
  static Future<bool> openAppleMaps(double latitude, double longitude, {String? label}) async {
    final String encodedLabel = label != null ? Uri.encodeComponent(label) : '';
    final String url = 'http://maps.apple.com/?q=$encodedLabel&ll=$latitude,$longitude';
    
    return await _launchUrl(url);
  }

  /// Opens the default map app with coordinates
  static Future<bool> _openWithCoordinates(double latitude, double longitude) async {
    if (Platform.isIOS) {
      // Try Apple Maps first on iOS
      if (await openAppleMaps(latitude, longitude)) {
        return true;
      }
      // Fallback to Google Maps
      return await openGoogleMaps(latitude, longitude);
    } else {
      // Try Google Maps first on Android
      if (await openGoogleMaps(latitude, longitude)) {
        return true;
      }
      // Fallback to generic maps URL
      return await _launchUrl('geo:$latitude,$longitude');
    }
  }

  /// Opens the default map app with an address
  static Future<bool> _openWithAddress(String address) async {
    final String encodedAddress = Uri.encodeComponent(address);
    
    if (Platform.isIOS) {
      // Try Apple Maps first on iOS
      final String appleMapsUrl = 'http://maps.apple.com/?q=$encodedAddress';
      if (await _launchUrl(appleMapsUrl)) {
        return true;
      }
    }
    
    // Fallback to Google Maps
    final String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
    return await _launchUrl(googleMapsUrl);
  }

  /// Launches a URL
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

  /// Checks if the location string is in coordinate format (lat,lng)
  static bool _isCoordinateFormat(String location) {
    // Check for patterns like "34.9671,135.7727" or "34.9671, 135.7727"
    final RegExp coordPattern = RegExp(r'^-?\d+\.?\d*,\s*-?\d+\.?\d*$');
    return coordPattern.hasMatch(location.trim());
  }

  /// Parses coordinates from a string
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

/// Simple class to hold coordinates
class Coordinates {
  final double latitude;
  final double longitude;

  const Coordinates(this.latitude, this.longitude);

  @override
  String toString() => '$latitude,$longitude';
}










