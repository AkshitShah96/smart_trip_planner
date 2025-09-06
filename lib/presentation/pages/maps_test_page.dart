import 'package:flutter/material.dart';
import '../widgets/location_map_widget.dart';
import '../../core/services/map_service.dart';

class MapsTestPage extends StatelessWidget {
  const MapsTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maps Integration Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Google Maps Integration Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Test 1: Full Map Widget
            const Text(
              '1. Full Interactive Map Widget',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            LocationMapWidget(
              latitude: 34.9671,
              longitude: 135.7727,
              title: 'Fushimi Inari Shrine',
              address: '68 Fukakusa Yabunouchicho, Fushimi Ward, Kyoto',
            ),
            const SizedBox(height: 20),
            
            // Test 2: Compact Location Widget
            const Text(
              '2. Compact Location Widget (for itinerary items)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            CompactLocationWidget(
              latitude: 35.0047,
              longitude: 135.7630,
              title: 'Nishiki Market',
              address: 'Nishiki Market, Nakagyo Ward, Kyoto',
            ),
            const SizedBox(height: 20),
            
            // Test 3: Static Map Widget
            const Text(
              '3. Static Map Widget (web compatible)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            StaticMapWidget(
              latitude: 35.0037,
              longitude: 135.7788,
              title: 'Gion District',
              width: 400,
              height: 200,
            ),
            const SizedBox(height: 20),
            
            // Test 4: Map Service Functions
            const Text(
              '4. Map Service Functions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () => _testOpenLocation(),
                  child: const Text('Open Location in Maps'),
                ),
                ElevatedButton(
                  onPressed: () => _testOpenDirections(),
                  child: const Text('Open Directions'),
                ),
                ElevatedButton(
                  onPressed: () => _testDistanceCalculation(),
                  child: const Text('Calculate Distance'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Test 5: Coordinate Format Detection
            const Text(
              '5. Coordinate Format Detection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Valid coordinate formats:'),
                  const SizedBox(height: 5),
                  const Text('• 34.9671,135.7727'),
                  const Text('• 35.0047, 135.7630'),
                  const Text('• -122.4194, 37.7749'),
                  const SizedBox(height: 10),
                  const Text('Invalid formats (will show as text):'),
                  const SizedBox(height: 5),
                  const Text('• Kyoto, Japan'),
                  const Text('• Fushimi Inari Shrine'),
                  const Text('• Downtown Tokyo'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _testOpenLocation() async {
    final success = await MapService.openLocation('34.9671,135.7727');
    print('Open location result: $success');
  }

  void _testOpenDirections() async {
    final success = await MapService.openGoogleMapsDirections(
      destinationLat: 34.9671,
      destinationLng: 135.7727,
      destinationLabel: 'Fushimi Inari Shrine',
    );
    print('Open directions result: $success');
  }

  void _testDistanceCalculation() {
    final distance = EnhancedMapService.calculateDistance(
      34.9671, 135.7727, // Kyoto
      35.6762, 139.6503, // Tokyo
    );
    print('Distance between Kyoto and Tokyo: ${distance.toStringAsFixed(2)} km');
  }
}

