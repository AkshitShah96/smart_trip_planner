# Google Maps Integration & Token Usage Analytics

This document describes the newly implemented Google Maps integration and comprehensive token usage analytics features in the Smart Trip Planner app.

## 🗺️ Google Maps Integration

### Features Implemented

#### 1. **Enhanced Map Service**
- **Location Parsing**: Automatically detects coordinate format vs. address format
- **Multi-Platform Support**: Works on Android, iOS, and Web
- **Multiple Map Providers**: Google Maps, Apple Maps, and fallback options
- **Directions Support**: Generate directions between multiple waypoints
- **Distance Calculation**: Calculate distances between coordinates

#### 2. **Interactive Map Widgets**
- **LocationMapWidget**: Full-featured map with markers and controls
- **CompactLocationWidget**: Lightweight widget for itinerary items
- **StaticMapWidget**: Web-compatible static map images

#### 3. **Itinerary Integration**
- **Clickable Locations**: All itinerary locations are now clickable
- **Coordinate Detection**: Automatically detects and displays coordinates
- **Map Integration**: Seamless integration with existing itinerary display
- **Fallback Support**: Graceful handling of non-coordinate locations

### Setup Instructions

#### 1. **Get Google Maps API Key**
```bash
# Run the setup script
setup_google_maps.bat
```

Or manually:
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create/select a project
3. Enable APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Maps JavaScript API
   - Static Maps API
   - Embed Maps API
4. Create API Key in "APIs & Services" > "Credentials"

#### 2. **Configure API Key**
```bash
# Run with API key
flutter run -d chrome --dart-define=GOOGLE_MAPS_API_KEY=your_api_key_here
```

#### 3. **Platform-Specific Configuration**

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

**iOS** (`ios/Runner/AppDelegate.swift`):
```swift
import GoogleMaps
GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
```

### Usage Examples

#### Basic Location Opening
```dart
// Open location in maps
await MapService.openLocation("34.9671,135.7727");
await MapService.openLocation("Kyoto, Japan");
```

#### Directions Between Points
```dart
// Open directions
await MapService.openGoogleMapsDirections(
  destinationLat: 34.9671,
  destinationLng: 135.7727,
  destinationLabel: "Fushimi Inari Shrine",
);
```

#### Interactive Map Widget
```dart
LocationMapWidget(
  latitude: 34.9671,
  longitude: 135.7727,
  title: "Fushimi Inari Shrine",
  address: "68 Fukakusa Yabunouchicho, Fushimi Ward, Kyoto",
)
```

## 📊 Token Usage Analytics

### Features Implemented

#### 1. **Comprehensive Token Tracking**
- **Request Tokens**: Track input tokens sent to AI
- **Response Tokens**: Track output tokens received from AI
- **Session Tracking**: Monitor current session usage
- **Total Usage**: Track cumulative usage across all sessions
- **Cost Estimation**: Real-time cost calculations

#### 2. **Token Usage Page**
- **Overview Dashboard**: Visual summary of token usage
- **Session Analytics**: Current session breakdown
- **Cost Analysis**: Detailed cost calculations with pricing
- **Usage Patterns**: Efficiency ratios and averages
- **Settings Management**: Debug mode and overlay controls

#### 3. **Debug Overlay**
- **Real-time Display**: Floating overlay showing current usage
- **Quick Access**: Easy toggle for debug mode
- **Cost Awareness**: Immediate cost feedback
- **Navigation**: Direct link to detailed analytics

### Navigation Integration

The token usage page is now accessible through:
- **Bottom Navigation**: New "Analytics" tab
- **Debug Overlay**: "View Details" button
- **Direct Navigation**: Programmatic access

### Usage Examples

#### Track Token Usage
```dart
// Add token usage
ref.read(tokenUsageProvider.notifier).addTokenUsage(
  requestTokens: 150,
  responseTokens: 300,
);
```

#### Toggle Debug Mode
```dart
// Enable debug overlay
ref.read(tokenUsageProvider.notifier).setDebugMode(true);
```

#### Reset Usage Data
```dart
// Reset current session
ref.read(tokenUsageProvider.notifier).resetCurrentSession();

// Reset all data
ref.read(tokenUsageProvider.notifier).resetAllUsage();
```

## 🔧 Technical Implementation

### Architecture

#### Map Service Architecture
```
MapService (Core)
├── EnhancedMapService (Advanced features)
├── LocationMapWidget (UI Component)
├── CompactLocationWidget (UI Component)
└── StaticMapWidget (Web compatibility)
```

#### Token Analytics Architecture
```
TokenUsageProvider (State Management)
├── TokenUsagePage (UI)
├── TokenUsageOverlay (Debug UI)
└── TokenUsageData (Data Model)
```

### Key Classes

#### MapService
- `openLocation()`: Open any location in maps
- `openGoogleMapsDirections()`: Generate directions
- `openGoogleMapsWithWaypoints()`: Multi-point routes

#### EnhancedMapService
- `createEmbeddedMapUrl()`: Web-embedded maps
- `createStaticMapUrl()`: Static map images
- `createMapConfiguration()`: Flutter map setup
- `calculateDistance()`: Distance calculations

#### TokenUsageNotifier
- `addTokenUsage()`: Track new usage
- `resetCurrentSession()`: Clear session data
- `toggleDebugMode()`: Toggle debug overlay
- `setOverlayVisible()`: Control overlay visibility

## 🚀 Getting Started

### 1. **Install Dependencies**
```bash
flutter pub get
```

### 2. **Setup Google Maps**
```bash
# Run setup script
setup_google_maps.bat

# Or manually configure API key
flutter run -d chrome --dart-define=GOOGLE_MAPS_API_KEY=your_key
```

### 3. **Test Features**
```bash
# Run the app
flutter run -d chrome

# Navigate to Analytics tab to see token usage
# Tap on itinerary locations to test maps integration
```

## 📱 User Experience

### Maps Integration
- **Seamless Integration**: Maps work within the existing UI
- **Multiple Options**: Click locations for map actions
- **Cross-Platform**: Consistent experience across platforms
- **Fallback Support**: Graceful handling of unsupported features

### Token Analytics
- **Real-time Feedback**: Immediate cost awareness
- **Detailed Insights**: Comprehensive usage analysis
- **User Control**: Easy reset and management options
- **Debug Support**: Developer-friendly debugging tools

## 🔒 Security & Best Practices

### API Key Security
- **Environment Variables**: API keys via `--dart-define`
- **No Hardcoding**: Keys never stored in source code
- **Restriction Support**: Configure key restrictions in Google Cloud
- **Monitoring**: Track usage in Google Cloud Console

### Token Usage Privacy
- **Local Storage**: All data stored locally
- **No External Sharing**: Data never sent to external services
- **User Control**: Complete control over data reset
- **Transparent Pricing**: Clear cost calculations

## 🎯 Future Enhancements

### Maps Features
- **Offline Maps**: Cache maps for offline use
- **Custom Markers**: Personalized location markers
- **Route Optimization**: AI-powered route suggestions
- **Real-time Traffic**: Live traffic integration

### Analytics Features
- **Usage Trends**: Historical usage patterns
- **Budget Alerts**: Set spending limits
- **Export Data**: Download usage reports
- **Team Analytics**: Multi-user usage tracking

## 📞 Support

For issues or questions:
1. Check the setup scripts for configuration help
2. Review the Google Maps API documentation
3. Test with the provided examples
4. Use the debug overlay for troubleshooting

---

**Note**: This implementation provides a solid foundation for maps integration and token analytics. The modular architecture allows for easy extension and customization based on specific requirements.
