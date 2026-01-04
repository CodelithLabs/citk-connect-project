import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CampusMapScreen extends StatefulWidget {
  const CampusMapScreen({super.key});

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  // 1. CITK Coordinates (Approximate Center)
  static const CameraPosition _citkCampus = CameraPosition(
    target: LatLng(26.4795, 90.2640), // Check these coords for your specific campus spot
    zoom: 17.0, // Zoomed in to see buildings
    tilt: 45.0, // 45 degree tilt for 3D effect!
  );

  // 2. Markers for Important Spots
  final Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId('main_gate'),
      position: LatLng(26.4795, 90.2640),
      infoWindow: InfoWindow(title: 'Main Gate', snippet: 'Welcome to CITK'),
    ),
    const Marker(
      markerId: MarkerId('library'),
      position: LatLng(26.4800, 90.2645), // Adjust these slightly
      infoWindow: InfoWindow(title: 'Central Library', snippet: 'Open 9AM - 8PM'),
    ),
    const Marker(
      markerId: MarkerId('rnb_hostel'),
      position: LatLng(26.4785, 90.2635),
      infoWindow: InfoWindow(title: 'RNB Hostel', snippet: 'Boys Hostel'),
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // THE GOOGLE MAP
          GoogleMap(
            mapType: MapType.hybrid, // Satellite + Roads looks best for Hackathons
            initialCameraPosition: _citkCampus,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            myLocationEnabled: true, // Show blue dot
            myLocationButtonEnabled: false, // We build our own button
            buildingsEnabled: true, // 3D Buildings!
          ),

          // Custom Back Button
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // "Recenter" Button
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
              onPressed: _goToCampus,
              backgroundColor: Colors.blueAccent,
              child: const Icon(Icons.school, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _goToCampus() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_citkCampus));
  }
}