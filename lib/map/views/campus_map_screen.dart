import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CampusMapScreen extends StatefulWidget {
  const CampusMapScreen({super.key});

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  bool _showBoundary = true; // Toggle state for polygon visibility

  // CITK Campus coordinates
  static const LatLng _citkCenter = LatLng(26.4700, 90.2700);

  final Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId('library'),
      position: LatLng(26.4710, 90.2710),
      infoWindow: InfoWindow(title: 'Central Library'),
    ),
    const Marker(
      markerId: MarkerId('admin'),
      position: LatLng(26.4705, 90.2705),
      infoWindow: InfoWindow(title: 'Administrative Block'),
    ),
  };

  // 🏟️ CAMPUS BOUNDARY (Polygon marking the whole area) - Getter based on state
  Set<Polygon> get _polygons {
    if (!_showBoundary) return {};
    return {
      Polygon(
        polygonId: const PolygonId('citk_campus_area'),
        points: const [
          LatLng(26.4745, 90.2660), // NW Corner (Near Hostels)
          LatLng(26.4750, 90.2710), // North Boundary
          LatLng(26.4735, 90.2745), // NE Corner (Near Faculty Quarters)
          LatLng(26.4690, 90.2750), // East Boundary
          LatLng(26.4660, 90.2720), // SE Corner (Main Gate Area)
          LatLng(26.4655, 90.2680), // South Boundary
          LatLng(26.4670, 90.2650), // SW Corner
          LatLng(26.4710, 90.2645), // West Boundary
        ],
        strokeWidth: 2,
        strokeColor: const Color(0xFF4285F4),
        fillColor: const Color(0xFF4285F4).withValues(alpha: 0.15),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campus Map')),
      body: GoogleMap(
        // 🛰️ SATELLITE VIEW (Hybrid shows labels too)
        mapType: MapType.hybrid,
        initialCameraPosition: const CameraPosition(
          target: _citkCenter,
          zoom: 16,
        ),
        markers: _markers,
        polygons: _polygons,
        myLocationEnabled: true,
        onMapCreated: (controller) {},
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => _showBoundary = !_showBoundary),
        label: Text(_showBoundary ? 'Hide Boundary' : 'Show Boundary'),
        icon: Icon(_showBoundary ? Icons.layers_clear : Icons.layers),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}
